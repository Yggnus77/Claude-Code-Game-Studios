extends TestCase
## Integration: bushes and pots in real rooms, the drops they give and the
## screen sliding between rooms (design/gdd/exploracao.md).

var main: Node


func _setup(room_id: String, tile: Vector2i) -> Player:
	main = load("res://src/scenes/main.tscn").instantiate()
	main.play_intro = false
	tree.root.add_child(main)
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


func _breakable_at(at: Vector2i) -> Breakable:
	for b in tree.get_nodes_in_group("breakables"):
		if b is Breakable and (b as Breakable).tile == at:
			return b
	return null


func test_the_sword_cuts_a_bush_and_it_drops_life() -> void:
	var p := _setup("v01_praca", Vector2i(3, 15))
	var bush := _breakable_at(Vector2i(3, 14))
	assert_true(bush != null, "a bush above")
	main.drop_roll = func() -> float: return 0.8  # vida_1 in the bush table
	p.health.take_damage(2)
	p.health.tick(5.0)
	p.motor.facing = Vector2.UP
	p.request_attack()
	await _frames(20)
	assert_true(bush.is_broken, "cut")
	assert_eq(bush.collision_layer, 0, "the stub does not block")
	var hearts := tree.get_nodes_in_group("pickups").filter(func(n: Node) -> bool: return n is Pickup and (n as Pickup).kind == Pickup.KIND_LIFE)
	# The wide swing also cuts the bush beside it (jogabilidade-classica §3.1).
	assert_true(hearts.size() >= 1, "a life drop (%d)" % hearts.size())
	var before := p.health.current
	p.respawn_at(main.room.data.tile_center(Vector2i(3, 14)), false)
	await _frames(3)
	assert_eq(p.health.current, before + 1, "walking over it heals 1")


func test_a_bush_blocks_until_cut_and_grows_back() -> void:
	var p := _setup("v01_praca", Vector2i(3, 15))
	p.input_override = Vector2.UP
	await _frames(30)
	p.input_override = Vector2.ZERO
	var bush_y: float = main.room.data.tile_center(Vector2i(3, 14)).y
	assert_true(p.global_position.y > bush_y + 8.0, "stopped by the bush")
	_breakable_at(Vector2i(3, 14)).break_open()
	main.load_room("v01_praca", Vector2i(3, 15))
	await _frames(1)
	var again := _breakable_at(Vector2i(3, 14))
	assert_true(again != null and not again.is_broken, "whole again on the next visit")


func test_pots_give_bronze_and_vanish() -> void:
	var p := _setup("t02_oficina", Vector2i(12, 12))
	var pot := _breakable_at(Vector2i(22, 6))
	assert_true(pot != null, "a pot")
	main.drop_roll = func() -> float: return 0.99  # bronze_5
	var bronze: int = main.state.bronze
	pot.break_open(p.global_position)
	await _frames(2)
	assert_true(not is_instance_valid(pot), "nothing left of a pot")
	var coins := tree.get_nodes_in_group("pickups").filter(func(n: Node) -> bool: return n is Pickup and (n as Pickup).kind == Pickup.KIND_BRONZE)
	assert_eq(coins.size(), 1, "one coin")
	p.respawn_at((coins[0] as Node2D).global_position, false)
	await _frames(3)
	assert_eq(main.state.bronze, bronze + 5, "5 Bronze")


func test_nothing_drops_in_the_boss_arena() -> void:
	_setup("t02_oficina", Vector2i(12, 12))
	main.igris = Igris.new()
	assert_eq(main._drop_from("pot", Vector2(40, 40), 0.99), "none", "no loot while a boss is here")
	main.igris.free()
	main.igris = null
	assert_eq(main._drop_from("pot", Vector2(40, 40), 0.99), "bronze_5", "loot elsewhere")


func test_side_doors_slide_the_screen() -> void:
	var p := _setup("t00_base", Vector2i(16, 12))
	var door: Dictionary = {}
	for d: Dictionary in main.room.data.doors:
		if str(d.get("side", "")) == "west":
			door = d
	assert_true(not door.is_empty(), "a west door")
	var cam: Camera2D = p.camera
	var done := [false]
	var run := func() -> void:
		await main._go_through(door)
		done[0] = true
	var gone := Vector2i(-1, -1)
	for b in tree.get_nodes_in_group("breakables"):
		gone = (b as Breakable).tile
		(b as Breakable).break_open()
		break
	assert_true(gone.x >= 0, "the base has pots")
	run.call()
	await tree.process_frame
	var ghost := main.get_node_or_null("SlideGhost")
	assert_true(ghost != null, "the old room is drawn beside the new one")
	var ghost_pots := ghost.get_children().filter(func(n: Node) -> bool: return n is Breakable and not n.is_queued_for_deletion())
	assert_true(ghost_pots.size() > 0, "with its pots")
	assert_true(ghost_pots.all(func(n: Node) -> bool: return not n.is_in_group("breakables") and (n as Breakable).collision_layer == 0), "which cannot be hit")
	assert_true(not ghost_pots.any(func(n: Node) -> bool: return (n as Breakable).tile == gone), "a broken pot stays broken")
	assert_true(not cam.limit_enabled, "the camera slides freely")
	while not done[0]:
		await tree.process_frame
	assert_eq(main.room_id, str(door["target_room"]), "arrived")
	await tree.process_frame
	assert_true(main.get_node_or_null("SlideGhost") == null, "the copy is gone")
	assert_true(cam.limit_enabled, "camera limits back")
	assert_eq(cam.offset, Vector2.ZERO, "no offset left")
	assert_true(not tree.paused, "play resumes")
	assert_eq(tree.get_nodes_in_group("breakables").filter(func(n: Node) -> bool: return (n as Node2D).global_position.x > main.room.data.pixel_size().x).size(), 0, "no copy of the old room's pots can be hit")


func test_hud_gauge_counts_fragments_toward_life() -> void:
	_setup("t00_base", Vector2i(16, 12))
	var hud = main.hud
	for i in 3:
		main.state.apply([{"op": "collect_fragment", "fragment_id": "test_%d" % i, "receipt_id": "test.frag.%d" % i}])
	assert_eq(hud.fragment_gauge(), 3, "three of four")
	main.state.apply([{"op": "collect_fragment", "fragment_id": "test_3", "receipt_id": "test.frag.3"}])
	assert_eq(hud.fragment_gauge(), 0, "a full set empties the gauge")
	assert_true(hud._gauge_flash > 0.0, "and it shines")


func test_doors_on_the_same_side_fade_instead() -> void:
	_setup("t00_base", Vector2i(16, 12))
	var to_arena: Dictionary = {}
	var west: Dictionary = {}
	for d: Dictionary in main.room.data.doors:
		if str(d.get("target_room", "")) == "t07_igris":
			to_arena = d
		elif str(d.get("side", "")) == "west":
			west = d
	assert_true(not main._can_slide(to_arena), "both doors north: no edge to slide across")
	assert_true(main._can_slide(west), "west to east slides")


func test_the_boss_door_needs_the_big_key() -> void:
	_setup("t06_marco", Vector2i(12, 9))
	var door: Dictionary = {}
	for d: Dictionary in main.room.data.doors:
		if str(d.get("target_room", "")) == "t07_igris":
			door = d
	assert_true(not main.is_door_open(door), "locked")
	assert_true(main._locked_text(door, str(door["id"])).contains("Chave Grande"), "says which key")
	main.state.apply([{"op": "grant_unique", "item_id": "chave_chefe_akurame", "quantity": 1, "receipt_id": "t.bk"}])
	assert_true(main.is_door_open(door), "open with the big key")
	main._on_room_entered()
	assert_true(main.state.has_flag("visited.t06_marco"), "the room counts as visited")
	main.hud.refresh_status(main.state)
	assert_true(main.hud.counters_text().contains("Chave Grande"), "the HUD shows it: %s" % main.hud.counters_text())
	main.load_room("r01_cruzamento", Vector2i(5, 12))
	assert_true(not main.hud.counters_text().contains("Chave"), "no keys outside the tower")
	assert_true(main.dungeon_map_view().is_empty(), "no map outside")


func _door_by_id(id: String) -> Dictionary:
	for d: Dictionary in main.room.data.doors:
		if str(d["id"]) == id:
			return d
	return {}


func test_leaving_the_workshop_lands_on_the_square_door_steps() -> void:
	# salas-pintadas.md §8.4: the painted square's workshop door is the
	# wooden door at the top left; arriving must not send Yggnus back.
	var p := _setup("v00_oficina", Vector2i(20, 9))
	await main._go_through(_door_by_id("door.v00_oficina.v01_praca"))
	await _frames(20)
	assert_eq(main.room_id, "v01_praca", "in the square")
	assert_eq(p.global_position, main.room.data.tile_center(Vector2i(11, 6)), "on the steps of the wooden door")
	p.input_override = Vector2.DOWN
	await _frames(20)
	p.input_override = Vector2.ZERO
	assert_eq(main.room_id, "v01_praca", "walking off the steps stays in the square")
	assert_true(p.global_position.y > main.room.data.tile_center(Vector2i(11, 6)).y + 8.0, "and walks into the square")


func test_the_square_road_is_barred_until_p07_then_leads_to_the_road() -> void:
	var p := _setup("v01_praca", Vector2i(20, 3))
	p.input_override = Vector2.UP
	await _frames(40)
	p.input_override = Vector2.ZERO
	assert_eq(main.room_id, "v01_praca", "barred before p07")
	main.state.apply([{"op": "set_flag", "flag": "seen.p07", "value": true}])
	p.respawn_at(main.room.data.tile_center(Vector2i(21, 3)), false)
	await _frames(2)
	p.input_override = Vector2.UP
	for i in 120:
		await tree.physics_frame
		if main.room_id != "v01_praca":
			break
	p.input_override = Vector2.ZERO
	assert_eq(main.room_id, "r00_estrada", "the far column of the wide way out still leads on")
