class_name RoomData
extends RefCounted
## One prototype room parsed from assets/data/maps/<id>.json.
##
## Grid legend (design/kit/plano-implementacao.md): '#' wall, '.' floor,
## '~' gap that only the grappling hook may cross. Coordinates are
## [column, row] from the top-left; a tile's pixel centre is tile*size + size/2.

const WALL := "#"
const FLOOR := "."
const GAP := "~"

var id: String = ""
var display_name: String = ""
var width: int = 0
var height: int = 0
var tile_size: int = 16
var grid: PackedStringArray = PackedStringArray()
var doors: Array = []
var entities: Array = []
var entry_default: Vector2i = Vector2i.ZERO


## Builds a RoomData from the parsed JSON dictionary of one room.
static func from_dict(d: Dictionary) -> RoomData:
	var room := RoomData.new()
	room.id = str(d.get("id", ""))
	room.display_name = str(d.get("name", room.id))
	room.width = int(d.get("width", 0))
	room.height = int(d.get("height", 0))
	room.tile_size = int(d.get("tile_size", 16))
	room.grid = PackedStringArray(d.get("grid", []))
	room.doors = d.get("doors", [])
	room.entities = d.get("entities", [])
	var entry: Array = d.get("entry_default", [1, 1])
	room.entry_default = Vector2i(int(entry[0]), int(entry[1]))
	return room


## Loads res://assets/data/maps/<room_id>.json. Returns null on failure.
static func load_room(room_id: String, dir: String = "res://assets/data/maps") -> RoomData:
	var text := FileAccess.get_file_as_string("%s/%s.json" % [dir, room_id])
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("RoomData: cannot load room %s" % room_id)
		return null
	return from_dict(parsed)


## The grid character at [param cell], or WALL when outside the grid.
func cell(cell_pos: Vector2i) -> String:
	if cell_pos.y < 0 or cell_pos.y >= grid.size():
		return WALL
	var row := grid[cell_pos.y]
	if cell_pos.x < 0 or cell_pos.x >= row.length():
		return WALL
	return row[cell_pos.x]


## True when the player may stand on [param cell_pos] without a tool.
func is_walkable(cell_pos: Vector2i) -> bool:
	return cell(cell_pos) == FLOOR


## Pixel centre of a tile.
func tile_center(cell_pos: Vector2i) -> Vector2:
	return Vector2(cell_pos) * tile_size + Vector2.ONE * tile_size * 0.5


## Room size in pixels.
func pixel_size() -> Vector2i:
	return Vector2i(width, height) * tile_size


## Merges every cell equal to [param ch] into as few tile rectangles as
## possible (runs along rows, then stacked rows with the same span).
## Used to build one collision shape per rectangle instead of one per tile.
func merged_rects(ch: String) -> Array[Rect2i]:
	var open: Dictionary = {}
	var result: Array[Rect2i] = []
	for y in grid.size():
		var row := grid[y]
		var x := 0
		while x < row.length():
			if row[x] != ch:
				x += 1
				continue
			var start := x
			while x < row.length() and row[x] == ch:
				x += 1
			var key := Vector2i(start, x - start)
			if open.has(key) and open[key].end.y == y:
				var r: Rect2i = open[key]
				r.size.y += 1
				open[key] = r
			else:
				if open.has(key):
					result.append(open[key])
				open[key] = Rect2i(start, y, x - start, 1)
	for r in open.values():
		result.append(r)
	return result
