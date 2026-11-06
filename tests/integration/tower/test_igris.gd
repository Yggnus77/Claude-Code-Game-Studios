extends TestCase
## Integration: Igris's chamber, the attempt snapshot and the return (Etapa 7).

const FLAGS := ["seen.p00", "seen.p01", "seen.p02", "seen.p03", "seen.p04", "seen.p05", "seen.p07", "seen.p08",
	"seen.t01", "seen.t02", "seen.t03", "seen.t05", "world.guards_clear", "world.weight_locked", "world.bells_solved", "visited.t00_base"]

var main: Node


func _setup(room_id: String, extra: Array = []) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	var effects := []
	for f in FLAGS + extra:
		effects.append({"op": "set_flag", "flag": f, "value": true})
	effects.append({"op": "grant_unique", "item_id": "gancho_retorno", "quantity": 1, "receipt_id": "scene.t03.gancho_retorno"})
	main.state.apply(effects)
	main.load_room(room_id)
	main._on_room_entered()
	var p: Player = main.player
	p.read_input = false
	p.respawn_at(main.room.data.tile_center(Vector2i(5, 14)))
	return p


func teardown() -> void:
	if main:
		main.dialogue_box.runner = null
		main.dialogue._on_box_closed()
		main.queue_free()
		await tree.process_frame
		tree.paused = false


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func _skip_scenes() -> Array:
	var ids := []
	for i in 8:
		await _frames(3)
		if main.dialogue.is_open():
			ids.append(main.dialogue._active_id)
			main.dialogue_box.runner.skip()
			main.dialogue_box._after_step()
	return ids


func _wait_phase(phase: IgrisFight.Phase, seconds := 15.0) -> void:
	var frames := int(seconds * 60)
	while main.igris and main.igris.fight.phase != phase and frames > 0:
		await tree.physics_frame
		frames -= 1


func _bell(id: String) -> Bell:
	for b in main.bells:
		if b.bell_id == id:
			return b
	return null


func _clear_cycle(attack_base: int) -> void:
	await _wait_phase(IgrisFight.Phase.MUFFLER)
	main._on_hook_hit({"type": "enemy", "node": main.igris})
	await _wait_phase(IgrisFight.Phase.BELLS)
	var n := 0
	for id in main.igris.fight.sequence():
		n += 1
		_bell(id).receive_sword_hit(1, attack_base + n, Vector2.ZERO)
	main.igris.receive_sword_hit(1, attack_base + 10, Vector2.ZERO)
	main.igris.receive_sword_hit(1, attack_base + 11, Vector2.ZERO)


func test_free_igris_then_he_chooses_to_leave() -> void:
	var p := _setup("t07_igris")
	assert_eq(await _skip_scenes(), ["t08"], "opening scene")
	assert_true(main.igris.active, "fight starts after t08")
	# Waves land on a standing target; enough life to watch both cycles.
	p.health.maximum = 99
	p.health.current = 99
	assert_true(not main.igris.receive_sword_hit(9, 1, Vector2.ZERO), "ordinary hit only clangs")
	await _clear_cycle(100)
	assert_eq(main.igris.fight.cycle, 1, "first cycle")
	await _clear_cycle(200)
	var ids := await _skip_scenes()
	assert_eq(ids, ["t10", "t11"], "control broken, then Igris chooses to leave")
	assert_true(main.state.has_flag("seen.t11"), "record delivered")
	assert_true(main.state.skins.has("operador_akurame"), "skin unlocked")
	await _frames(2)
	assert_true(main.igris == null, "the fight is over for good")
	for d in main.room.data.doors:
		if str(d["id"]) == "door.t07_igris.t00_base":
			assert_true(main.is_door_open(d), "shortcut down to the base")
	main.load_room("t07_igris")
	assert_true(main.igris == null, "no fight on return")


func test_death_returns_flasks_and_skips_the_opening() -> void:
	var p := _setup("t07_igris")
	await _skip_scenes()
	main.state.apply([{"op": "refill_flask"}])
	main._attempt = {}
	main.igris.active = false
	main._start_igris_attempt()
	main.state.apply([{"op": "drink_flask"}])
	assert_eq(main.state.full_flask_count(), 0, "drank during the attempt")
	p.receive_hit(99, p.global_position + Vector2(10, 0))
	await _frames(int(main.RESPAWN_DELAY * 60) + 10)
	assert_eq(main.state.full_flask_count(), 1, "the flask is back for the new attempt")
	main.load_room("t07_igris")
	main._on_room_entered()
	await _frames(3)
	assert_true(not main.dialogue.is_open(), "t08 does not play again")
	assert_true(main.igris.active, "the fight restarts right away")
	assert_eq(main.igris.fight.cycle, 0, "from the first cycle")


func test_arena_rings_pull_yggnus_out_of_a_wave() -> void:
	# catalogo-atlas: four fixing points in the arena; a ring pulls Yggnus to it.
	var p := _setup("t07_igris")
	await _skip_scenes()
	var anchors := 0
	for e in main.room.data.entities:
		if str(e.get("kind", "")) == "anchor":
			anchors += 1
	assert_eq(anchors, 4, "four rings in the arena")
	var ring: Vector2 = main.room.data.tile_center(Vector2i(4, 12))
	p.respawn_at(ring + Vector2(80, 0))
	p.motor.facing = Vector2.LEFT
	var life := p.health.current
	assert_true(p.fire_hook(), "hook thrown at the ring")
	await _frames(60)
	assert_true(p.global_position.distance_to(ring) < 2.0, "pulled onto the ring")
	assert_true(p.health.current >= life - 1, "at most one wave on the way")


func test_outcome_scenes_offer_no_choice() -> void:
	# Etapa 7: the result never depends on pressing a button during the talk.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/dialogos.pt-BR.json"))
	var checked := 0
	for scene in data["scenes"]:
		if ["t10", "t11"].has(str(scene["id"])):
			checked += 1
			for node in scene["nodes"]:
				assert_true(str(node.get("type", "")) != "choice", "%s has no choice node" % node["id"])
	assert_eq(checked, 2, "both outcome scenes found")


func test_leaving_the_chamber_ends_the_attempt() -> void:
	var p := _setup("t07_igris")
	await _skip_scenes()
	assert_true(not main._attempt.is_empty(), "attempt running")
	main.load_room("t06_marco")
	assert_true(main._attempt.is_empty(), "leaving drops the snapshot")
	main.state.apply([{"op": "refill_flask"}])
	p.receive_hit(99, p.global_position + Vector2(10, 0))
	await _frames(int(main.RESPAWN_DELAY * 60) + 10)
	assert_eq(main.state.full_flask_count(), 1, "a death elsewhere keeps the flask filled later")


func test_death_at_the_regulator_restarts_from_the_first_cycle() -> void:
	var p := _setup("t07_igris")
	await _skip_scenes()
	p.health.maximum = 99
	p.health.current = 99
	await _clear_cycle(100)
	await _wait_phase(IgrisFight.Phase.MUFFLER)
	main._on_hook_hit({"type": "enemy", "node": main.igris})
	await _wait_phase(IgrisFight.Phase.BELLS)
	var n := 0
	for id in main.igris.fight.sequence():
		n += 1
		_bell(id).receive_sword_hit(1, 300 + n, Vector2.ZERO)
	main.igris.receive_sword_hit(1, 310, Vector2.ZERO)
	assert_eq(main.igris.fight.hits, 1, "one hit on the open regulator")
	p.receive_hit(999, p.global_position + Vector2(10, 0))
	await _frames(int(main.RESPAWN_DELAY * 60) + 10)
	main.load_room("t07_igris")
	main._on_room_entered()
	await _frames(3)
	assert_true(not main.dialogue.is_open(), "t08 does not play again")
	assert_eq(main.igris.fight.cycle, 0, "first cycle again")
	assert_eq(main.igris.fight.hits, 0, "no hits carried over")


func test_return_to_the_workshop_upgrades_the_sword() -> void:
	_setup("v00_oficina", ["seen.t10", "seen.t11"])
	assert_eq(await _skip_scenes(), ["t12"], "Exódia's scene")
	assert_eq(main.state.item_count("espada_diapasao"), 1, "tuned sword")
