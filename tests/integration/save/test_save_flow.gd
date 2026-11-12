extends TestCase
## Integration: saving, closing and loading in the game (Etapa 9,
## integracao-e-salvamento.md §7, mecanicas-e-dificuldade.md §9).

const TOWER := ["seen.p00", "seen.p01", "seen.p02", "seen.p03", "seen.p04", "seen.p05", "seen.p07", "seen.p08",
	"seen.t01", "seen.t02", "seen.t03", "seen.t05", "world.guards_clear", "world.weight_locked", "world.bells_solved", "visited.t00_base"]

var main: Node
var _dir := ""


func _new_main(slot := 1) -> Node:
	if _dir.is_empty():
		_dir = "user://test_saves/flow%d" % Time.get_ticks_usec()
	var m: Node = load("res://src/scenes/main.tscn").instantiate()
	m.play_intro = false
	m.save_dir = _dir
	m.settings_path = _dir.path_join("settings.cfg")
	tree.root.add_child(m)
	m.save_slot = slot
	m.player.read_input = false
	return m


func _flags(m: Node, flags: Array) -> void:
	var fx := []
	for f in flags:
		fx.append({"op": "set_flag", "flag": f, "value": true})
	m.state.apply(fx)


## Closes [param m] like quitting the game, then opens a new one on the save.
func _reopen(m: Node) -> Node:
	m.save_now()
	await _close(m)
	main = _new_main()
	var r: Dictionary = main.saves.read(1)
	assert_eq(r["status"], SaveStore.Status.OK, "the save reads back")
	main.continue_from(r["data"])
	main.player.read_input = false
	return main


func _close(m: Node) -> void:
	m.dialogue_box.runner = null
	m.dialogue._on_box_closed()
	m.queue_free()
	await tree.process_frame
	tree.paused = false


func teardown() -> void:
	if main and is_instance_valid(main):
		await _close(main)
	if not _dir.is_empty() and DirAccess.dir_exists_absolute(_dir):
		for f in DirAccess.get_files_at(_dir):
			DirAccess.remove_absolute(_dir.path_join(f))
		DirAccess.remove_absolute(_dir)


func _door(m: Node, door_id: String) -> Dictionary:
	for d in m.room.data.doors:
		if str(d["id"]) == door_id:
			return d
	return {}


func test_close_and_load_after_a_door_returns_to_its_entry() -> void:
	main = _new_main()
	_flags(main, TOWER)
	main.load_room("t06_marco")
	main.player.health.take_damage(2)
	await main._go_through(_door(main, "door.t06_marco.t07_igris"))
	assert_eq(main.room_id, "t07_igris", "crossed")
	main.player.global_position += Vector2(48, 0)  # walked on, then quit
	main = await _reopen(main)
	assert_eq(main.room_id, "t07_igris", "same room")
	assert_eq(main.player.global_position, main.room.data.tile_center(Vector2i(2, 14)), "on the door's entry tile")
	assert_eq(main.player.health.current, main.player.health.maximum - 2, "life as saved, not healed")


func test_a_save_standing_where_the_room_now_has_a_wall_still_loads() -> void:
	# The square was redrawn (salas-pintadas.md): a save made before that may
	# stand on a tile that is now wall. It loads, at the room's default entry.
	main = _new_main()
	main.load_room("v01_praca")
	main.save_now()
	var doc: Dictionary = main.saves.read(1)["data"]
	doc["safe_entry"] = [2, 12]  # floor in the old square, wall in the new one
	assert_true(not main.room.data.is_walkable(Vector2i(2, 12)), "fixture: a wall now")
	assert_eq(main.saves.write(1, doc), OK, "the old save is accepted")
	var r: Dictionary = main.saves.read(1)
	assert_eq(r["status"], SaveStore.Status.OK, "and reads back as valid")
	main.continue_from(r["data"])
	assert_eq(main.player.global_position, main.room.data.tile_center(main.room.data.entry_default), "on the default entry")


func test_quitting_during_igris_returns_to_the_attempt_start() -> void:
	main = _new_main()
	_flags(main, TOWER + ["seen.t08"])
	main.state.apply([{"op": "refill_flask"}, {"op": "grant_unique", "item_id": "pao_porto", "quantity": 2, "receipt_id": "test.pao"}])
	main.player.health.take_damage(1)
	main.load_room("t07_igris", Vector2i(2, 14), false)
	assert_true(not main._attempt.is_empty(), "the attempt started")
	var life_at_start: int = main.player.health.current
	# Mid-fight: drink the flask, eat bread, get hit, then the game closes.
	main.state.apply([{"op": "drink_flask"}, {"op": "use_item", "item_id": "pao_porto"}])
	main.player.global_position = main.room.data.tile_center(Vector2i(20, 14))
	main.player.health.take_damage(2)
	main = await _reopen(main)
	assert_eq(main.room_id, "t07_igris", "back in the chamber")
	assert_eq(main.player.global_position, main.room.data.tile_center(Vector2i(2, 14)), "at the attempt's entry")
	assert_eq(main.state.full_flask_count(), 1, "flask full again")
	assert_eq(main.state.item_count("pao_porto"), 2, "bread back")
	assert_eq(main.player.health.current, life_at_start, "life as the attempt began")
	assert_true(main.igris != null and main.igris.active, "a fresh attempt")


func test_closing_during_the_victory_scene_keeps_win_and_supplies_together() -> void:
	main = _new_main()
	_flags(main, TOWER + ["seen.t08"])
	main.state.apply([{"op": "refill_flask"}])
	main.load_room("t07_igris", Vector2i(2, 14), false)
	main.state.apply([{"op": "drink_flask"}])
	main.igris.control_broken.emit()
	await tree.process_frame
	assert_true(main.dialogue.is_open(), "the victory scene plays")
	# Closed during the scene: nothing of the victory is saved yet.
	var during: GameState = SaveGame.restore((await _reopen(main)).saves.read(1)["data"])["state"]
	assert_eq(during.full_flask_count(), 1, "the fight's start: flask full")
	assert_true(main.igris != null and main.igris.active, "the fight is there to win again")
	# Win again and finish the scene: victory and the spent flask together.
	main.state.apply([{"op": "drink_flask"}])
	main.igris.control_broken.emit()
	await tree.process_frame
	main.dialogue_box.runner.skip()
	main.dialogue_box._after_step()
	await tree.process_frame
	main.dialogue_box.runner = null
	main.dialogue._on_box_closed()
	main = await _reopen(main)
	assert_true(main.state.has_flag("seen.%s" % main._igris_end_scene()), "victory saved")
	assert_eq(main.state.full_flask_count(), 0, "with the flask it cost")
	assert_true(main.igris == null, "Igris is free for good")


func test_a_scene_with_rewards_is_saved_once_and_not_replayed() -> void:
	main = _new_main()
	main.state.replace_with(GameState.new())
	_flags(main, ["seen.p00", "seen.p01", "seen.p02", "seen.p03", "seen.p04"])
	main.load_room("v00_oficina")
	main.dialogue.request("yame_entra")
	main.dialogue_box.runner.skip()
	main.dialogue_box._after_step()
	await tree.process_frame
	assert_true(main.state.has_flag("seen.p05"), "p05 finished")
	assert_eq(main.state.item_count("espada_oficina"), 1, "sword received")
	main = await _reopen(main)
	assert_eq(main.state.item_count("espada_oficina"), 1, "the sword is still there, once")
	assert_true(main.player.has_sword, "and in hand")
	assert_true(not main.dialogue.request("yame_entra"), "the scene does not hand it out again")


func test_a_marco_becomes_the_place_to_load() -> void:
	main = _new_main()
	_flags(main, TOWER)
	main.load_room("v01_praca")
	var marco: Dictionary = {}
	for e in main.room.data.entities:
		if str(e.get("kind", "")) == "checkpoint":
			marco = e
	var below := Vector2i(int(marco["tile"][0]), int(marco["tile"][1]) + 1)
	main.player.global_position = main.room.data.tile_center(below)
	main.player.motor.facing = Vector2.UP
	assert_eq(main.interact(), "checkpoint", "marco used")
	main.dialogue_box.runner = null
	main.dialogue._on_box_closed()
	main = await _reopen(main)
	assert_eq(main.player.global_position, main.room.data.tile_center(below), "loads beside the marco")
	assert_eq(str(main.state.checkpoint.get("room", "")), "v01_praca", "marco kept")


func test_title_screen_starts_and_continues_slots() -> void:
	main = _new_main(0)
	var title := TitleScreen.new(main.saves)
	title.describe = main.describe_save
	var got := []
	title.start.connect(func(slot: int, doc: Dictionary) -> void: got.append([slot, doc]))
	main.add_child(title)
	title.show_slots(1)
	title.menu.confirm()  # slot 1, empty
	assert_eq(got.size(), 1, "an empty slot starts at once")
	assert_eq(got[0][0], 1, "slot 1")
	assert_true(got[0][1].is_empty(), "as a new game")
	main.save_slot = 2
	assert_eq(main.save_now(), OK, "slot 2 saved")
	title.show_slots(2)
	title.menu.confirm()  # open slot 2
	title.menu.confirm()  # Continuar
	assert_eq(got.size(), 2, "a saved slot continues")
	assert_eq(got[1][0], 2, "slot 2")
	assert_eq(str(got[1][1]["current_room"]), main.room_id, "with its save")
	title.queue_free()


func test_title_offers_the_backup_when_the_save_is_damaged() -> void:
	main = _new_main()
	main.save_now()
	main.save_now()
	var f := FileAccess.open(main.saves.main_path(1), FileAccess.WRITE)
	f.store_string("{\"schema_version\": 1, \"cut")
	f.close()
	var title := TitleScreen.new(main.saves)
	title.describe = main.describe_save
	main.add_child(title)
	title.show_slots(1)
	assert_true(title.menu.options[0].contains("cópia recuperada"), "the row says a copy is used: %s" % title.menu.options[0])
	title.menu.confirm()
	assert_true(title.menu.options[0].contains("cópia"), "continue from the copy")
	title.queue_free()


func test_pause_menu_continues_and_offers_leaving() -> void:
	main = _new_main()
	main.pause_overlay.on_title = main.quit_to_title
	main.pause_overlay.set_paused(true)
	assert_true(tree.paused, "paused")
	assert_eq(main.pause_overlay.menu.options.size(), 5, "continue, settings, title, quit, playtest folder")
	main.pause_overlay.menu.confirm()
	assert_true(not tree.paused, "Continuar resumes")


func test_the_playtest_record_follows_the_session() -> void:
	main = _new_main()
	main.playtest_dir = _dir.path_join("playtest")
	_flags(main, TOWER + ["seen.t08"])
	main.load_room("t07_igris", Vector2i(2, 14), false)
	main._on_room_entered()
	assert_eq(main.playtest.igris_attempts.size(), 0, "attempt running, not ended")
	main.load_room("t07_igris", Vector2i(2, 14), false)  # R mid-fight
	assert_eq(main.playtest.igris_attempts.size(), 1, "the reset ends the first attempt")
	assert_eq(main.playtest.igris_attempts[0]["result"], "reiniciou", "as a reset")
	main.player.receive_hit(99, main.igris.global_position, false, true, "onda de Igris")
	await tree.process_frame
	assert_eq(main.playtest.igris_attempts.size(), 2, "the death ends the second")
	assert_eq(main.playtest.igris_attempts[1]["result"], "morte", "as a death")
	assert_eq(main.playtest.deaths.get("Câmara de Igris", {}).get("onda de Igris", 0), 1, "named by what hit")
	main.write_playtest()
	var files := DirAccess.get_files_at(main.playtest_dir)
	assert_eq(files.size(), 2, "summary and data written: %s" % [files])
	for f in files:
		DirAccess.remove_absolute(main.playtest_dir.path_join(f))
	DirAccess.remove_absolute(main.playtest_dir)


func test_continuing_a_finished_save_is_not_a_new_finish() -> void:
	main = _new_main()
	_flags(main, TOWER + ["seen.t08", "seen.t10", "seen.t11", "seen.t12"])
	main.load_room("v00_oficina")
	main.save_now()
	await _close(main)
	main = _new_main()
	main.continue_from(main.saves.read(1)["data"])
	assert_eq(main.playtest.finished_at, -1.0, "no finish recorded on load")
