extends TestCase
## Detailed scenery: how a room picks its tiles, rugs, wall decoration and
## lights from the map and cenario.json.


func _room(id: String) -> Room:
	var room := Room.new()
	room._ready()
	room.build(RoomData.load_room(id))
	return room


## The workshop as it was before it was painted: a tile room with a rug and
## two furniture blocks (tests/fixtures/maps/v00_oficina.json).
func _tile_room() -> Room:
	var room := Room.new()
	room._ready()
	room.build(RoomData.load_room("v00_oficina", "res://tests/fixtures/maps"))
	return room


func test_top_wall_is_tall_and_inner_blocks_are_furniture() -> void:
	var room := _tile_room()
	assert_true(room.is_tall_wall(Vector2i(5, 0)), "top wall above the floor")
	assert_true(not room.is_tall_wall(Vector2i(0, 5)), "side wall is not")
	assert_eq(room.tile_kind(Vector2i(0, 5)), "wall_top", "side wall shows its top")
	assert_true(room.is_furniture(Vector2i(6, 5)), "block inside the room")
	assert_eq(room.tile_kind(Vector2i(6, 6)), "furn_front", "front row of a block")
	assert_true(room.tile_kind(Vector2i(6, 5)).begins_with("furn_top_"), "top row of a block")
	assert_eq(room.top_extent(), 32, "two extra wall rows above row 0")
	room.free()


func test_rug_pieces_follow_their_neighbours() -> void:
	var room := _tile_room()  # rug at [9, 8, 5, 3]
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
	room.build(RoomData.load_room("v00_oficina", "res://tests/fixtures/maps"))
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


func test_a_painted_room_draws_its_picture_instead_of_tiles() -> void:
	var room := _room("v01_praca")  # "art": {"background": "v01_praca"}
	assert_true(room.is_painted(), "the square is a painted room")
	assert_eq(Vector2i(room.background.get_size()), room.data.pixel_size(), "the picture is the room's size")
	assert_eq(room.top_extent(), 0, "no tall wall above row 0")
	assert_eq(room.decor.size(), 0, "no tile decoration")
	assert_eq(room.light_specs.size(), 0, "the lamps are in the picture")
	assert_true(room.painted_objects.has("bush"), "bushes redrawn in the picture's style")
	room.free()


func test_a_tile_room_is_not_painted() -> void:
	var room := _room("t02_oficina")
	assert_true(not room.is_painted(), "no background")
	assert_true(room.painted_objects.is_empty(), "objects from the tile sheet")
	room.free()


func test_people_in_the_picture_get_no_sprite() -> void:
	var room := _room("v01_praca")
	var merchant: Dictionary = room.data.entities.filter(func(e: Dictionary) -> bool: return e["id"] == "v01_praca.merchant")[0]
	assert_true(room.is_painted_entity(merchant), "the merchant is painted at the stall")
	for c in room.get_children():
		if c is Room.Prop:
			assert_true(str((c as Room.Prop).entity.get("id", "")) != "v01_praca.merchant", "no prop for the merchant")
	room.free()


func test_a_wide_way_out_covers_its_whole_span() -> void:
	var room := _room("v01_praca")  # road north at [18, 1], span 4
	var road: Dictionary = room.data.doors.filter(func(d: Dictionary) -> bool: return d["id"] == "door.v01_praca.r00_estrada")[0]
	var zone := room.door_zone(road)
	for x in range(18, 22):
		assert_true(zone.has_point(room.data.tile_center(Vector2i(x, 1))), "column %d of the road" % x)
	assert_true(not zone.has_point(room.data.tile_center(Vector2i(22, 1))), "not past the road")
	room.free()


func test_every_painted_map_matches_its_picture() -> void:
	# Each map naming a background must have it, at the map's size, and its
	# doors and entities must stand where the map says (floor, or a wall the
	# painting shows them in, for painted people).
	for f in DirAccess.get_files_at("res://assets/data/maps"):
		var data := RoomData.load_room(f.get_basename())
		if data == null or str(data.art.get("background", "")).is_empty():
			continue
		var path := "res://assets/art/salas/%s.png" % data.art["background"]
		assert_true(ResourceLoader.exists(path), "%s has its picture" % data.id)
		if ResourceLoader.exists(path):
			assert_eq(Vector2i((load(path) as Texture2D).get_size()), data.pixel_size(), "%s picture size" % data.id)
		for d: Dictionary in data.doors:
			var t: Array = d["tile"]
			assert_true(data.is_walkable(Vector2i(int(t[0]), int(t[1]))), "%s door on floor" % d["id"])
		for e: Dictionary in data.entities:
			var t: Array = e["tile"]
			assert_true(bool(e.get("painted", false)) or data.is_walkable(Vector2i(int(t[0]), int(t[1]))), "%s on floor" % e["id"])


func test_world_reward_tiles_match_the_maps() -> void:
	# recompensas-mundo.json repeats where each fragment is; a redrawn room
	# must move it there too.
	var f := FileAccess.open("res://assets/data/recompensas-mundo.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(f.get_as_text())
	for frag: Dictionary in data.get("fragments", []):
		if not frag.has("tile") or not frag.has("room"):
			continue
		var room := RoomData.load_room(str(frag["room"]))
		var found := room.entities.filter(func(e: Dictionary) -> bool: return str(e.get("collectible_id", "")) == str(frag.get("id", "")))
		if found.is_empty():
			continue
		assert_eq(found[0]["tile"], frag["tile"], "%s tile" % frag["id"])



## Floor cells reachable from [param start]. Bushes and pots block, unless
## [param cut] is true: Yggnus starts with the sword, so a collectible may
## hide behind them (the road hides a fragment behind two bushes), but a
## door never should.
func _reachable(data: RoomData, start: Vector2i, cut := false) -> Dictionary:
	var blocked := {}
	if not cut:
		for kind: String in data.breakables:
			for at: Vector2i in data.breakables[kind]:
				blocked[at] = true
	var seen := {start: true}
	var todo: Array[Vector2i] = [start]
	while not todo.is_empty():
		var at: Vector2i = todo.pop_back()
		for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n := at + dir
			if not seen.has(n) and data.is_walkable(n) and not blocked.has(n):
				seen[n] = true
				todo.append(n)
	return seen


func _touches(seen: Dictionary, at: Vector2i) -> bool:
	if seen.has(at):
		return true
	for dir: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if seen.has(at + dir):
			return true
	return false


func test_every_painted_room_is_connected() -> void:
	# A hand-drawn grid can wall a part of the room off (it once cut the
	# workshop door and the road off from the square): from the default
	# entry, every door must be reached and everything must be next to it.
	for f in DirAccess.get_files_at("res://assets/data/maps"):
		var data := RoomData.load_room(f.get_basename())
		if data == null or str(data.art.get("background", "")).is_empty():
			continue
		var seen := _reachable(data, data.entry_default)
		for d: Dictionary in data.doors:
			var t: Array = d["tile"]
			assert_true(seen.has(Vector2i(int(t[0]), int(t[1]))), "%s reached without cutting" % d["id"])
		seen = _reachable(data, data.entry_default, true)
		for e: Dictionary in data.entities:
			var t: Array = e["tile"]
			assert_true(_touches(seen, Vector2i(int(t[0]), int(t[1]))), "%s reached" % e["id"])
		for kind: String in data.breakables:
			for at: Vector2i in data.breakables[kind]:
				assert_true(_touches(seen, at), "%s %s reached" % [kind, at])
