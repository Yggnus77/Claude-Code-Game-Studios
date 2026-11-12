extends TestCase
## Integration: chests, clues, story scenes and doors in real rooms.

var main: Node


func _setup(room_id: String, flags: Array = []) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	var effects := []
	for f in flags:
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


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


## Stands the player just below [param tile], facing up at it.
func _face(p: Player, tile: Vector2i) -> void:
	p.respawn_at(main.room.data.tile_center(tile + Vector2i(0, 1)))
	p.motor.facing = Vector2.UP


func test_chest_gives_bronze_once() -> void:
	var p := _setup("v01_praca")
	_face(p, Vector2i(5, 14))
	assert_eq(main.interact(), "chest", "opens the travel reserve")
	assert_eq(main.state.bronze, 10, "10 Bronze")
	assert_eq(main.interact(), "chest_empty", "second press finds it empty")
	main.load_room("v01_praca")
	_face(p, Vector2i(5, 14))
	assert_eq(main.interact(), "chest_empty", "still empty after re-entering the room")
	assert_eq(main.state.bronze, 10, "no duplicate Bronze")


func test_key_chest_gives_key_once() -> void:
	var p := _setup("t00_base")
	_face(p, Vector2i(5, 4))
	main.interact()
	main.interact()
	assert_eq(main.state.item_count("key_ak_base"), 1, "one key")


func test_clue_sets_flag_once() -> void:
	var p := _setup("v01_praca", ["seen.t11"])
	_face(p, Vector2i(33, 10))
	assert_eq(main.interact(), "clue", "clue recorded")
	assert_true(main.state.has_flag("clue.m01.recibo_mercado"), "flag set")
	assert_eq(main.interact(), "nothing", "second read does nothing new")


func test_scene_pauses_world_and_one_box_only() -> void:
	var p := _setup("v00_oficina", ["seen.p00"])
	_face(p, Vector2i(22, 14))
	assert_eq(main.interact(), "scene", "examining the clock plays p01")
	assert_true(main.dialogue.is_open(), "box open")
	assert_true(tree.paused, "world paused during the scene")
	assert_eq(main.interact(), "nothing", "a second quick press does not open another box")
	main.dialogue_box.runner.skip()
	main.dialogue_box._after_step()
	assert_true(not tree.paused, "world resumes")
	assert_true(main.state.has_flag("seen.p01"), "skip applied the scene's effects")


func test_scene_waits_for_dodge_to_end() -> void:
	var p := _setup("v00_oficina", ["seen.p00"])
	p.input_override = Vector2.RIGHT
	p.has_dodge = true  # the dash of a later item
	p.request_dodge()
	await _frames(3)
	assert_true(p.dodge.is_dodging(), "dodging")
	main.dialogue.request("examinar_relogio")
	assert_true(not main.dialogue.is_open(), "the scene does not cut the dodge")
	p.input_override = Vector2.ZERO
	await _frames(20)
	assert_true(main.dialogue.is_open(), "it opens once the dodge ends")


func test_door_needs_its_gate() -> void:
	var p := _setup("v01_praca")
	var door: Dictionary = {}
	for d in main.room.data.doors:
		if d["target_room"] == "r00_estrada":
			door = d
	assert_true(not door.is_empty(), "praça has a door to the road")
	assert_true(not main.is_door_open(door), "closed before seen.p07")
	main.state.apply([{"op": "set_flag", "flag": "seen.p07", "value": true}])
	assert_true(main.is_door_open(door), "open after seen.p07")
	var t: Array = door["tile"]
	p.respawn_at(main.room.data.tile_center(Vector2i(int(t[0]), int(t[1]))) + Vector2(-12, 0))
	main._arrival_door = ""
	p.global_position = main.room.data.tile_center(Vector2i(int(t[0]), int(t[1])))
	await _frames(40)
	assert_eq(main.room_id, "r00_estrada", "walking onto the open door changes room")
