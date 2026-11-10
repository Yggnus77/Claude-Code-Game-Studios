extends TestCase
## Integration: the road rooms, the optional pump, the merchant, flasks,
## Bronze drops and the locked m01 clues (Etapa 5).

const AFTER_INVASION := ["seen.p00", "seen.p01", "seen.p02", "seen.p03", "seen.p04", "seen.p05", "seen.p07"]

var main: Node


func _setup(room_id: String, flags: Array = AFTER_INVASION) -> Player:
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
		main.shop_panel.close()
		main.queue_free()
		await tree.process_frame
		tree.paused = false


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func _face(p: Player, tile: Vector2i) -> void:
	p.respawn_at(main.room.data.tile_center(tile + Vector2i(0, 1)))
	p.motor.facing = Vector2.UP


func _skip_scene() -> String:
	await _frames(2)
	if not main.dialogue.is_open():
		return ""
	var id: String = main.dialogue._active_id
	main.dialogue_box.runner.skip()
	main.dialogue_box._after_step()
	return id


func _enemy_with_entity(entity_id: String) -> Node:
	for e in main.enemies:
		if str(e.get_meta("entity", {}).get("id", "")) == entity_id:
			return e
	return null


func _defeat(enemy: Node) -> void:
	for i in 20:
		if enemy.is_defeated:
			return
		enemy.health.take_damage(99)
		enemy.receive_sword_hit(99, 9000 + i, enemy.global_position)


func test_pump_side_quest_gives_second_flask_once() -> void:
	var p := _setup("r02_bomba")
	_face(p, Vector2i(16, 10))
	assert_eq(main.interact(), "scene", "the mechanic asks for the parts (r03)")
	assert_eq(await _skip_scene(), "r03", "r03")
	assert_eq(main.interact(), "nothing", "without parts the pump waits")
	main.load_room("r00_estrada")
	_face(p, Vector2i(5, 5))
	assert_eq(main.interact(), "chest", "gear part from the chest by the wall")
	main.load_room("r01_cruzamento")
	var scrap := _enemy_with_entity("r01_cruzamento.pump_b")
	assert_true(scrap != null, "the designated creature is there")
	_defeat(scrap)
	assert_eq(main.state.item_count("peca_bomba_b"), 1, "axle part from the creature")
	main.load_room("r01_cruzamento")
	_defeat(_enemy_with_entity("r01_cruzamento.pump_b"))
	assert_eq(main.state.item_count("peca_bomba_b"), 1, "defeating it again gives nothing more")
	main.load_room("r02_bomba")
	_face(p, Vector2i(16, 10))
	assert_eq(main.interact(), "scene", "both parts: r04")
	assert_eq(await _skip_scene(), "r04", "r04")
	assert_eq(main.state.flasks(), ["frasco_01", "frasco_02"], "the pump gave only the second flask")
	assert_eq(main.state.item_count("peca_bomba_a") + main.state.item_count("peca_bomba_b"), 0, "parts used")
	assert_eq(main.interact(), "nothing", "nothing more from the pump")


func test_travel_reserves_buy_a_refill_and_the_flask_heals() -> void:
	var p := _setup("v01_praca")
	_face(p, Vector2i(7, 17))
	main.interact()
	main.load_room("r00_estrada")
	_face(p, Vector2i(33, 7))
	main.interact()
	assert_eq(main.state.bronze, 20, "two reserves of 10")
	main.load_room("v01_praca")
	_face(p, Vector2i(24, 7))
	assert_eq(main.interact(), "scene", "merchant talk (r05)")
	assert_eq(await _skip_scene(), "r05", "r05")
	await _frames(2)
	assert_true(main.shop_panel.is_open(), "shop opens after the talk")
	main.shop_panel._index = 1
	assert_true(main.shop_panel.buy_selected(), "refill bought")
	assert_eq(main.state.bronze, 0, "20 Bronze spent")
	_face(p, Vector2i(7, 17))
	main.interact()
	assert_eq(main.state.bronze, 0, "reopening the chest changes nothing")
	main.shop_panel.close()
	assert_true(not p.request_heal(), "full life: the flask is not used")
	assert_eq(main.state.full_flask_count(), 1, "still full")
	p.health.take_damage(4)
	p.health.tick(5.0)
	assert_true(p.request_heal(), "drinks")
	await _frames(int(0.65 * 60) + 3)
	assert_eq(p.health.current, 5, "+3 life")
	assert_eq(main.state.full_flask_count(), 0, "flask emptied at the effect frame")


func test_hit_while_drinking_spends_nothing() -> void:
	var p := _setup("v01_praca")
	main.state.apply([{"op": "refill_flask"}])
	p.health.take_damage(2)
	p.health.tick(5.0)
	assert_true(p.request_heal(), "drinks")
	await _frames(10)
	p.receive_hit(1, p.global_position + Vector2(20, 0))
	await _frames(60)
	assert_eq(main.state.full_flask_count(), 1, "interrupted: the flask is still full")


func test_merchant_goes_straight_to_goods_after_first_talk() -> void:
	var p := _setup("v01_praca", AFTER_INVASION + ["seen.r05"])
	_face(p, Vector2i(24, 7))
	assert_eq(main.interact(), "shop", "no repeated talk")
	await tree.process_frame
	assert_true(main.shop_panel.is_open(), "the goods are shown")


func test_common_enemy_drops_bronze() -> void:
	var p := _setup("r00_estrada")
	var crawler := _enemy_with_entity("r00_estrada.rastejo_1")
	_defeat(crawler)
	await _frames(2)
	var coins := tree.get_nodes_in_group("pickups")
	assert_eq(coins.size(), 1, "one coin")
	p.respawn_at(coins[0].global_position)
	await _frames(3)
	assert_eq(main.state.bronze, 1, "rastejo drops 1 Bronze")


func test_m01_clues_wait_for_igris_record() -> void:
	var p := _setup("r01_cruzamento")
	_face(p, Vector2i(7, 17))
	assert_eq(main.interact(), "clue_locked", "too early")
	assert_true(not main.state.has_flag("clue.m01.via_cais"), "nothing recorded")
	main.state.apply([{"op": "set_flag", "flag": "seen.t11", "value": true}])
	assert_eq(main.interact(), "clue", "after Igris's record it is noted")


func test_road_needs_no_enemy_defeated() -> void:
	_setup("r00_estrada")
	for door in main.room.data.doors:
		assert_true(main.is_door_open(door), "%s open" % door["id"])
	main.load_room("r01_cruzamento")
	for door in main.room.data.doors:
		if Room.is_cracked(door):
			continue  # the optional cellar behind the cracked wall needs a charge
		assert_true(main.is_door_open(door), "%s open" % door["id"])
