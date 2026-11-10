extends TestCase
## Key dungeons (Dungeons): layout from side doors, map, compass, keys and
## the big-key door (design/gdd/masmorras.md).


func _state() -> GameState:
	return GameState.new()


func test_the_tower_layout_follows_its_side_doors() -> void:
	var d := Dungeons.load_from()
	var cells := d.layout("akurame")
	assert_eq(cells.get("t00_base"), Vector2i(0, 0), "start")
	assert_eq(cells.get("t01_guardas"), Vector2i(1, 0), "east of the base")
	assert_eq(cells.get("t02_oficina"), Vector2i(1, -1), "north of the guards")
	assert_eq(cells.get("t07_igris"), Vector2i(5, -1), "the arena past the antechamber")
	assert_eq(cells.size(), 8, "eight rooms")
	assert_eq(d.dungeon_of("t03_treino"), "akurame", "a tower room")
	assert_eq(d.dungeon_of("r01_cruzamento"), "", "outside")


func test_rooms_show_when_visited_or_with_the_map() -> void:
	var d := Dungeons.load_from()
	var s := _state()
	s.apply([{"op": "set_flag", "flag": "visited.t01_guardas", "value": true}])
	var v := d.map_view("akurame", s, "t00_base")
	var shown: Array = v["rooms"].filter(func(r: Dictionary) -> bool: return r["shown"]).map(func(r: Dictionary) -> String: return r["id"])
	assert_eq(shown.size(), 2, "the room here and the visited one: %s" % [shown])
	s.apply([{"op": "grant_unique", "item_id": "mapa_akurame", "quantity": 1, "receipt_id": "t.map"}])
	v = d.map_view("akurame", s, "t00_base")
	assert_true(v["rooms"].all(func(r: Dictionary) -> bool: return r["shown"]), "the map shows every room")
	assert_true(v["rooms"].filter(func(r: Dictionary) -> bool: return r["visited"]).size() == 2, "still only two visited")


func test_the_compass_marks_closed_chests_and_the_boss() -> void:
	var d := Dungeons.load_from()
	var s := _state()
	var v := d.map_view("akurame", s, "t00_base")
	assert_true(v["rooms"].all(func(r: Dictionary) -> bool: return not r["chest"] and not r["boss"]), "nothing without the compass")
	s.apply([{"op": "grant_unique", "item_id": "bussola_akurame", "quantity": 1, "receipt_id": "t.compass"}])
	v = d.map_view("akurame", s, "t00_base")
	var chests: Array = v["rooms"].filter(func(r: Dictionary) -> bool: return r["chest"]).map(func(r: Dictionary) -> String: return r["id"])
	assert_true(chests.has("t05_sinos") and chests.has("t00_base"), "closed chests: %s" % [chests])
	s.apply([{"op": "add_receipt", "receipt_id": "unique.t05_sinos.chave_chefe"}])
	v = d.map_view("akurame", s, "t00_base")
	assert_true(not v["rooms"].any(func(r: Dictionary) -> bool: return r["id"] == "t05_sinos" and r["chest"]), "an opened chest is not marked")
	assert_true(v["rooms"].any(func(r: Dictionary) -> bool: return r["id"] == "t07_igris" and r["boss"]), "the boss room is marked")
	s.apply([{"op": "set_flag", "flag": "seen.t10", "value": true}])
	v = d.map_view("akurame", s, "t00_base")
	assert_true(not v["rooms"].any(func(r: Dictionary) -> bool: return r["boss"]), "not after the boss")


func test_the_big_key_door() -> void:
	var d := Dungeons.load_from()
	var s := _state()
	assert_true(not d.boss_gate_open("chave_chefe_akurame", s), "closed without the key")
	s.apply([{"op": "grant_unique", "item_id": "chave_chefe_akurame", "quantity": 1, "receipt_id": "t.bk"}])
	assert_true(d.boss_gate_open("chave_chefe_akurame", s), "open with it")
	var old := _state()
	old.apply([{"op": "set_flag", "flag": "seen.t10", "value": true}])
	assert_true(d.boss_gate_open("chave_chefe_akurame", old), "a save past the boss is never locked out")


func test_key_count() -> void:
	var d := Dungeons.load_from()
	var s := _state()
	s.apply([{"op": "grant_unique", "item_id": "key_ak_base", "quantity": 1, "receipt_id": "t.k"}])
	assert_eq(d.map_view("akurame", s, "t00_base")["small_keys"], 1, "one small key")
