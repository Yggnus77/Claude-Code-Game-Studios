extends TestCase
## Integration: Torre Akurame (Etapa 6): the way to the hook without it,
## the hook itself, the gap, the counterweight and the bells.

const AFTER_INVASION := ["seen.p00", "seen.p01", "seen.p02", "seen.p03", "seen.p04", "seen.p05", "seen.p07", "seen.p08"]

var main: Node


func _setup(room_id: String, flags: Array = [], hook := false) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	var effects := []
	for f in AFTER_INVASION + flags:
		effects.append({"op": "set_flag", "flag": f, "value": true})
	if hook:
		effects.append({"op": "grant_unique", "item_id": "gancho_retorno", "quantity": 1, "receipt_id": "scene.t03.gancho_retorno"})
	main.state.apply(effects)
	main.load_room(room_id)
	var p: Player = main.player
	p.read_input = false
	return p


func teardown() -> void:
	if main:
		main.dialogue_box.runner = null
		main.dialogue._on_box_closed()
		main.shop_panel.close()
		main.queue_free()
		await tree.process_frame
		tree.paused = false


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func _stand(p: Player, tile: Vector2i, facing: Vector2) -> void:
	p.respawn_at(main.room.data.tile_center(tile))
	p.motor.facing = facing


func _skip_scene() -> String:
	await _frames(2)
	if not main.dialogue.is_open():
		return ""
	var id: String = main.dialogue._active_id
	main.dialogue_box.runner.skip()
	main.dialogue_box._after_step()
	return id


func _door(id: String) -> Dictionary:
	for d in main.room.data.doors:
		if str(d["id"]) == id:
			return d
	return {}


func test_way_to_the_hook_without_owning_it() -> void:
	var p := _setup("t00_base")
	_stand(p, Vector2i(6, 14), Vector2.UP)
	main.interact()
	assert_eq(await _skip_scene(), "t01", "arriving at the base plays t01")
	assert_eq(main.state.item_count("key_ak_base"), 1, "key from the base chest")
	assert_true(main.is_door_open(_door("door.t00_base.t01_guardas")), "key opens the guards' hall")
	main.load_room("t01_guardas")
	main._on_room_entered()
	assert_eq(await _skip_scene(), "t02", "t02: the guards' opening is explained before the fight")
	assert_true(not main.is_door_open(_door("door.t01_guardas.t02_oficina")), "workshop locked while guards stand")
	assert_true(not main.is_door_open(_door("door.t01_guardas.t03_treino")), "training needs the hook")
	assert_eq(main.enemies.size(), 2, "two guards")
	for g in main.enemies.duplicate():
		g.health.take_damage(99)
		g._defeat()
	assert_true(main.state.has_flag("world.guards_clear"), "guards clear")
	assert_true(main.is_door_open(_door("door.t01_guardas.t02_oficina")), "workshop open")
	main.load_room("t01_guardas")
	assert_eq(main.enemies.size(), 0, "the guards do not come back")
	main.load_room("t02_oficina")
	_stand(p, Vector2i(19, 10), Vector2.UP)
	assert_eq(main.interact(), "scene", "the hook chest plays t03")
	assert_eq(await _skip_scene(), "t03", "t03")
	assert_eq(main.state.item_count("gancho_retorno"), 1, "hook obtained")
	assert_eq(main.equipped, "gancho", "hook equipped on the item button")
	_stand(p, Vector2i(19, 10), Vector2.UP)
	assert_eq(main.interact(), "chest_empty", "the chest stays open")


func test_hook_never_passes_a_wall() -> void:
	var p := _setup("t00_base", [], true)
	_stand(p, Vector2i(12, 12), Vector2.LEFT)  # the chest's plinth fills columns 2–9
	main.equipped = "gancho"
	main.use_item()
	var leftmost := p.global_position.x
	for i in 40:
		await tree.physics_frame
		leftmost = minf(leftmost, p.hook.tip(p.global_position).x)
	# The tip checks every Hook.STEP px, so it stops at most one step inside.
	assert_true(leftmost >= 160.0 - Hook.STEP, "tip stops at the first wall (x %.1f)" % leftmost)


func test_gap_is_not_floor_and_hook_crosses_it() -> void:
	var p := _setup("t03_treino", [], true)
	_stand(p, Vector2i(20, 15), Vector2.UP)
	p.input_override = Vector2.UP
	await _frames(40)
	p.input_override = Vector2.ZERO
	assert_true(p.global_position.y > 14 * 16, "walking stops at the gap's edge")
	_stand(p, Vector2i(20, 15), Vector2.UP)
	main.equipped = "gancho"
	main.use_item()
	await _frames(60)  # eight tiles out and eight back
	assert_eq(Vector2i(p.global_position / 16.0), Vector2i(20, 7), "pulled across to the upper ring")
	p.motor.facing = Vector2.DOWN
	await _frames(25)
	main.use_item()
	await _frames(60)
	assert_eq(Vector2i(p.global_position / 16.0), Vector2i(20, 15), "and back")


func test_hook_from_elsewhere_does_not_pull() -> void:
	var p := _setup("t03_treino", [], true)
	_stand(p, Vector2i(12, 20), Vector2.UP)
	main.equipped = "gancho"
	main.use_item()
	await _frames(45)
	assert_true(p.global_position.y > 19 * 16, "no ring in line: Yggnus stays on the walkway")


func test_counterweight_then_lock_opens_bells_for_good() -> void:
	var p := _setup("t04_pesos", ["seen.t03"], true)
	assert_true(not main.is_door_open(_door("door.t04_pesos.t05_sinos")), "bridge up")
	_stand(p, Vector2i(31, 17), Vector2.UP)
	assert_eq(main.interact(), "nothing", "lock does nothing while the weight is down")
	_stand(p, Vector2i(6, 14), Vector2.UP)
	main.equipped = "gancho"
	main.use_item()
	await _frames(30)
	assert_true(main.room.raised.get("t04_pesos.weight", false), "the hook raised the weight")
	_stand(p, Vector2i(31, 17), Vector2.UP)
	assert_eq(main.interact(), "scene", "Ádally fixes the lock (t05)")
	assert_eq(await _skip_scene(), "t05", "t05")
	assert_true(main.state.has_flag("world.weight_locked"), "locked")
	main.load_room("t04_pesos")
	assert_true(main.is_door_open(_door("door.t04_pesos.t05_sinos")), "still open after restarting the room")
	main.load_room("t05_sinos")
	assert_true(main.is_door_open(_door("door.t04_pesos.t05_sinos")), "same door state seen from the other side")


func test_bells_in_drawn_order() -> void:
	var p := _setup("t05_sinos")
	assert_eq(main.bells.size(), 3, "three bells")
	_stand(p, Vector2i(14, 7), Vector2.UP)
	assert_eq(main.interact(), "scene", "inscription (t06)")
	assert_eq(await _skip_scene(), "t06", "t06")
	assert_eq(main.interact(), "scene", "asking again gives the hint (t07)")
	assert_eq(await _skip_scene(), "t07", "t07")
	assert_eq(main.interact(), "nothing", "then the inscription is just read")
	var by_id := {}
	for b in main.bells:
		by_id[b.bell_id] = b
	by_id["t05_sinos.bell_waves"].receive_sword_hit(1, 1, Vector2.ZERO)
	by_id["t05_sinos.bell_circle"].receive_sword_hit(1, 2, Vector2.ZERO)
	by_id["t05_sinos.bell_waves"].receive_sword_hit(1, 3, Vector2.ZERO)
	assert_true(not main.state.has_flag("world.bells_solved"), "wrong order")
	by_id["t05_sinos.bell_circle"].receive_sword_hit(1, 4, Vector2.ZERO)
	by_id["t05_sinos.bell_gap"].receive_sword_hit(1, 5, Vector2.ZERO)
	by_id["t05_sinos.bell_waves"].receive_sword_hit(1, 6, Vector2.ZERO)
	assert_true(main.state.has_flag("world.bells_solved"), "circle, gap, waves")
	assert_true(main.is_door_open(_door("door.t05_sinos.t06_marco")), "antechamber open")


func test_restarting_a_room_keeps_its_chest_open() -> void:
	var p := _setup("t00_base")
	_stand(p, Vector2i(6, 14), Vector2.UP)
	main.interact()
	main.load_room("t00_base")
	_stand(p, Vector2i(6, 14), Vector2.UP)
	assert_eq(main.interact(), "chest_empty", "still open")
	assert_eq(main.state.item_count("key_ak_base"), 1, "one key")


func test_hook_opens_a_guard_shield() -> void:
	var p := _setup("t01_guardas", [], true)
	var guard: Node = main.enemies[0]
	_stand(p, Vector2i(int(guard.global_position.x / 16) - 4, int(guard.global_position.y / 16)), Vector2.RIGHT)
	main.equipped = "gancho"
	main.use_item()
	var opened := false
	for i in 30:
		await tree.physics_frame
		opened = opened or guard.is_open()
	assert_true(opened, "hooked guard drops its guard")


func test_entering_the_tower_plays_t01() -> void:
	_setup("t00_base")
	main._on_room_entered()
	assert_eq(await _skip_scene(), "t01", "t01 on arrival")
