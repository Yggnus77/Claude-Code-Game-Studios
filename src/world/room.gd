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
const DRAWN_KINDS := ["chest", "mystery_clue", "npc", "interact", "checkpoint", "unique_fragment", "anchor", "binding", "bell", "push_block"]

var data: RoomData
## Progress used to draw opened/collected things; may be null in tests.
var state: GameState
## Callable(door: Dictionary) -> bool telling whether a door is open.
var door_open: Callable = func(_door: Dictionary) -> bool: return true
## Entity id to outline (the one the player can interact with).
var highlight_id := ""


## Replaces the current content with [param room_data].
func build(room_data: RoomData) -> void:
	data = room_data
	for child in get_children():
		child.queue_free()
	name = "Room_%s" % data.id
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


func _draw() -> void:
	if data == null:
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
			"unique_fragment":
				if not spent:
					draw_colored_polygon(PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 0), c + Vector2(0, 5), c + Vector2(-4, 0)]), COLOR_FRAGMENT)
			_:
				draw_circle(c, 3.0, COLOR_OTHER)
		if str(e.get("id", "")) == highlight_id:
			draw_arc(c - Vector2(0, 4), 12.0, 0, TAU, 20, COLOR_HIGHLIGHT, 1.0)
