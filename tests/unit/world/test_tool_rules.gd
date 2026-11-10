extends TestCase
## Unit: the item-button tool rules (design/gdd/ferramentas.md §3, §4).


func _state(items: Dictionary = {}, flags: Array = []) -> GameState:
	var s := GameState.new()
	var fx: Array = []
	for id: String in items:
		fx.append({"op": "grant_unique", "item_id": id, "quantity": int(items[id]), "receipt_id": "t.%s" % id})
	for f: String in flags:
		fx.append({"op": "set_flag", "flag": f, "value": true})
	s.apply(fx)
	return s


func test_the_data_file_matches_the_kit_numbers() -> void:
	var t := ToolRules.load_from()
	assert_eq(t.order, ["frasco", "gancho", "arco", "cargas", "lamparina"] as Array[String], "swap order")
	assert_near(t.num("arco", "startup", 0), 0.18, 0.001, "bow draw 0.18 s")
	assert_near(t.num("arco", "speed", 0), 260.0, 0.001, "needle 260 px/s")
	assert_near(t.num("arco", "cooldown", 0), 0.3, 0.001, "bow cooldown 0.30 s")
	assert_eq(int(t.num("arco", "damage", 0)), 2, "needle damage 2")
	assert_eq(t.ammo_cap("arco"), 20, "20 needles at most")
	assert_eq(t.ammo_cap("cargas"), 9, "9 charges at most")
	assert_eq(t.ammo_of("lamparina"), "", "the lamp spends nothing")


func test_only_owned_tools_are_in_the_swap() -> void:
	var t := ToolRules.load_from()
	var s := _state({"arco_fio": 1})
	assert_eq(t.owned(s), ["frasco", "arco"] as Array[String], "flask and bow")
	assert_eq(t.next_tool("frasco", s), "arco", "flask -> bow")
	assert_eq(t.next_tool("arco", s), "frasco", "bow -> flask")
	assert_eq(t.next_tool("gancho", s), "frasco", "a tool not owned falls back to the flask")


func test_spent_charges_stay_in_the_swap_once_known() -> void:
	var t := ToolRules.load_from()
	assert_true(not t.owns("cargas", _state()), "never had charges")
	assert_true(t.owns("cargas", _state({"carga_bronze": 1})), "has one")
	assert_true(t.owns("cargas", _state({}, ["gear.cargas"])), "spent them all but knows them")


func test_labels_show_the_ammunition() -> void:
	var t := ToolRules.load_from()
	var s := _state({"arco_fio": 1, "agulha_fio": 12})
	assert_eq(t.label("arco", s), "Arco 12", "bow with needles")
	assert_eq(t.label("frasco", s), "Frasco", "flask")
	assert_eq(t.label("lamparina", s), "Lamparina", "no count for the lamp")


func test_new_tools_are_found_in_order() -> void:
	var t := ToolRules.load_from()
	var before := t.owned(_state())
	var s := _state({"gancho_retorno": 1, "lamparina_oleo": 1})
	assert_eq(t.new_tools(before, s), ["gancho", "lamparina"] as Array[String], "both, swap order")


func test_a_refill_tops_up_to_ten_and_never_past_the_cap() -> void:
	var t := ToolRules.load_from()
	var s := _state({"arco_fio": 1, "agulha_fio": 4})
	var fx := t.top_up_effects("arco", t.refill_amount, s)
	assert_eq(fx.size(), 1, "one effect")
	assert_true(s.apply(fx), "applies")
	assert_eq(s.item_count("agulha_fio"), 10, "4 -> 10")
	assert_true(t.top_up_effects("arco", t.refill_amount, s).is_empty(), "already at ten")
	assert_true(t.top_up_effects("arco", 50, _state({"agulha_fio": 20})).is_empty(), "never past 20")


func test_a_blast_reaches_a_cracked_wall_with_slack() -> void:
	var t := ToolRules.load_from()
	var arch := Vector2(100, 100)
	var reach := 28.0 + t.num("cargas", "crack_reach", 0.0)
	assert_eq(int(reach), 40, "28 + 12 (ferramentas.json crack_reach)")
	assert_true(t.blast_reaches_wall(Vector2(100, 140), arch, 28.0), "40 px: inside")
	assert_true(not t.blast_reaches_wall(Vector2(100, 141), arch, 28.0), "41 px: outside")


func test_a_broken_file_keeps_the_flask_and_hook() -> void:
	var t := ToolRules.load_from("res://does/not/exist.json")
	assert_eq(t.order, ["frasco", "gancho"] as Array[String], "default order")
	assert_true(t.owns("gancho", _state({"gancho_retorno": 1})), "the hook still works")


func test_a_needle_flies_its_real_speed_and_range() -> void:
	var root := Node2D.new()
	tree.root.add_child(root)
	var a := Arrow.new()
	a.direction = Vector2.RIGHT
	a.speed = 260.0
	a.max_range = 224.0
	root.add_child(a)
	a.set_physics_process(false)
	for i in 30:
		a.advance(1.0 / 60.0)
	assert_near(a.position.x, 130.0, 0.5, "130 px after 0.5 s at 260 px/s")
	assert_near(a.travelled, a.position.x, 0.01, "counted distance = distance moved")
	var frames := 30
	while not a.advance(1.0 / 60.0):
		frames += 1
	assert_true(frames >= 50 and frames <= 53, "stops after ~0.86 s (%d frames)" % frames)
	root.queue_free()
