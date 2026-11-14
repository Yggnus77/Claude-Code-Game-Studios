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
const DRAWN_KINDS := ["chest", "mystery_clue", "npc", "interact", "checkpoint", "unique_fragment", "anchor", "push_block", "plate", "refill", "examine"]
## Wall plates hang this far above their tile (they sit on the tall wall).
const PLATE_LIFT := Vector2(0, -6)

var data: RoomData
## Progress used to draw opened/collected things; may be null in tests.
var state: GameState
## Callable(door: Dictionary) -> bool telling whether a door is open.
var door_open: Callable = func(_door: Dictionary) -> bool: return true
## Entity id to outline (the one the player can interact with).
var highlight_id := ""
## Raised state of push blocks pulled by the hook (by entity id).
var raised: Dictionary = {}
## Bush and pot rules; null builds no breakables (tests, old callers).
var breakable_rules: Breakables
## Breakables built for this visit (emitted so the game can hand drops).
signal breakable_broken(breakable: Breakable)
## Ambient colour of a room marked dark ("art": {"dark": true}).
var dark_ambient := Color("2a2638")
## Torches of this visit (the Lamparina lights them).
var torches: Array[Torch] = []
## Reach of a lit torch's light.
var torch_light_radius := 104.0

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
## Most lights a room places (Godot lights a canvas item with at most 16).
const MAX_ROOM_LIGHTS := 12
## How far to each side of a door's arch walking into the wall still enters.
const DOOR_SIDE_SLACK := 5.0
## Per-cell picture plan made by [method _plan_cells]: tile kind, the piece
## drawn over it ("" none) and the cells above the tall wall.
var _cell_kinds: Dictionary = {}
var _cell_overlays: Dictionary = {}
var _art: Dictionary = {}
var _theme_row := 0
## Painted rooms (design/gdd/salas-pintadas.md): the map's
## "art": {"background": "<name>"} names a picture in this folder that is the
## whole room; walls, doors and objects in the map are placed to match it.
const BACKGROUND_DIR := "res://assets/art/salas"
## The room's painted picture, or null for a room drawn from tiles.
var background: Texture2D
## Objects redrawn in the pictures' style for painted rooms
## (BACKGROUND_DIR/obj_<kind>.png), by kind.
var painted_objects: Dictionary = {}
## Objects a painted room draws from BACKGROUND_DIR/obj_<kind>.png instead
## of the block sheet (tools/art/gerar_salas.py and objetos_pintados.py).
const PAINTED_KINDS := ["bush", "bush_cut", "pot", "barreira", "chest", "chest_open", "clue", "refill",
	"plate", "plate_hit", "marco", "marco_active"]
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
		remove_child(child)  # out of the tree now: the old lights must not linger a frame
		child.queue_free()
	name = "Room_%s" % data.id
	_theme_row = theme_row(data.id)
	var themes: Array = _art.get("themes", [])
	_theme = str(themes[_theme_row]) if _theme_row < themes.size() else ""
	_props.clear()
	_lights.clear()
	torches.clear()
	background = null
	var bg := str(data.art.get("background", ""))
	if not bg.is_empty() and ResourceLoader.exists("%s/%s.png" % [BACKGROUND_DIR, bg]):
		background = load("%s/%s.png" % [BACKGROUND_DIR, bg])
	painted_objects.clear()
	if background != null:
		for kind: String in PAINTED_KINDS:
			var path := "%s/obj_%s.png" % [BACKGROUND_DIR, kind]
			if ResourceLoader.exists(path):
				painted_objects[kind] = load(path)
	_plan_art()
	if _tiles and background == null:
		_plan_cells()
	if _tiles:
		for e in data.entities:
			if PROP_KINDS.has(str(e.get("kind", ""))) and not is_painted_entity(e):
				var t: Array = e.get("tile", [0, 0])
				var prop := Prop.new()
				prop.room = self
				prop.entity = e
				prop.position = data.tile_center(Vector2i(int(t[0]), int(t[1])))
				add_child(prop)
				_props.append(prop)
	_build_breakables()
	_build_torches()
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
	if _tiles or background:
		var ground := Ground.new()
		ground.name = "Ground"
		ground.room = self
		ground.z_index = -1  # under everything that sorts by height
		add_child(ground)
	if _tiles and (background == null or is_dark()):
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
	if data == null or _tiles == null or background != null:
		return 0
	return (int(_art.get("wall_rows", 1)) - 1) * data.tile_size


## Whether this room is one painted picture ([member background]).
func is_painted() -> bool:
	return background != null


## Whether entity [param e] is already part of the room's picture (the map
## marks it "painted": true), so the room draws nothing for it.
func is_painted_entity(e: Dictionary) -> bool:
	return background != null and bool(e.get("painted", false))


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
	if data.cell(at) != RoomData.WALL or at.x <= 0 or at.y <= 0 or at.x >= data.width - 1 or at.y >= data.height - 1:
		return false
	for y in at.y:  # walls joined to the top edge belong to the tall wall
		if data.cell(Vector2i(at.x, y)) != RoomData.WALL:
			return true
	return false


static func _hash(at: Vector2i, salt: int = 0) -> int:
	var h := (at.x * 374761393 + at.y * 668265263 + salt * 2246822519) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return h ^ (h >> 16)


func _theme_light(key: String) -> Variant:
	var lighting: Dictionary = _art.get("lighting", {})
	return (lighting.get(_theme, {}) as Dictionary).get(key, null)


## Picks the wall decoration, the rug cells and the lights for this room.
func _plan_art() -> void:
	decor.clear()
	rug_cells.clear()
	light_specs.clear()
	if data == null or (background != null and not is_dark()):
		return  # a painted room has its lamps and light in the picture
	for r: Array in (data.art.get("rugs", []) as Array):
		for y in range(int(r[1]), int(r[1]) + int(r[3])):
			for x in range(int(r[0]), int(r[0]) + int(r[2])):
				if data.is_walkable(Vector2i(x, y)):
					rug_cells[Vector2i(x, y)] = true
	var names: Array = (_art.get("decor", {}) as Dictionary).get(_theme, [])
	var lit_kinds: Dictionary = _theme_light("decor_lights") if _theme_light("decor_lights") != null else {}
	if is_dark():
		lit_kinds = {}  # a dark room: no lamps burn on its walls
		names = names.filter(func(n: String) -> bool: return not (_theme_light("decor_lights") as Dictionary).has(n)) if _theme_light("decor_lights") != null else names
	var lit: Array = names.filter(func(n: String) -> bool: return lit_kinds.has(n))
	var unlit: Array = names.filter(func(n: String) -> bool: return not lit_kinds.has(n))
	var seed := data.id.hash()
	var ts := data.tile_size
	var door_cols := {}
	for door: Dictionary in data.doors:
		var f := door_frame_tile(door)
		if is_tall_wall(f):
			for dx in [-1, 0, 1]:
				door_cols[f.x + dx] = true
	var count := 0
	for x in range(2, data.width - 2):
		var at := Vector2i(x, 0)
		while at.y < data.height and not is_tall_wall(at) and data.cell(at) == RoomData.WALL:
			at.y += 1
		if not is_tall_wall(at) or (x + absi(seed)) % 3 != 0 or door_cols.has(x):
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
				"energy": float(l[1]), "radius": float(l[2]), "flicker": l.size() > 4 and bool(l[4])})
	var furn: Variant = null if is_dark() else _theme_light("furn_light")
	for y in data.height:
		for x in data.width:
			var at := Vector2i(x, y)
			if furn != null and tile_kind(at) == "furn_top_d":
				light_specs.append({"pos": data.tile_center(at), "color": Color(str(furn[0])), "energy": float(furn[1]),
					"radius": float(furn[2]), "flicker": true})
	var pickups: Dictionary = (_art.get("pickup_lights", {}) as Dictionary)
	for e in data.entities:
		var kind := str(e.get("kind", ""))
		if pickups.has(kind) and not is_spent(e):
			var l: Array = pickups[kind]
			var t: Array = e.get("tile", [0, 0])
			light_specs.append({"pos": data.tile_center(Vector2i(int(t[0]), int(t[1]))), "color": Color(str(l[0])),
				"energy": float(l[1]), "radius": float(l[2]), "entity": e})
	# One canvas item takes at most 16 lights; keep the strongest and leave
	# room for Yggnus's glow and the flashes of hit sparks.
	if light_specs.size() > MAX_ROOM_LIGHTS:
		light_specs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a["energy"]) * float(a["radius"]) > float(b["energy"]) * float(b["radius"]))
		light_specs.resize(MAX_ROOM_LIGHTS)


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


## Whether the map marks this room as dark.
func is_dark() -> bool:
	return data != null and bool(data.art.get("dark", false))


func _add_lights() -> void:
	var ambient: Variant = dark_ambient.to_html() if is_dark() else _theme_light("ambient")
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


## Whether the plate [param e] was already hit (its flag is set).
func plate_hit(e: Dictionary) -> bool:
	var flag := str(e.get("sets_flag", ""))
	return state != null and not flag.is_empty() and state.has_flag(flag)


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


func _draw_tile(at: Vector2i, kind: String, item: CanvasItem = null) -> void:
	if item == null:
		item = self
	var ts := data.tile_size
	var col: int = (_art.get("tile_cols", []) as Array).find(kind)
	if col < 0:
		return
	var src := Rect2(Vector2(col * ts, _theme_row * ts), Vector2(ts, ts))
	item.draw_texture_rect_region(_tiles, Rect2(Vector2(at) * ts, Vector2(ts, ts)), src)


func _draw_object(center: Vector2, kind: String, lift := Vector2.ZERO, item: CanvasItem = null) -> void:
	if item == null:
		item = self
	if painted_objects.has(kind):
		# The painted-style picture, standing on the tile like the block one.
		var tex: Texture2D = painted_objects[kind]
		item.draw_texture(tex, (center + lift - Vector2(tex.get_width() * 0.5, tex.get_height() - 6.0)).floor())
		return
	var col: int = (_art.get("object_cols", []) as Array).find(kind)
	if col < 0:
		return
	var size: Array = _art.get("object_size", [16, 32])
	var pivot: Array = _art.get("object_pivot", [8, 24])
	var w := float(size[0])
	var h := float(size[1])
	var src := Rect2(Vector2(col * w, 0), Vector2(w, h))
	item.draw_texture_rect_region(_objects, Rect2(center + lift - Vector2(float(pivot[0]), float(pivot[1])), Vector2(w, h)), src)


## Bushes and pots listed in the map ("breakables": {"bush": [[x, y]…]}),
## whole again on every visit.
func _build_breakables() -> void:
	if breakable_rules == null:
		return
	for kind: String in data.breakables:
		if not breakable_rules.has_kind(kind):
			continue
		for at: Vector2i in data.breakables[kind]:
			var b := Breakable.new()
			b.room = self
			b.rules = breakable_rules
			b.kind = kind
			b.tile = at
			b.name = "%s_%d_%d" % [kind, at.x, at.y]
			b.position = data.tile_center(at)
			b.broken.connect(breakable_broken.emit)
			add_child(b)


## Torches listed as entities (kind "torch"), lit when their puzzle's flag
## is already set.
func _build_torches() -> void:
	for e in data.entities:
		if str(e.get("kind", "")) != "torch":
			continue
		var t: Array = e.get("tile", [0, 0])
		var torch := Torch.new()
		torch.room = self
		torch.light_radius = torch_light_radius
		torch.entity = e
		torch.name = "Torch_%s" % str(e.get("id", "")).replace(".", "_")
		torch.position = data.tile_center(Vector2i(int(t[0]), int(t[1])))
		if is_painted_entity(e):
			# A lamp of the picture: only the flame and its light are drawn,
			# at "flame_at" (pixels from the tile's centre).
			torch.painted = true
			var f: Array = e.get("flame_at", [0, -12])
			torch.flame_offset = Vector2(float(f[0]), float(f[1]))
		var flag := torch.puzzle_flag()
		torch.lit = state != null and not flag.is_empty() and state.has_flag(flag)
		add_child(torch)
		torches.append(torch)


## Whether [param door] is a cracked wall (a bomb opens it).
static func is_cracked(door: Dictionary) -> bool:
	return bool(door.get("cracked", false))


## Draws object column [param kind] centred on [param item] (bushes, pots).
func draw_object_on(item: CanvasItem, kind: String) -> void:
	if painted_objects.has(kind):
		var tex: Texture2D = painted_objects[kind]
		item.draw_texture(tex, -Vector2(tex.get_width() * 0.5, tex.get_height() - 6.0).floor())
	elif _objects:
		_draw_object(Vector2.ZERO, kind, Vector2.ZERO, item)
	else:
		match kind:
			"torch_off", "torch_on":
				item.draw_rect(Rect2(-1, -10, 2, 12), Color("4a3a30"))
				item.draw_rect(Rect2(-3, -13, 6, 3), Color("6a5a48"))
				if kind == "torch_on":
					item.draw_circle(Vector2(0, -15), 3.0, Color("ffa850"))
			_:
				item.draw_circle(Vector2.ZERO, 6.0, COLOR_OTHER)


func _draw() -> void:
	if data == null:
		return
	if _tiles:
		_draw_art()
		return
	if background != null:
		return  # without the object sheet the picture is enough
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
		if not open and is_cracked(door):
			draw_line(center + Vector2(-5, -6), center + Vector2(4, 6), COLOR_GAP, 1.0)
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
			"plate":
				draw_circle(c + PLATE_LIFT, 5.0, COLOR_CHECKPOINT if plate_hit(e) else COLOR_DOOR_LOCKED)
				draw_circle(c + PLATE_LIFT, 2.0, COLOR_HIGHLIGHT)
			"refill":
				draw_rect(Rect2(c - Vector2(4, 7), Vector2(8, 11)), COLOR_INTERACT)
			"examine":
				if e.get("barrier") is Dictionary:
					var b: Array = e["barrier"].get("tile", t)
					draw_rect(Rect2(data.tile_center(Vector2i(int(b[0]), int(b[1]))) - Vector2(7, 7), Vector2(14, 14)), COLOR_DOOR_LOCKED)
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
		if e is Dictionary:
			_lights[i].visible = not is_spent(e)
	for door in data.doors:
		var open := bool(door_open.call(door))
		if background != null:
			if is_cracked(door):
				# The picture shows the crack; once blown, a hole opens in it.
				if open:
					_draw_hole(door)
			elif not open:
				_draw_barrier(door)
			continue  # the picture already shows the way through
		var look := "door_open" if open else ("door_cracked" if is_cracked(door) else "door_closed")
		_draw_object(data.tile_center(door_frame_tile(door)), look)
	for e in data.entities:
		var kind := str(e.get("kind", ""))
		if not DRAWN_KINDS.has(kind):
			continue
		var t: Array = e.get("tile", [0, 0])
		var c := data.tile_center(Vector2i(int(t[0]), int(t[1])))
		var spent := is_spent(e)
		if is_painted_entity(e):
			kind = ""  # in the picture; only the highlight ring is drawn
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
			"plate":
				_draw_object(c, "plate_hit" if plate_hit(e) else "plate", PLATE_LIFT)
			"refill":
				_draw_object(c, "refill")
			"examine":
				# A way the picture shows but the story keeps shut: the same
				# barrier a closed door gets (map entity "barrier", door-shaped).
				if e.get("barrier") is Dictionary:
					_draw_barrier(e["barrier"])
		if str(e.get("id", "")) == highlight_id:
			draw_arc(c - Vector2(0, 4), 12.0, 0, TAU, 20, COLOR_HIGHLIGHT, 1.0)


## A closed way out of a painted room: a barrier across the door's span,
## standing on the door's own row.
func _draw_barrier(door: Dictionary) -> void:
	var t: Array = door.get("tile", [0, 0])
	var span := maxi(1, int(door.get("span", 1)))
	var ts := float(data.tile_size)
	var across := Vector2(1, 0) if str(door.get("side", "")) in ["north", "south"] else Vector2(0, 1)
	var c := data.tile_center(Vector2i(int(t[0]), int(t[1]))) + across * ts * (span - 1) * 0.5
	var tex: Texture2D = painted_objects.get("barreira")
	if tex == null:
		_draw_object(c, "door_closed")
	elif across.x != 0.0:
		# The picture is four tiles wide; a narrower way shows its middle.
		var w := minf(float(tex.get_width()), ts * span)
		var src := Rect2(Vector2((tex.get_width() - w) * 0.5, 0).floor(), Vector2(w, tex.get_height()))
		draw_texture_rect_region(tex, Rect2((c - Vector2(w * 0.5, tex.get_height() - 6.0)).floor(), src.size), src)
	else:  # an east or west way out: the barrier seen from its end
		draw_texture_rect_region(tex, Rect2(c - Vector2(5, tex.get_height() - 6.0), Vector2(10, tex.get_height())),
			Rect2(Vector2(3, 0), Vector2(10, tex.get_height())))


## A cracked wall of a painted room after the blast: a dark broken arch
## in the wall above the door's span, with fallen stones at its foot.
func _draw_hole(door: Dictionary) -> void:
	var t: Array = door.get("tile", [0, 0])
	var span := maxi(1, int(door.get("span", 1)))
	var ts := float(data.tile_size)
	var foot := data.tile_center(Vector2i(int(t[0]), int(t[1]))) + Vector2(ts * (span - 1) * 0.5, -ts * 0.5)
	var half := ts * span * 0.5 - 2.0
	var pts := PackedVector2Array()
	for i in 13:  # a ragged arch: the rim jumps in and out by a pixel or two
		var a := PI + PI * i / 12.0
		var jag := 1.5 if i % 2 == 0 else -1.0
		pts.append(foot + Vector2(cos(a) * (half + jag), sin(a) * (half * 2.4 + jag)))
	draw_colored_polygon(pts, Color("140c12"))
	draw_polyline(pts, Color("3a2a2e"), 1.0)
	for k: Vector3 in [Vector3(-half + 2, 1, 3), Vector3(-3, 2, 2.5), Vector3(half - 4, 1, 3.5), Vector3(4, 3, 2)]:
		draw_circle(foot + Vector2(k.x, k.y), k.z, Color("6a5a5e"))
		draw_circle(foot + Vector2(k.x - 0.5, k.y - 0.8), k.z * 0.5, Color("8a7a7a"))


## Works out once per build which picture each cell shows (the ground layer
## draws from this, so a redraw of the room costs only doors and entities).
func _plan_cells() -> void:
	_cell_kinds.clear()
	_cell_overlays.clear()
	var rows := int(_art.get("wall_rows", 1))
	for y in data.height:
		for x in data.width:
			var at := Vector2i(x, y)
			var kind := tile_kind(at)
			_cell_kinds[at] = kind
			if rows >= 3 and kind == "wall_lower":
				_cell_overlays[at + Vector2i.UP] = "wall_mid"
				_cell_overlays[at + Vector2i.UP * 2] = "wall_upper"
			elif rug_cells.has(at):
				_cell_overlays[at] = rug_piece(at)
			elif data.is_walkable(at) and _hash(at, 7) % 29 == 0 and not _is_occupied(at):
				_cell_overlays[at] = "decal_" + "abcd"[_hash(at, 3) % 4]


## The still picture of the room (tiles, wall, rugs, decor, shadows), drawn
## once per build by the [Ground] child.
func draw_ground(item: CanvasItem) -> void:
	if background != null:
		item.draw_texture(background, Vector2.ZERO)
		return
	var rows := int(_art.get("wall_rows", 1))
	for y in range(-(rows - 1), 0):    # the map's edge continues above row 0
		for x in data.width:
			_draw_tile(Vector2i(x, y), "wall_top", item)
	for at: Vector2i in _cell_kinds:
		_draw_tile(at, _cell_kinds[at], item)
	for at: Vector2i in _cell_overlays:
		_draw_tile(at, _cell_overlays[at], item)
	_draw_decor(rows, item)
	_draw_shadows(item)
	_draw_gap_lips(item)


## Where a door's arch is drawn: set into the nearest wall within two tiles
## of its tile (the doorway in the wall), else on the tile itself. Only the
## picture moves; the door's trigger stays on its tile.
func door_frame_tile(door: Dictionary) -> Vector2i:
	var t: Array = door.get("tile", [0, 0])
	var at := Vector2i(int(t[0]), int(t[1]))
	if _tiles == null:
		return at
	for dir: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]:
		for k in [1, 2]:
			var w: Vector2i = at + dir * k
			if w.x < 0 or w.y < 0 or w.x >= data.width or w.y >= data.height:
				break
			if data.cell(w) == RoomData.WALL:
				if not is_furniture(w):
					return w
				break
	return at


## Where stepping in uses the door: its own tile plus the ground between it
## and the arch drawn in the wall, so walking up to the arch goes through.
func door_zone(door: Dictionary) -> Rect2:
	var t: Array = door.get("tile", [0, 0])
	var at := Vector2i(int(t[0]), int(t[1]))
	var ts := float(data.tile_size)
	var zone := Rect2(Vector2(at) * ts, Vector2(ts, ts))
	# A wide way out ("span": n) covers n tiles across the direction of travel.
	var span := maxi(1, int(door.get("span", 1)))
	if span > 1:
		var across := Vector2(1, 0) if str(door.get("side", "")) in ["north", "south"] else Vector2(0, 1)
		zone = zone.merge(Rect2((Vector2(at) + across * (span - 1)) * ts, Vector2(ts, ts)))
	var frame := door_frame_tile(door)
	if frame != at:
		# The walkable cells in between; the feet stop at the wall's face,
		# which is still inside the last of them.
		var step := (frame - at).sign()
		var cell := at + step
		while cell != frame and data.is_walkable(cell):
			zone = zone.merge(Rect2(Vector2(cell) * ts, Vector2(ts, ts)))
			cell += step
		# A little wider than the arch, so arriving slightly to one side
		# still goes through instead of rubbing against the wall.
		var side := DOOR_SIDE_SLACK
		zone = zone.grow_individual(side if step.y != 0 else 0.0, side if step.x != 0 else 0.0,
			side if step.y != 0 else 0.0, side if step.x != 0 else 0.0)
	return zone


func _is_occupied(at: Vector2i) -> bool:
	for list: Array in [data.doors, data.entities]:
		for e: Dictionary in list:
			var t: Array = e.get("tile", [-1, -1])
			if int(t[0]) == at.x and int(t[1]) == at.y:
				return true
	return false


func _draw_decor(rows: int, item: CanvasItem) -> void:
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
		item.draw_texture_rect_region(_decor_tex, Rect2(Vector2(at.x, at.y - (rows - 1)) * data.tile_size, Vector2(w, h)), src)


## A thin ledge where a gap meets ground at its sides, so a chasm has an edge.
func _draw_gap_lips(item: CanvasItem) -> void:
	var ts := float(data.tile_size)
	for at: Vector2i in _cell_kinds:
		if data.cell(at) != RoomData.GAP:
			continue
		var o := Vector2(at) * ts
		for side: int in [-1, 1]:
			var n := at + Vector2i(side, 0)
			if data.is_walkable(n):
				var x := o.x if side < 0 else o.x + ts - 2.0
				item.draw_rect(Rect2(Vector2(x, o.y), Vector2(2, ts)), Color(0.34, 0.3, 0.38))
				item.draw_rect(Rect2(Vector2(x + (2.0 if side < 0 else -1.0), o.y), Vector2(1, ts)), Color(0, 0, 0, 0.6))


## Soft shade on the ground under walls and furniture, and to their right.
func _draw_shadows(item: CanvasItem) -> void:
	var ts := float(data.tile_size)
	for y in data.height:
		for x in data.width:
			var at := Vector2i(x, y)
			if data.cell(at) == RoomData.WALL:
				continue
			var o := Vector2(at) * ts
			if y > 0 and data.cell(at + Vector2i.UP) == RoomData.WALL:
				for i in 6:
					item.draw_rect(Rect2(o + Vector2(0, i), Vector2(ts, 1)), Color(0.06, 0.03, 0.05, 0.42 * (1.0 - i / 6.0)))
			if x > 0 and data.cell(at + Vector2i.LEFT) == RoomData.WALL:
				for i in 4:
					item.draw_rect(Rect2(o + Vector2(i, 0), Vector2(1, ts)), Color(0.06, 0.03, 0.05, 0.3 * (1.0 - i / 4.0)))


## Draws a tall entity on its own node (see [constant PROP_KINDS]).
func draw_prop(prop: Node2D, e: Dictionary) -> void:
	var kind := str(e.get("kind", ""))
	if kind == "checkpoint":
		var active := state != null and str(state.checkpoint.get("entity_id", "")) == str(e.get("id", ""))
		_draw_object(Vector2.ZERO, "marco_active" if active else "marco", Vector2.ZERO, prop)
	else:
		_draw_object(Vector2.ZERO, kind, Vector2.ZERO, prop)


class Ground extends Node2D:
	var room: Room

	func _draw() -> void:
		if room and is_instance_valid(room) and room.data:
			room.draw_ground(self)


class Prop extends Node2D:
	var room: Room
	var entity: Dictionary = {}

	func _draw() -> void:
		if room and is_instance_valid(room):
			room.draw_prop(self, entity)
