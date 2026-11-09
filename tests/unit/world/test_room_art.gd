extends TestCase
## Detailed scenery: how a room picks its tiles, rugs, wall decoration and
## lights from the map and cenario.json.


func _room(id: String) -> Room:
	var room := Room.new()
	room._ready()
	room.build(RoomData.load_room(id))
	return room


func test_top_wall_is_tall_and_inner_blocks_are_furniture() -> void:
	var room := _room("v00_oficina")
	assert_true(room.is_tall_wall(Vector2i(5, 0)), "top wall above the floor")
	assert_true(not room.is_tall_wall(Vector2i(0, 5)), "side wall is not")
	assert_eq(room.tile_kind(Vector2i(0, 5)), "wall_top", "side wall shows its top")
	assert_true(room.is_furniture(Vector2i(6, 5)), "block inside the room")
	assert_eq(room.tile_kind(Vector2i(6, 6)), "furn_front", "front row of a block")
	assert_true(room.tile_kind(Vector2i(6, 5)).begins_with("furn_top_"), "top row of a block")
	assert_eq(room.top_extent(), 32, "two extra wall rows above row 0")
	room.free()


func test_rug_pieces_follow_their_neighbours() -> void:
	var room := _room("v00_oficina")  # rug at [9, 8, 5, 3]
	assert_eq(room.rug_piece(Vector2i(9, 8)), "rug_tl", "top left corner")
	assert_eq(room.rug_piece(Vector2i(11, 8)), "rug_t", "top edge")
	assert_eq(room.rug_piece(Vector2i(11, 9)), "rug_c", "middle")
	assert_eq(room.rug_piece(Vector2i(13, 10)), "rug_br", "bottom right corner")
	assert_eq(room.rug_piece(Vector2i(8, 8)), "", "outside the rug")
	room.free()


func test_every_tile_kind_exists_in_the_sheet() -> void:
	var f := FileAccess.open("res://assets/art/cenario/cenario.json", FileAccess.READ)
	var art: Dictionary = JSON.parse_string(f.get_as_text())
	var cols: Array = art["tile_cols"]
	for kind in ["wall_upper", "wall_mid", "wall_lower", "floor_a", "floor_d", "wall_top", "furn_top_d",
			"furn_front", "gap", "gap_edge", "decal_d", "rug_c", "rug_br"]:
		assert_true(cols.has(kind), "column '%s'" % kind)
	for theme: String in art["themes"]:
		assert_eq((art["decor"][theme] as Array).size(), 6, "six decorations for %s" % theme)
		assert_true(art["lighting"].has(theme), "lighting for %s" % theme)


func test_decor_sits_on_the_tall_wall_and_lamps_light_up() -> void:
	var room := _room("t07_igris")
	assert_true(room.decor.size() > 0, "the tower wall is decorated")
	for d: Dictionary in room.decor:
		assert_true(room.is_tall_wall(d["tile"]), "decoration on the tall wall")
	assert_true(room.light_specs.size() > 0, "torches and braziers give light")
	var ambient := room.get_node_or_null("Ambient")
	assert_true(ambient is CanvasModulate, "the room is dimmed by its theme's ambient")
	room.free()


func test_effects_without_a_parent_are_dropped() -> void:
	assert_eq(Fx.hit_sparks(null, Vector2.ZERO, Vector2.LEFT), null, "no parent, no sparks")
	assert_eq(Fx.dust(null, Vector2.ZERO), null, "no parent, no dust")


func test_rebuilding_replaces_the_old_lights_at_once() -> void:
	var room := _room("t07_igris")
	room.build(RoomData.load_room("v00_oficina"))
	assert_true(room.get_node_or_null("Ambient") is CanvasModulate, "the new ambient keeps its name")
	var ambients := room.get_children().filter(func(n: Node) -> bool: return n is CanvasModulate)
	assert_eq(ambients.size(), 1, "only one ambient per room")
	assert_true(room.light_specs.size() <= Room.MAX_ROOM_LIGHTS, "lights capped")
	room.free()


func test_a_wall_joined_to_the_top_edge_is_not_furniture() -> void:
	var d := RoomData.from_dict({"id": "t99", "width": 6, "height": 5, "tile_size": 16, "grid": [
		"######", "#.##.#", "#....#", "#.##.#", "######"]})
	var room := Room.new()
	room._ready()
	room.build(d)
	assert_true(not room.is_furniture(Vector2i(2, 1)), "pillar hanging from the top wall")
	assert_eq(room.tile_kind(Vector2i(2, 1)), "wall_lower", "it is the tall wall's base")
	assert_true(room.is_furniture(Vector2i(2, 3)), "a free block is furniture")
	room.free()


func test_doors_are_set_into_the_nearest_wall() -> void:
	var room := _room("t00_base")  # doors at [2, 12], [29, 12], [16, 2]
	assert_eq(room.door_frame_tile({"tile": [16, 2]}), Vector2i(16, 0), "north door sits in the tall wall")
	assert_eq(room.door_frame_tile({"tile": [2, 12]}), Vector2i(0, 12), "west door sits in the side wall")
	assert_eq(room.door_frame_tile({"tile": [10, 10]}), Vector2i(10, 10), "far from walls it stays put")
	for d: Dictionary in room.decor:
		assert_true(absi((d["tile"] as Vector2i).x - 16) > 1, "no decoration on the doorway")
	room.free()


func test_walking_up_to_the_arch_uses_the_door() -> void:
	var room := _room("t00_base")  # north door at [16, 2], arch in the wall at [16, 0]
	var zone := room.door_zone({"tile": [16, 2]})
	assert_true(zone.has_point(room.data.tile_center(Vector2i(16, 2))), "the door's own tile")
	assert_true(zone.has_point(Vector2(16 * 16 + 8, 16 + 4)), "right under the arch, against the wall")
	assert_true(not zone.has_point(room.data.tile_center(Vector2i(16, 3))), "not the tile in front of it")
	var west := room.door_zone({"tile": [2, 12]})
	assert_true(west.has_point(Vector2(16 + 4, 12 * 16 + 8)), "against the west wall")
	room.free()
