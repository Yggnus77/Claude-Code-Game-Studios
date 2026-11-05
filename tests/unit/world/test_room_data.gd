extends TestCase
## Unit tests for RoomData parsing and wall merging.


func _sample() -> RoomData:
	return RoomData.from_dict({
		"id": "sample", "width": 5, "height": 4, "tile_size": 16,
		"grid": ["#####", "#..~#", "#...#", "#####"],
		"entry_default": [1, 2],
	})


func test_walkable_cells() -> void:
	var room := _sample()
	assert_true(room.is_walkable(Vector2i(1, 1)), "floor is walkable")
	assert_true(not room.is_walkable(Vector2i(0, 0)), "wall is not walkable")
	assert_true(not room.is_walkable(Vector2i(3, 1)), "gap is not walkable on foot")
	assert_true(not room.is_walkable(Vector2i(-1, 2)), "outside the grid counts as wall")


func test_merged_rects_cover_every_wall_once() -> void:
	var room := _sample()
	var covered := {}
	for r in room.merged_rects(RoomData.WALL):
		for y in range(r.position.y, r.end.y):
			for x in range(r.position.x, r.end.x):
				var key := Vector2i(x, y)
				assert_true(not covered.has(key), "cell %s covered twice" % key)
				covered[key] = true
	var walls := 0
	for y in room.height:
		for x in room.width:
			if room.cell(Vector2i(x, y)) == RoomData.WALL:
				walls += 1
				assert_true(covered.has(Vector2i(x, y)), "wall %s not covered" % Vector2i(x, y))
	assert_eq(covered.size(), walls, "rects cover exactly the wall cells")


func test_every_prototype_room_loads() -> void:
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/mapas-prototipo.json"))
	for id in index["rooms"]:
		var room := RoomData.load_room(id)
		assert_true(room != null, "room %s loads" % id)
		if room == null:
			continue
		assert_eq(room.grid.size(), room.height, "%s grid height" % id)
		assert_true(room.is_walkable(room.entry_default), "%s entry is on floor" % id)
