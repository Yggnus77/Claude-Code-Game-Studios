extends TestCase
## Bush and pot rules (Breakables) and their place in the maps
## (design/gdd/exploracao.md §2).


func _rules() -> Breakables:
	var b := Breakables.new()
	b.kinds = {"bush": {"solid": true, "stub": "bush_cut", "drops": [["none", 2], ["vida_1", 1], ["bronze_1", 1]]}}
	return b


func test_drops_follow_the_weights() -> void:
	var b := _rules()
	assert_eq(b.drop_for("bush", 0.0), "none", "first half: nothing")
	assert_eq(b.drop_for("bush", 0.49), "none", "still nothing")
	assert_eq(b.drop_for("bush", 0.5), "vida_1", "third quarter: life")
	assert_eq(b.drop_for("bush", 0.8), "bronze_1", "last quarter: Bronze")
	assert_eq(b.drop_for("bush", 1.0), "bronze_1", "1.0 counts as the end")
	assert_eq(b.drop_for("rock", 0.8), "none", "unknown kind")


func test_bad_tables_drop_nothing() -> void:
	var b := Breakables.new()
	b.kinds = {"a": {"drops": "x"}, "b": {"drops": [["vida_1", -3]]}, "c": {}}
	for k in ["a", "b", "c"]:
		assert_eq(b.drop_for(k, 0.5), "none", "kind %s" % k)


func test_life_amount() -> void:
	assert_eq(Breakables.life_amount("vida_1"), 1, "one")
	assert_eq(Breakables.life_amount("vida_3"), 3, "three")
	assert_eq(Breakables.life_amount("bronze_1"), 0, "not life")
	assert_eq(Breakables.life_amount("vida_-2"), 0, "never negative")


func test_the_data_file_loads() -> void:
	var b := Breakables.load_from()
	assert_true(b.has_kind("bush") and b.has_kind("pot"), "bush and pot")
	assert_eq(b.stub("bush"), "bush_cut", "a cut bush leaves a stub")
	assert_eq(b.stub("pot"), "", "a pot leaves nothing")
	assert_true(b.is_solid("pot"), "pots block the way")
	assert_true(b.life_lifetime > 0.0, "life drops last a while")
	assert_eq(Breakables.load_from("res://nope.json").kinds.size(), 0, "missing file: none")


func test_maps_only_put_breakables_on_reachable_floor() -> void:
	var b := Breakables.load_from()
	for path in DirAccess.get_files_at("res://assets/data/maps"):
		if not path.ends_with(".json"):
			continue
		var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/maps/" + path))
		var data := RoomData.load_room(path.get_basename())
		var listed := 0
		for kind: String in raw.get("breakables", {}):
			assert_true(b.has_kind(kind), "%s: %s is a known kind" % [path, kind])
			listed += (raw["breakables"][kind] as Array).size()
		var parsed := 0
		for kind: String in data.breakables:
			parsed += (data.breakables[kind] as Array).size()
		assert_eq(parsed, listed, "%s: every listed cell is floor" % path)
		assert_true(not data.breakables.has("bush") or path.begins_with("v") or path.begins_with("r"), "%s: bushes outdoors" % path)
		if path.begins_with("t07"):
			assert_eq(listed, 0, "no breakables in the boss arena")


func test_room_data_skips_walls_and_repeats() -> void:
	var d := RoomData.from_dict({"id": "x", "width": 3, "height": 3, "grid": ["###", "#..", "###"],
		"breakables": {"pot": [[1, 1], [1, 1], [0, 0], [2, 1], "bad"], "bush": 4}})
	assert_eq(d.breakables["pot"], [Vector2i(1, 1), Vector2i(2, 1)] as Array[Vector2i], "floor cells, once")
	assert_true(not d.breakables.has("bush"), "a non-list is skipped")
