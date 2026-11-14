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
	var common := SpriteAtlas.enemies()
	assert_true(art.frame_size.x > common.frame_size.x and art.frame_size.y > common.frame_size.y, "Igris is bigger than a common enemy")
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


## Sum of colour differences between two frames of the same size.
func _difference(a: Image, b: Image) -> float:
	var total := 0.0
	for y in a.get_height():
		for x in a.get_width():
			var p := a.get_pixel(x, y)
			var q := b.get_pixel(x, y)
			total += absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) + absf(p.a - q.a)
	return total


func test_yggnus_walks_sideways_facing_where_he_goes() -> void:
	# User report 2026-11-13: walking sideways he looked backwards. Every side
	# walk frame must face the same way as the side idle frame (right).
	var picker := SpritePicker.load_meta("res://assets/art/personagens/yggnus.json")
	var sheet: Image = (load("res://assets/art/personagens/yggnus.png") as Texture2D).get_image()
	sheet.decompress()
	var size := picker.frame_size
	var row := int(picker.rows["side"]) * size.y
	var idle := sheet.get_region(Rect2i(int(picker.anims["idle"][0]) * size.x, row, size.x, size.y))
	for col in picker.anims["walk"]:
		var frame := sheet.get_region(Rect2i(int(col) * size.x, row, size.x, size.y))
		var mirrored := frame.duplicate() as Image
		mirrored.flip_x()
		assert_true(_difference(idle, frame) < _difference(idle, mirrored), "walk column %d faces right" % col)
