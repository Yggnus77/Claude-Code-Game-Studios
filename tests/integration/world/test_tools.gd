extends TestCase
## Integration: the bow, the charges and the lamp in real rooms
## (design/gdd/ferramentas.md §8, acceptance criteria 1–8).

var main: Node


func _setup(room_id: String, tile: Vector2i, items: Dictionary = {}) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
	var fx: Array = []
	for id: String in items:
		fx.append({"op": "grant_unique", "item_id": id, "quantity": int(items[id]), "receipt_id": "test.%s" % id})
	if not fx.is_empty():
		main.state.apply(fx)
	main.load_room(room_id, tile)
	main.clear_enemies()
	var p: Player = main.player
	p.read_input = false
	return p


func teardown() -> void:
	if main:
		main.queue_free()
		await tree.process_frame
	tree.paused = false


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func _door(id: String) -> Dictionary:
	for d: Dictionary in main.room.data.doors:
		if str(d["id"]) == id:
			return d
	return {}


func test_a_new_tool_is_equipped_and_the_swap_visits_owned_tools() -> void:
	_setup("r01_cruzamento", Vector2i(20, 12))
	assert_eq(main.equipped, "frasco", "flask at first")
	main.state.apply([{"op": "grant_unique", "item_id": "arco_fio", "quantity": 1, "receipt_id": "t.arco"}])
	assert_eq(main.equipped, "arco", "the bow goes on the button")
	main.state.apply([{"op": "add_item", "item_id": "agulha_fio", "quantity": 7}])
	assert_true(main.hud._item.text.contains("Arco 7"), "HUD shows the needles: %s" % main.hud._item.text)
	main.quick_swap()
	assert_eq(main.equipped, "frasco", "bow -> flask (no hook, no charges, no lamp)")
	main.quick_swap()
	assert_eq(main.equipped, "arco", "flask -> bow")


func test_a_needle_hurts_an_enemy_for_two() -> void:
	var p := _setup("r01_cruzamento", Vector2i(10, 12), {"arco_fio": 1, "agulha_fio": 5})
	var enemy: EnemyBase = main.spawn_enemy("soldado_corda", Vector2i(16, 12))
	enemy.set_physics_process(false)
	var life := enemy.health.current
	var a: Arrow = main.spawn_arrow(p.global_position, Vector2.RIGHT)
	for i in 60:
		if a.advance(1.0 / 60.0):
			break
	assert_eq(enemy.health.current, life - 2, "2 damage")


func test_shooting_spends_a_needle_and_a_miss_can_be_picked_up() -> void:
	var p := _setup("r01_cruzamento", Vector2i(20, 12), {"arco_fio": 1, "agulha_fio": 3})
	p.motor.facing = Vector2.UP
	assert_eq(main.shoot_arrow(), "shot", "shot")
	assert_eq(main.state.item_count("agulha_fio"), 2, "one needle spent")
	await _frames(70)
	var needles := tree.get_nodes_in_group("pickups").filter(func(n: Node) -> bool: return n is Pickup and (n as Pickup).kind == Pickup.KIND_NEEDLE)
	assert_eq(needles.size(), 1, "the miss lies under the wall")
	var at: Vector2 = (needles[0] as Pickup).global_position
	assert_true(at.y < main.room.data.tile_center(Vector2i(20, 2)).y + 8.0, "stopped at the top wall, not through it")
	p.respawn_at(at, false)
	await _frames(3)
	assert_eq(main.state.item_count("agulha_fio"), 3, "picked up again")


func test_no_needles_says_so_and_spends_nothing() -> void:
	_setup("r01_cruzamento", Vector2i(20, 12), {"arco_fio": 1})
	assert_eq(main.shoot_arrow(), "empty", "nothing to shoot")
	assert_true(main.hud._toast.text.contains("Sem agulhas"), "tells why")


func test_a_needle_on_the_plate_opens_the_lookout_and_the_sword_does_not() -> void:
	var p := _setup("t06_marco", Vector2i(16, 8), {"arco_fio": 1, "agulha_fio": 5})
	var door := _door("door.t06_marco.t08_mirante")
	assert_true(not main.is_door_open(door), "closed at first")
	p.motor.facing = Vector2.UP
	p.respawn_at(main.room.data.tile_center(Vector2i(16, 6)), false)
	p.request_attack()
	await _frames(20)
	assert_true(not main.is_door_open(door), "the sword does not reach the plate")
	p.respawn_at(main.room.data.tile_center(Vector2i(16, 8)), false)
	var a: Arrow = main.spawn_arrow(p.global_position, Vector2.UP)
	for i in 60:
		if a.advance(1.0 / 60.0):
			break
	assert_true(main.is_door_open(door), "the needle on the plate opens it")
	assert_true(main.state.has_flag("world.plate.t06_marco"), "for good")


func test_the_refill_tops_needles_up_to_ten() -> void:
	var p := _setup("t06_marco", Vector2i(6, 16), {"arco_fio": 1, "agulha_fio": 2})
	p.motor.facing = Vector2.UP
	assert_eq(main.interact(), "refill", "used the container")
	assert_eq(main.state.item_count("agulha_fio"), 10, "2 -> 10")
	assert_eq(main.interact(), "nothing", "already full")


func test_a_charge_opens_the_cracked_wall_only_when_close() -> void:
	var p := _setup("r01_cruzamento", Vector2i(30, 8), {"carga_bronze": 3})
	var door := _door("door.r01_cruzamento.r04_adega")
	assert_true(not door.is_empty() and Room.is_cracked(door), "a cracked wall")
	assert_true(not main.is_door_open(door), "closed")
	var far: Bomb = main.spawn_bomb(main.room.data.tile_center(Vector2i(30, 6)))
	far.detonate()
	assert_true(not main.is_door_open(door), "too far: still closed")
	p.respawn_at(main.room.data.tile_center(Vector2i(30, 10)), false)
	var near: Bomb = main.spawn_bomb(main.room.data.tile_center(Vector2i(30, 2)))
	near.detonate()
	assert_true(main.is_door_open(door), "the wall fell")
	main.load_room("r04_adega")
	assert_true(main.is_door_open(_door("door.r01_cruzamento.r04_adega")), "open from the other side too")


func test_a_blast_hurts_enemies_breaks_pots_and_hurts_yggnus_nearby() -> void:
	var p := _setup("t02_oficina", Vector2i(8, 8), {"carga_bronze": 2})
	var enemy: EnemyBase = main.spawn_enemy("guarda_contrapeso", Vector2i(9, 9))
	enemy.set_physics_process(false)
	var pot: Breakable = null
	for b in tree.get_nodes_in_group("breakables"):
		if b is Breakable and (b as Breakable).tile == Vector2i(10, 8):
			pot = b
	assert_true(pot != null, "a pot by the wall")
	main.drop_roll = func() -> float: return 0.0  # nothing drops
	var life := enemy.health.current
	var mine := p.health.current
	var bomb: Bomb = main.spawn_bomb(main.room.data.tile_center(Vector2i(9, 8)))
	bomb.detonate()
	assert_eq(enemy.health.current, maxi(0, life - 3), "3 damage, the shield does not stop it")
	assert_true(pot.is_broken, "the pot broke")
	assert_eq(p.health.current, mine - 1, "Yggnus was too close")


func test_placing_a_charge_spends_one_and_it_goes_off_after_the_fuse() -> void:
	var p := _setup("r01_cruzamento", Vector2i(20, 12), {"carga_bronze": 2})
	main.equipped = "cargas"
	p.motor.facing = Vector2.RIGHT
	assert_eq(main.place_bomb(), "placed", "placed")
	assert_eq(main.state.item_count("carga_bronze"), 1, "one spent")
	assert_eq(main.active_bombs().size(), 1, "burning")
	var b: Bomb = main.active_bombs()[0]
	assert_true(b.global_position.x > p.global_position.x, "in front of Yggnus")
	b.burn(1.0)
	assert_true(not b.done, "not yet at 1 s")
	b.burn(0.7)
	assert_true(b.done, "off after 1.6 s")


func test_the_merchant_sells_charges_only_after_the_first() -> void:
	_setup("v01_praca", Vector2i(6, 12))
	var ids := func() -> Array: return main.shop.for_state(main.state).map(func(o: Dictionary) -> String: return str(o["id"]))
	assert_true(not ids.call().has("tres_cargas"), "hidden at first")
	main.state.apply(main.config.reward_effects("chest_cargas_poco"))
	assert_true(main.state.has_flag("gear.cargas"), "the cellar chest teaches them")
	assert_eq(main.state.item_count("carga_bronze"), 3, "three charges")
	assert_true(ids.call().has("tres_cargas"), "now for sale")
	main.state.apply([{"op": "add_bronze", "amount": 50}])
	var offer: Dictionary = main.shop.for_state(main.state).filter(func(o: Dictionary) -> bool: return o["id"] == "tres_cargas")[0]
	assert_true(main.shop.buy(main.state, offer), "bought")
	assert_eq(main.state.item_count("carga_bronze"), 6, "3 more")
	main.state.apply([{"op": "add_item", "item_id": "carga_bronze", "quantity": 2, "stack_limit": 9}])
	assert_true(not main.shop.refusal(main.state, offer).is_empty(), "8 + 3 does not fit in 9")


func test_both_torches_lit_open_the_sealed_door_for_good() -> void:
	var p := _setup("r02_bomba", Vector2i(17, 20), {"lamparina_oleo": 1})
	var door := _door("door.r02_bomba.r03_poco")
	assert_eq(main.room.torches.size(), 2, "two torches")
	assert_true(not main.is_door_open(door), "sealed")
	main.equipped = "lamparina"
	p.motor.facing = Vector2.LEFT
	p.respawn_at(main.room.data.tile_center(Vector2i(17, 20)), false)
	assert_eq(main.use_lamp(), "lit", "the first catches")
	assert_true(not main.is_door_open(door), "still sealed")
	main._tool_cooldown = 0.0
	p.motor.facing = Vector2.RIGHT
	p.respawn_at(main.room.data.tile_center(Vector2i(20, 20)), false)
	assert_eq(main.use_lamp(), "solved", "both burn")
	assert_true(main.is_door_open(door), "the door opened")
	main.load_room("r02_bomba", Vector2i(20, 12))
	assert_true(main.room.torches.all(func(t: Torch) -> bool: return t.lit), "still lit on the next visit")


func test_a_lone_torch_goes_out_when_leaving() -> void:
	var p := _setup("r02_bomba", Vector2i(17, 20), {"lamparina_oleo": 1})
	p.motor.facing = Vector2.LEFT
	assert_eq(main.use_lamp(), "lit", "one lit")
	main.load_room("r02_bomba", Vector2i(20, 12))
	assert_true(main.room.torches.all(func(t: Torch) -> bool: return not t.lit), "out again")


func test_the_lamp_widens_the_light_in_the_dark_well() -> void:
	var p := _setup("r03_poco", Vector2i(20, 17))
	assert_true(main.room.is_dark(), "the well is dark")
	var glow := p.get_node_or_null("Glow") as PointLight2D
	if glow == null:
		return  # no sprite sheet, no glow (headless without art)
	var small := glow.texture_scale
	main.state.apply([{"op": "grant_unique", "item_id": "lamparina_oleo", "quantity": 1, "receipt_id": "t.lamp"}])
	assert_true(glow.texture_scale > small, "wider with the lamp")


func test_the_new_rooms_are_saveable_and_tools_round_trip() -> void:
	_setup("r04_adega", Vector2i(12, 14), {"arco_fio": 1, "agulha_fio": 4})
	main.equipped = "arco"
	var doc := SaveGame.capture(main.state, {"room": "r04_adega", "entry": Vector2i(12, 14), "life": 6, "tool": "arco", "playtime": 1, "slot": 1})
	var checker := SaveGame.new(main.config.room_ids, main.config.items.keys(), main.config.fragments.keys())
	assert_eq(checker.validate(doc), [], "valid save in a new room with the bow")
	main.continue_from(doc)
	assert_eq(main.equipped, "arco", "bow still on the button")
	assert_eq(main.room_id, "r04_adega", "same room")


func test_the_bow_draw_keeps_yggnus_busy() -> void:
	var p := _setup("r01_cruzamento", Vector2i(20, 12), {"arco_fio": 1, "agulha_fio": 3})
	p.motor.facing = Vector2.RIGHT
	assert_eq(main.shoot_arrow(), "shot", "drawing")
	assert_true(p.is_busy(), "busy while drawing")
	p.request_attack()
	await _frames(2)
	assert_true(not p.sword.is_busy(), "no sword swing during the draw")
	await _frames(15)
	assert_true(not p.is_busy(), "free once the needle is off")


func test_a_full_quiver_leaves_needles_on_the_ground() -> void:
	var p := _setup("r01_cruzamento", Vector2i(20, 12), {"arco_fio": 1, "agulha_fio": 20})
	var n: Pickup = main.drop_needles(p.global_position, 3, 10.0)
	await _frames(3)
	assert_true(is_instance_valid(n), "still there")
	assert_eq(main.state.item_count("agulha_fio"), 20, "nothing lost or added")
	main.state.apply([{"op": "use_item", "item_id": "agulha_fio"}])
	await _frames(3)
	assert_true(not is_instance_valid(n), "picked up once there is room")
	assert_eq(main.state.item_count("agulha_fio"), 20, "19 + 1 (the rest did not fit)")


func test_a_charge_never_takes_the_last_point_of_life() -> void:
	var p := _setup("r01_cruzamento", Vector2i(20, 12), {"carga_bronze": 1})
	p.health.take_damage(p.health.current - 1)
	p.health.tick(5.0)
	var b: Bomb = main.spawn_bomb(p.global_position)
	b.detonate()
	assert_eq(p.health.current, 1, "still standing at 1")
	assert_true(not p.is_dead(), "alive")


func test_a_needle_stops_at_a_chest_and_a_weight() -> void:
	var p := _setup("t04_pesos", Vector2i(6, 18), {"arco_fio": 1})
	var a: Arrow = main.spawn_arrow(p.global_position, Vector2.UP)
	for i in 60:
		if a.advance(1.0 / 60.0):
			break
	assert_true(a.global_position.y > main.room.data.tile_center(Vector2i(6, 13)).y, "stopped at the weight, not past it")


func test_a_near_miss_by_one_column_still_hits_the_plate() -> void:
	var p := _setup("t06_marco", Vector2i(17, 8), {"arco_fio": 1})
	var a: Arrow = main.spawn_arrow(p.global_position, Vector2.UP)
	for i in 60:
		if a.advance(1.0 / 60.0):
			break
	assert_true(main.state.has_flag("world.plate.t06_marco"), "a column off still counts")


func test_the_shop_will_not_sell_hidden_charges() -> void:
	_setup("v01_praca", Vector2i(6, 12))
	main.state.apply([{"op": "add_bronze", "amount": 50}])
	var offer: Dictionary = main.shop.offers.filter(func(o: Dictionary) -> bool: return o["id"] == "tres_cargas")[0]
	assert_true(not main.shop.buy(main.state, offer), "not before the first charges")
	assert_eq(main.state.bronze, 50, "nothing spent")


func test_chest_text_names_amounts_and_extras() -> void:
	# The bow is the tower's chest item (jogabilidade-classica.md §3.5).
	var p := _setup("t06_marco", Vector2i(8, 10))
	p.motor.facing = Vector2.UP
	assert_eq(main.interact(), "chest", "opened")
	assert_true(main.hud._toast.text.contains("Recebeu Arco de Fio e 10 Agulhas de Fio"), main.hud._toast.text)
	assert_eq(main.state.item_count("agulha_fio"), 10, "ten needles")
