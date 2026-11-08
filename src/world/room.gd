class_name Room
extends Node2D
## Builds a playable room from a [RoomData]: draws the theme's tiles (a wall
## three tiles tall along the top, wall decoration, rugs, floor details and
## soft shadows), adds wall and gap collision, lights the room, and draws
## doors and entities, reflecting the [GameState] (open chests, collected
## fragments, read clues). Flat colours stand in when the art is missing.

## Physics layer used by walls and gaps (layer 1).
const WORLD_LAYER := 1

const COLOR_FLOOR := Color("2b2f3a")
const COLOR_FLOOR_ALT := Color("2f3440")
const COLOR_WALL := Color("6b5a45")
const COLOR_WALL_TOP := Color("8a7458")
const COLOR_GAP := Color("0d0f14")
const COLOR_DOOR := Color("d9a441")
const COLOR_DOOR_LOCKED := Color("8a4a3a")
const COLOR_CHEST := Color("9a6a2e")
const COLOR_CHEST_OPEN := Color("4a3a24")
const COLOR_CLUE := Color("b7e4c7")
const COLOR_NPC := Color("c7b3e6")
const COLOR_INTERACT := Color("7fb7e6")
const COLOR_CHECKPOINT := Color("f2c14e")
const COLOR_FRAGMENT := Color("6fe0e0")
const COLOR_OTHER := Color("5fa8a0")
const COLOR_HIGHLIGHT := Color("ffffff")
## Entity kinds drawn by the room (enemies are their own nodes).
const DRAWN_KINDS := ["chest", "mystery_clue", "npc", "interact", "checkpoint", "unique_fragment", "anchor", "push_block"]

var data: RoomData
## Progress used to draw opened/collected things; may be null in tests.
var state: GameState
## Callable(door: Dictionary) -> bool telling whether a door is open.
var door_open: Callable = func(_door: Dictionary) -> bool: return true
## Entity id to outline (the one the player can interact with).
var highlight_id := ""
## Raised state of push blocks pulled by the hook (by entity id).
var raised: Dictionary = {}

const TILES_PATH := "res://assets/art/cenario/tiles.png"
const OBJECTS_PATH := "res://assets/art/cenario/objetos.png"
const DECOR_PATH := "res://assets/art/cenario/decor.png"
const ART_META := "res://assets/art/cenario/cenario.json"
## Sheets drawn by tools/art/gerar_cenario.py; null keeps the flat colours.
var _tiles: Texture2D
var _objects: Texture2D
var _decor_tex: Texture2D
var _theme := ""
## Decoration hung on the tall top wall: [{"tile": Vector2i, "kind": String}].
var decor: Array = []
## Rug cells (Vector2i -> true), from the map's "art": {"rugs": [[x, y, w, h]]}.
var rug_cells: Dictionary = {}
## Lights placed by [method build]: [{"pos", "color", "energy", "radius"}].
var light_specs: Array = []
var _lights: Array[PointLight2D] = []
var _flicker_time := 0.0
static var _light_texture: GradientTexture2D
var _art: Dictionary = {}
var _theme_row := 0
## Tall things (people, marcos) are child nodes so they sort by height on
## screen with Yggnus and the enemies (main and room use y-sort).
const PROP_KINDS := ["npc", "checkpoint"]
var _props: Array[Node2D] = []


func _ready() -> void:
	y_sort_enabled = true
	if ResourceLoader.exists(TILES_PATH) and ResourceLoader.exists(OBJECTS_PATH):
		var f := FileAccess.open(ART_META, FileAccess.READ)
		var json := JSON.new()
		if f and json.parse(f.get_as_text()) == OK and json.data is Dictionary:
			_art = json.data
			_tiles = load(TILES_PATH)
			_objects = load(OBJECTS_PATH)
			if ResourceLoader.exists(DECOR_PATH):
				_decor_tex = load(DECOR_PATH)


## Replaces the current content with [param room_data].
func build(room_data: RoomData) -> void:
	data = room_data
	for child in get_children():
		child.queue_free()
	name = "Room_%s" % data.id
	_theme_row = theme_row(data.id)
	var themes: Array = _art.get("themes", [])
	_theme = str(themes[_theme_row]) if _theme_row < themes.size() else ""
	_props.clear()
	_lights.clear()
	_plan_art()
	if _tiles:
		for e in data.entities:
			if PROP_KINDS.has(str(e.get("kind", ""))):
				var t: Array = e.get("tile", [0, 0])
				var prop := Prop.new()
				prop.room = self
				prop.entity = e
				prop.position = data.tile_center(Vector2i(int(t[0]), int(t[1])))
				add_child(prop)
				_props.append(prop)
	var body := StaticBody2D.new()
	body.name = "Walls"
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	add_child(body)
	for ch in [RoomData.WALL, RoomData.GAP]:
		for r in data.merged_rects(ch):
			var shape := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = Vector2(r.size * data.tile_size)
			shape.shape = rect
			shape.position = Vector2(r.position * data.tile_size) + rect.size * 0.5
			body.add_child(shape)
	if _tiles:
		_add_lights()
	queue_redraw()


func _process(delta: float) -> void:
	if _lights.is_empty():
		return
	# Flames breathe a little; each light has its own phase.
	_flicker_time += delta
	for i in _lights.size():
		var base: float = light_specs[i]["energy"]
		if light_specs[i].get("flicker", false):
			_lights[i].energy = base * (0.93 + 0.05 * sin(_flicker_time * 7.0 + i * 1.7) + 0.02 * sin(_flicker_time * 13.0 + i))


## How many pixels the tall top wall rises above row 0 (the camera shows it).
func top_extent() -> int:
	if data == null or _tiles == null:
		return 0
	return (int(_art.get("wall_rows", 1)) - 1) * data.tile_size


## Whether the wall at [param at] is the base of the tall wall: walkable
## ground below it and nothing but wall above it, up to the map's edge.
func is_tall_wall(at: Vector2i) -> bool:
	if data.cell(at) != RoomData.WALL:
		return false
	var below := at + Vector2i.DOWN
	if below.y >= data.height or data.cell(below) == RoomData.WALL:
		return false
	for y in at.y:
		if data.cell(Vector2i(at.x, y)) != RoomData.WALL:
			return false
	return true


## Whether the wall at [param at] is furniture (a block inside the room).
func is_furniture(at: Vector2i) -> bool:
	return data.cell(at) == RoomData.WALL and at.x > 0 and at.y > 0 and at.x < data.width - 1 and at.y < data.height - 1


static func _hash(at: Vector2i, salt: int = 0) -> int:
	return absi(hash([at.x, at.y, salt]))


func _theme_light(key: String) -> Variant:
	var lighting: Dictionary = _art.get("lighting", {})
	return (lighting.get(_theme, {}) as Dictionary).get(key, null)


## Picks the wall decoration, the rug cells and the lights for this room.
func _plan_art() -> void:
	decor.clear()
	rug_cells.clear()
	light_specs.clear()
	if data == null:
		return
	for r: Array in (data.art.get("rugs", []) as Array):
		for y in range(int(r[1]), int(r[1]) + int(r[3])):
			for x in range(int(r[0]), int(r[0]) + int(r[2])):
				if data.is_walkable(Vector2i(x, y)):
					rug_cells[Vector2i(x, y)] = true
	var names: Array = (_art.get("decor", {}) as Dictionary).get(_theme, [])
	var lit_kinds: Dictionary = _theme_light("decor_lights") if _theme_light("decor_lights") != null else {}
	var lit: Array = names.filter(func(n: String) -> bool: return lit_kinds.has(n))
	var unlit: Array = names.filter(func(n: String) -> bool: return not lit_kinds.has(n))
	var seed := data.id.hash()
	var ts := data.tile_size
	var count := 0
	for x in range(2, data.width - 2):
		var at := Vector2i(x, 0)
		while at.y < data.height and not is_tall_wall(at) and data.cell(at) == RoomData.WALL:
			at.y += 1
		if not is_tall_wall(at) or (x + absi(seed)) % 3 != 0:
			continue
		var pool: Array = lit if (count % 2 == 0 and not lit.is_empty()) or unlit.is_empty() else unlit
		if pool.is_empty():
			continue
		var kind: String = pool[_hash(at, seed) % pool.size()]
		decor.append({"tile": at, "kind": kind})
		count += 1
		if lit_kinds.has(kind):
			var l: Array = lit_kinds[kind]
			var top := float((at.y - (int(_art.get("wall_rows", 1)) - 1)) * ts)
			light_specs.append({"pos": Vector2(at.x * ts + ts * 0.5, top + float(l[3])), "color": Color(str(l[0])),
				"energy": float(l[1]), "radius": float(l[2]), "flicker": kind != "window" and kind != "slit"})
	var furn: Variant = _theme_light("furn_light")
	for y in data.height:
		for x in data.width:
			var at := Vector2i(x, y)
			if furn != null and tile_kind(at) == "furn_top_d":
				light_specs.append({"pos": data.tile_center(at), "color": Color(str(furn[0])), "energy": float(furn[1]),
					"radius": float(furn[2]), "flicker": true})
	for e in data.entities:
		var kind := str(e.get("kind", ""))
		if (kind == "unique_fragment" and not is_spent(e)) or kind == "checkpoint":
			var t: Array = e.get("tile", [0, 0])
			light_specs.append({"pos": data.tile_center(Vector2i(int(t[0]), int(t[1]))),
				"color": Color("6fe0e0") if kind == "unique_fragment" else Color("f2c14e"), "energy": 0.6, "radius": 40.0,
				"entity": e})


## A soft round light texture shared by every room light.
static func light_texture() -> GradientTexture2D:
	if _light_texture == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.45, Color(1, 1, 1, 0.45))
		_light_texture = GradientTexture2D.new()
		_light_texture.gradient = g
		_light_texture.fill = GradientTexture2D.FILL_RADIAL
		_light_texture.fill_from = Vector2(0.5, 0.5)
		_light_texture.fill_to = Vector2(1.0, 0.5)
		_light_texture.width = 128
		_light_texture.height = 128
	return _light_texture


func _add_lights() -> void:
	var ambient: Variant = _theme_light("ambient")
	if ambient != null:
		var mod := CanvasModulate.new()
		mod.name = "Ambient"
		mod.color = Color(str(ambient))
		add_child(mod)
	var motes: Variant = _theme_light("motes")
	if motes != null:
		add_child(Fx.motes(Vector2(data.pixel_size()), Color(str(motes[0])), int(motes[1]), float(top_extent())))
	for spec: Dictionary in light_specs:
		var light := PointLight2D.new()
		light.texture = light_texture()
		light.position = spec["pos"]
		light.color = spec["color"]
		light.energy = spec["energy"]
		light.texture_scale = float(spec["radius"]) * 2.0 / 128.0
		add_child(light)
		_lights.append(light)


## Whether entity [param e] is already used up (open chest, read clue, picked fragment).
func is_spent(e: Dictionary) -> bool:
	if state == null:
		return false
	var receipt := str(e.get("persistent_receipt", ""))
	return not receipt.is_empty() and receipt != "<null>" and state.has_receipt(receipt)


## Row of the tile sheet for room [param id]: the longest matching prefix in
## cenario.json "theme_by_room_prefix" wins (v00 workshop, other v… square).
func theme_row(id: String) -> int:
	var by_prefix: Dictionary = _art.get("theme_by_room_prefix", {})
	var best := ""
	for prefix: String in by_prefix:
		if id.begins_with(prefix) and prefix.length() > best.length():
			best = prefix
	var themes: Array = _art.get("themes", [])
	return maxi(themes.find(by_prefix.get(best, "")), 0)


## Which tile picture cell [param at] uses: the tall top wall shows its
## base (its upper rows are drawn above it), blocks inside the room are
## furniture, other walls show their top, gaps show a ledge under ground.
func tile_kind(at: Vector2i) -> String:
	var c := data.cell(at)
	var h := _hash(at)
	if c == RoomData.WALL:
		if is_furniture(at):
			var below := at + Vector2i.DOWN
			if data.cell(below) != RoomData.WALL:
				return "furn_front"
			return "furn_top_d" if h % 5 == 0 else "furn_top_" + "abc"[h % 3]
		return "wall_lower" if is_tall_wall(at) else "wall_top"
	if c == RoomData.GAP:
		var above := at + Vector2i.UP
		return "gap_edge" if above.y >= 0 and data.cell(above) != RoomData.GAP and data.cell(above) != RoomData.WALL else "gap"
	if _hash(at, 11) % 53 == 0:
		return "floor_d"  # the rare one (a drain, a rune)
	var f := h % 40
	return "floor_a" if f < 26 else ("floor_b" if f < 35 else "floor_c")


## Which of the nine rug pieces cell [param at] uses ("" when no rug).
func rug_piece(at: Vector2i) -> String:
	if not rug_cells.has(at):
		return ""
	var v := "t" if not rug_cells.has(at + Vector2i.UP) else ("b" if not rug_cells.has(at + Vector2i.DOWN) else "")
	var hz := "l" if not rug_cells.has(at + Vector2i.LEFT) else ("r" if not rug_cells.has(at + Vector2i.RIGHT) else "")
	var part := v + hz
	return "rug_" + (part if not part.is_empty() else "c")


func _draw_tile(at: Vector2i, kind: String) -> void:
	var ts := data.tile_size
	var col: int = (_art.get("tile_cols", []) as Array).find(kind)
	if col < 0:
		return
	var src := Rect2(Vector2(col * ts, _theme_row * ts), Vector2(ts, ts))
	draw_texture_rect_region(_tiles, Rect2(Vector2(at) * ts, Vector2(ts, ts)), src)


func _draw_object(center: Vector2, kind: String, lift := Vector2.ZERO, item: CanvasItem = null) -> void:
	if item == null:
		item = self
	var col: int = (_art.get("object_cols", []) as Array).find(kind)
	if col < 0:
		return
	var size: Array = _art.get("object_size", [16, 32])
	var pivot: Array = _art.get("object_pivot", [8, 24])
	var w := float(size[0])
	var h := float(size[1])
	var src := Rect2(Vector2(col * w, 0), Vector2(w, h))
	item.draw_texture_rect_region(_objects, Rect2(center + lift - Vector2(float(pivot[0]), float(pivot[1])), Vector2(w, h)), src)


func _draw() -> void:
	if data == null:
		return
	if _tiles:
		_draw_art()
		return
	var ts := data.tile_size
	for y in data.height:
		for x in data.width:
			var c := data.cell(Vector2i(x, y))
			var rect := Rect2(Vector2(x, y) * ts, Vector2(ts, ts))
			match c:
				RoomData.WALL:
					draw_rect(rect, COLOR_WALL)
					draw_rect(Rect2(rect.position, Vector2(ts, 3)), COLOR_WALL_TOP)
				RoomData.GAP:
					draw_rect(rect, COLOR_GAP)
				_:
					draw_rect(rect, COLOR_FLOOR if (x + y) % 2 == 0 else COLOR_FLOOR_ALT)
	for door in data.doors:
		var t: Array = door.get("tile", [0, 0])
		var center := data.tile_center(Vector2i(int(t[0]), int(t[1])))
		var open := bool(door_open.call(door))
		draw_rect(Rect2(center - Vector2(7, 7), Vector2(14, 14)), COLOR_DOOR if open else COLOR_DOOR_LOCKED, open == false, 2.0 if open else -1.0)
	for e in data.entities:
		var kind := str(e.get("kind", ""))
		if not DRAWN_KINDS.has(kind):
			continue
		var t: Array = e.get("tile", [0, 0])
		var c := data.tile_center(Vector2i(int(t[0]), int(t[1])))
		var spent := is_spent(e)
		match kind:
			"chest":
				draw_rect(Rect2(c - Vector2(7, 5), Vector2(14, 10)), COLOR_CHEST_OPEN if spent else COLOR_CHEST)
				if not spent:
					draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), COLOR_CHECKPOINT)
			"mystery_clue":
				if not spent:
					draw_string(ThemeDB.fallback_font, c + Vector2(-3, 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_CLUE)
			"npc":
				draw_rect(Rect2(c - Vector2(5, 14), Vector2(10, 16)), COLOR_NPC)
				draw_circle(c - Vector2(0, 17), 4.0, COLOR_NPC)
			"interact":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -6), c + Vector2(6, 0), c + Vector2(0, 6), c + Vector2(-6, 0)]), COLOR_INTERACT)
			"checkpoint":
				draw_rect(Rect2(c - Vector2(3, 14), Vector2(6, 16)), COLOR_CHECKPOINT)
			"anchor":
				# Traversal ring: a double ring, unlike any decoration.
				draw_arc(c, 6.0, 0, TAU, 16, COLOR_CHECKPOINT, 2.0)
				draw_arc(c, 2.5, 0, TAU, 10, COLOR_CHECKPOINT, 1.0)
			"push_block":
				var lift := Vector2(0, -10) if raised.get(str(e.get("id", "")), false) else Vector2.ZERO
				if lift != Vector2.ZERO:
					draw_rect(Rect2(c - Vector2(7, 2), Vector2(14, 6)), Color(0, 0, 0, 0.4))
				draw_rect(Rect2(c - Vector2(7, 7) + lift, Vector2(14, 14)), Color("7a7f8a"))
				# Pull ring (single, filled) — different from the traversal ring.
				draw_circle(c + lift + Vector2(0, -9), 2.5, COLOR_INTERACT)
			"unique_fragment":
				if not spent:
					draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 0), c + Vector2(0, 5), c + Vector2(-4, 0)]), COLOR_FRAGMENT)
			_:
				draw_circle(c, 3.0, COLOR_OTHER)
		if str(e.get("id", "")) == highlight_id:
			draw_arc(c - Vector2(0, 4), 12.0, 0, TAU, 20, COLOR_HIGHLIGHT, 1.0)


## The painted version of [method _draw]: same entities, same rules.
func _draw_art() -> void:
	for prop in _props:
		prop.queue_redraw()
	for i in mini(_lights.size(), light_specs.size()):
		var e: Variant = light_specs[i].get("entity", null)
		if e is Dictionary and str(e.get("kind", "")) == "unique_fragment":
			_lights[i].visible = not is_spent(e)
	var rows := int(_art.get("wall_rows", 1))
	for y in range(-(rows - 1), 0):    # the map's edge continues above row 0
		for x in data.width:
			_draw_tile(Vector2i(x, y), "wall_top")
	for y in data.height:
		for x in data.width:
			_draw_tile(Vector2i(x, y), tile_kind(Vector2i(x, y)))
	for y in data.height:
		for x in data.width:
			var at := Vector2i(x, y)
			if rows >= 3 and is_tall_wall(at):
				_draw_tile(at + Vector2i.UP, "wall_mid")
				_draw_tile(at + Vector2i.UP * 2, "wall_upper")
			elif rug_cells.has(at):
				_draw_tile(at, rug_piece(at))
			elif data.is_walkable(at) and _hash(at, 7) % 29 == 0 and not _is_occupied(at):
				_draw_tile(at, "decal_" + "abcd"[_hash(at, 3) % 4])
	_draw_decor(rows)
	_draw_shadows()
	for door in data.doors:
		var t: Array = door.get("tile", [0, 0])
		var center := data.tile_center(Vector2i(int(t[0]), int(t[1])))
		_draw_object(center, "door_open" if bool(door_open.call(door)) else "door_closed")
	for e in data.entities:
		var kind := str(e.get("kind", ""))
		if not DRAWN_KINDS.has(kind):
			continue
		var t: Array = e.get("tile", [0, 0])
		var c := data.tile_center(Vector2i(int(t[0]), int(t[1])))
		var spent := is_spent(e)
		match kind:
			"chest":
				_draw_object(c, "chest_open" if spent else "chest")
			"mystery_clue":
				if not spent:
					_draw_object(c, "clue")
			"npc", "checkpoint":
				pass  # drawn by their Prop node
			"interact", "anchor", "push_block":
				var lift := Vector2.ZERO
				if kind == "push_block" and raised.get(str(e.get("id", "")), false):
					lift = Vector2(0, -10)
					draw_rect(Rect2(c - Vector2(7, 2), Vector2(14, 6)), Color(0, 0, 0, 0.55))
				_draw_object(c, kind, lift)
			"unique_fragment":
				if not spent:
					_draw_object(c, "fragment")
		if str(e.get("id", "")) == highlight_id:
			draw_arc(c - Vector2(0, 4), 12.0, 0, TAU, 20, COLOR_HIGHLIGHT, 1.0)


func _is_occupied(at: Vector2i) -> bool:
	for list: Array in [data.doors, data.entities]:
		for e: Dictionary in list:
			var t: Array = e.get("tile", [-1, -1])
			if int(t[0]) == at.x and int(t[1]) == at.y:
				return true
	return false


func _draw_decor(rows: int) -> void:
	if _decor_tex == null:
		return
	var names: Array = (_art.get("decor", {}) as Dictionary).get(_theme, [])
	var size: Array = _art.get("decor_size", [16, 32])
	var w := float(size[0])
	var h := float(size[1])
	for d: Dictionary in decor:
		var col := names.find(d["kind"])
		var at: Vector2i = d["tile"]
		var src := Rect2(Vector2(col * w, _theme_row * h), Vector2(w, h))
		draw_texture_rect_region(_decor_tex, Rect2(Vector2(at.x, at.y - (rows - 1)) * data.tile_size, Vector2(w, h)), src)


## Soft shade on the ground under walls and furniture, and to their right.
func _draw_shadows() -> void:
	var ts := float(data.tile_size)
	for y in data.height:
		for x in data.width:
			var at := Vector2i(x, y)
			if data.cell(at) == RoomData.WALL:
				continue
			var o := Vector2(at) * ts
			if y > 0 and data.cell(at + Vector2i.UP) == RoomData.WALL:
				for i in 6:
					draw_rect(Rect2(o + Vector2(0, i), Vector2(ts, 1)), Color(0.06, 0.03, 0.05, 0.42 * (1.0 - i / 6.0)))
			if x > 0 and data.cell(at + Vector2i.LEFT) == RoomData.WALL:
				for i in 4:
					draw_rect(Rect2(o + Vector2(i, 0), Vector2(1, ts)), Color(0.06, 0.03, 0.05, 0.3 * (1.0 - i / 4.0)))


## Draws a tall entity on its own node (see [constant PROP_KINDS]).
func draw_prop(prop: Node2D, e: Dictionary) -> void:
	var kind := str(e.get("kind", ""))
	if kind == "checkpoint":
		var active := state != null and str(state.checkpoint.get("entity_id", "")) == str(e.get("id", ""))
		_draw_object(Vector2.ZERO, "marco_active" if active else "marco", Vector2.ZERO, prop)
	else:
		_draw_object(Vector2.ZERO, kind, Vector2.ZERO, prop)


class Prop extends Node2D:
	var room: Room
	var entity: Dictionary = {}

	func _draw() -> void:
		if room and is_instance_valid(room):
			room.draw_prop(self, entity)
