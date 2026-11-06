extends TestCase
## Integration: fixes from the full review of stages 1–7 (doors, pause
## ownership, inventory, barks, dialogue box layout).

const FLAGS := ["seen.p00", "seen.p01", "seen.p02", "seen.p03", "seen.p04", "seen.p05", "seen.p07", "seen.p08",
	"seen.t01", "seen.t02", "seen.t03", "seen.t05", "world.guards_clear", "world.weight_locked", "world.bells_solved", "visited.t00_base"]

var main: Node


func _setup(room_id: String) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	var effects := []
	for f in FLAGS:
		effects.append({"op": "set_flag", "flag": f, "value": true})
	main.state.apply(effects)
	main.load_room(room_id)
	var p: Player = main.player
	p.read_input = false
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


func _key(action: String) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	return ev


func test_a_door_does_not_heal() -> void:
	# mecanicas: only marcos restore life; stepping out and back is no cure.
	var p := _setup("t06_marco")
	p.health.take_damage(3)
	var left := p.health.current
	var door: Dictionary = {}
	for d in main.room.data.doors:
		if str(d["id"]) == "door.t06_marco.t07_igris":
			door = d
	await main._go_through(door)
	assert_eq(main.room_id, "t07_igris", "crossed")
	assert_eq(p.health.current, left, "life kept through the door")


func test_death_still_restores_life() -> void:
	var p := _setup("t06_marco")
	p.receive_hit(99, p.global_position + Vector2(10, 0))
	await _frames(int(main.RESPAWN_DELAY * 60) + 10)
	assert_eq(p.health.current, p.health.maximum, "full life after a death")


func test_inventory_closes_while_paused() -> void:
	_setup("t06_marco")
	main._unhandled_input(_key("map"))
	assert_true(main.hud.is_inventory_open(), "Tab opens")
	assert_true(tree.paused, "and pauses")
	main.hud._unhandled_input(_key("map"))
	assert_true(not main.hud.is_inventory_open(), "Tab closes")
	assert_true(not tree.paused, "and resumes")
	main._unhandled_input(_key("map"))
	main.hud._unhandled_input(_key("pause"))
	assert_true(not main.hud.is_inventory_open() and not tree.paused, "Esc closes it too")


func test_scene_restores_an_existing_pause() -> void:
	_setup("t06_marco")
	tree.paused = true
	main.dialogue._paused_before = false
	main.dialogue._start({"id": "probe", "entry_node": "n0", "nodes": [{"id": "n0", "type": "end"}]})
	assert_true(main.dialogue._paused_before, "remembers the pause it found")
	main.dialogue_box.runner = null
	main.dialogue._on_box_closed()
	assert_true(tree.paused, "closing the scene keeps the other pause")


func test_bark_shows_every_line_with_speaker() -> void:
	_setup("t07_igris")
	var got := [""]
	main.dialogue.bark.connect(func(text: String) -> void: got[0] = text)
	main.dialogue.request("igris_primeiro_abafador")
	var lines: PackedStringArray = got[0].split("\n")
	assert_eq(lines.size(), 2, "both lines of t09")
	assert_true(lines[1].contains("Falta o outro vínculo"), "the hint line is shown")
	assert_true(lines[0].contains(":"), "with the speaker's name")


func test_dialogue_box_grows_upward_with_choices() -> void:
	_setup("v01_praca")
	var scene := {"id": "probe", "entry_node": "c", "nodes": [
		{"id": "c", "type": "choice", "text": "Escolha uma opção para seguir com a conversa.", "options": [
			{"text": "Primeira opção", "next": "e"}, {"text": "Segunda opção", "next": "e"}, {"text": "Terceira opção", "next": "e"}]},
		{"id": "e", "type": "end"}]}
	main.dialogue_box.open(DialogueRunner.new(scene, main.state))
	await tree.process_frame
	await tree.process_frame
	var rect: Rect2 = main.dialogue_box._panel.get_global_rect()
	assert_true(rect.end.y <= 360.0, "the box ends on screen (bottom at %.0f)" % rect.end.y)
	assert_true(rect.position.y >= 0.0, "and starts on screen")
