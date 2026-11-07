extends TestCase
## Arte P1: the sheets the game draws from are present and match the code.


func test_enemy_atlas_has_a_frame_for_every_state_drawn() -> void:
	var art := SpriteAtlas.enemies()
	assert_true(art != null, "inimigos.png and its JSON load")
	for f in ["rastejo_idle0", "rastejo_idle1", "rastejo_telegraph", "rastejo_charge", "mariposa_fly0",
			"mariposa_fly1", "mariposa_dive", "soldado_idle", "soldado_windup", "soldado_strike",
			"guarda_idle", "guarda_raise", "guarda_open", "yame_idle", "yame_telegraph"]:
		assert_true(art.has_frame(f), "frame '%s'" % f)


func test_igris_atlas_has_every_fight_phase() -> void:
	var art := SpriteAtlas.igris()
	assert_true(art != null, "igris.png loads")
	assert_eq(art.frame_size, Vector2(48, 64), "Igris is bigger")
	for f in ["idle", "muffler", "regulator", "free"]:
		assert_true(art.has_frame(f), "frame '%s'" % f)


func test_bell_columns_match_the_objects_sheet() -> void:
	var f := FileAccess.open("res://assets/art/cenario/cenario.json", FileAccess.READ)
	var json := JSON.new()
	assert_eq(json.parse(f.get_as_text()), OK, "cenario.json parses")
	var cols: Array = json.data["object_cols"]
	assert_eq(cols.find("bell"), Bell.BELL_COL, "bell column")
	assert_eq(cols.find("bell_lit"), Bell.BELL_LIT_COL, "lit bell column")


func test_room_theme_follows_the_room_id() -> void:
	var room := Room.new()
	room._ready()
	assert_eq(room.theme_row("v00_oficina"), 0, "workshop")
	assert_eq(room.theme_row("v01_praca"), 1, "square")
	assert_eq(room.theme_row("r02_bomba"), 2, "road")
	assert_eq(room.theme_row("t07_igris"), 3, "tower")
	room.free()
