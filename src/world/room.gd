class_name Room
extends Node2D
## Builds a playable placeholder room from a [RoomData]: draws flat tiles,
## adds wall and gap collision, and marks doors and entities.
## Placeholder art only — real tiles come later (design/kit/arte-e-audio-pendentes.md).

## Physics layer used by walls and gaps (layer 1).
const WORLD_LAYER := 1

const COLOR_FLOOR := Color("2b2f3a")
const COLOR_FLOOR_ALT := Color("2f3440")
const COLOR_WALL := Color("6b5a45")
const COLOR_WALL_TOP := Color("8a7458")
const COLOR_GAP := Color("0d0f14")
const COLOR_DOOR := Color("d9a441")
const COLOR_ENTITY := Color("5fa8a0")

var data: RoomData


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
		draw_rect(Rect2(center - Vector2(6, 6), Vector2(12, 12)), COLOR_DOOR, false, 2.0)
	for entity in data.entities:
		var t: Array = entity.get("tile", [0, 0])
		var center := data.tile_center(Vector2i(int(t[0]), int(t[1])))
		draw_circle(center, 4.0, COLOR_ENTITY)
