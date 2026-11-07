class_name Room
extends Node2D
## Builds a playable placeholder room from a [RoomData]: draws flat tiles,
## adds wall and gap collision, and draws doors and entities, reflecting the
## [GameState] (open chests, collected fragments, read clues).
## Placeholder art only — real tiles come later (design/kit/arte-e-audio-pendentes.md).

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
const ART_META := "res://assets/art/cenario/cenario.json"
## Sheets drawn by tools/art/gerar_cenario.py; null keeps the flat colours.
var _tiles: Texture2D
var _objects: Texture2D
var _art: Dictionary = {}
var _theme_row := 0


func _ready() -> void:
	if ResourceLoader.exists(TILES_PATH) and ResourceLoader.exists(OBJECTS_PATH):
		var f := FileAccess.open(ART_META, FileAccess.READ)
		var json := JSON.new()
		if f and json.parse(f.get_as_text()) == OK and json.data is Dictionary:
			_art = json.data
			_tiles = load(TILES_PATH)
			_objects = load(OBJECTS_PATH)


## Replaces the current content with [param room_data].
func build(room_data: RoomData) -> void:
	data = room_data
	for child in get_children():
		child.queue_free()
	name = "Room_%s" % data.id
	_theme_row = theme_row(data.id)
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
	queue_redraw()


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


## Which tile picture cell [param at] uses: walls show their front face
## above walkable ground, gaps show a ledge under walkable ground.
func tile_kind(at: Vector2i) -> String:
	var c := data.cell(at)
	if c == RoomData.WALL:
		var below := at + Vector2i.DOWN
		return "wall_front" if below.y < data.height and data.cell(below) != RoomData.WALL else "wall_top"
	if c == RoomData.GAP:
		var above := at + Vector2i.UP
		return "gap_edge" if above.y >= 0 and data.cell(above) != RoomData.GAP and data.cell(above) != RoomData.WALL else "gap"
	var h := absi((at.x * 73856093) ^ (at.y * 19349663)) % 25
	return "floor_a" if h < 15 else ("floor_b" if h < 24 else "floor_c")


func _draw_tile(at: Vector2i, kind: String) -> void:
	var ts := data.tile_size
	var col: int = (_art.get("tile_cols", []) as Array).find(kind)
	var src := Rect2(Vector2(col * ts, _theme_row * ts), Vector2(ts, ts))
	draw_texture_rect_region(_tiles, Rect2(Vector2(at) * ts, Vector2(ts, ts)), src)


func _draw_object(center: Vector2, kind: String, lift := Vector2.ZERO) -> void:
	var col: int = (_art.get("object_cols", []) as Array).find(kind)
	if col < 0:
		return
	var size: Array = _art.get("object_size", [16, 32])
	var pivot: Array = _art.get("object_pivot", [8, 24])
	var w := float(size[0])
	var h := float(size[1])
	var src := Rect2(Vector2(col * w, 0), Vector2(w, h))
	draw_texture_rect_region(_objects, Rect2(center + lift - Vector2(float(pivot[0]), float(pivot[1])), Vector2(w, h)), src)


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
	for y in data.height:
		for x in data.width:
			_draw_tile(Vector2i(x, y), tile_kind(Vector2i(x, y)))
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
			"npc", "interact", "anchor", "push_block":
				var lift := Vector2.ZERO
				if kind == "push_block" and raised.get(str(e.get("id", "")), false):
					lift = Vector2(0, -10)
					draw_rect(Rect2(c - Vector2(7, 2), Vector2(14, 6)), Color(0, 0, 0, 0.4))
				_draw_object(c, kind, lift)
			"checkpoint":
				var active := state != null and str(state.checkpoint.get("entity_id", "")) == str(e.get("id", ""))
				_draw_object(c, "marco_active" if active else "marco")
			"unique_fragment":
				if not spent:
					_draw_object(c, "fragment")
		if str(e.get("id", "")) == highlight_id:
			draw_arc(c - Vector2(0, 4), 12.0, 0, TAU, 20, COLOR_HIGHLIGHT, 1.0)
