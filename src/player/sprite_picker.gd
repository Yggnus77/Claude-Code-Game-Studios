class_name SpritePicker
extends RefCounted
## Picks the frame of a character sheet drawn by tools/art (rows per
## direction, columns per animation; see assets/art/personagens/*.json).
## Pure: the node passes the animation name, its clock and the facing.

## Frame size in pixels and the pivot (the feet) inside the frame.
var frame_size := Vector2i(32, 48)
var pivot := Vector2i(16, 44)
var rows: Dictionary = {"down": 0, "up": 1, "side": 2}
## Animation name → sheet columns, in play order.
var anims: Dictionary = {}
## Frames per second per animation; missing ones hold their first frame.
var fps: Dictionary = {}
## Animations that stop on their last frame instead of looping.
var once: Array = ["fall", "dodge"]


func _init(meta: Dictionary = {}) -> void:
	var fs: Array = meta.get("frame_size", [32, 48])
	frame_size = Vector2i(int(fs[0]), int(fs[1]))
	var pv: Array = meta.get("pivot", [16, 44])
	pivot = Vector2i(int(pv[0]), int(pv[1]))
	rows = meta.get("rows", rows)
	anims = meta.get("anims", {})
	fps = meta.get("fps", {})


## Reads the sheet's JSON; an empty picker (no anims) when it is missing.
static func load_meta(path: String) -> SpritePicker:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return SpritePicker.new()
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK or not json.data is Dictionary:
		return SpritePicker.new()
	return SpritePicker.new(json.data)


## The row for [param facing]: side views face right, so left is flipped.
func direction(facing: Vector2) -> Dictionary:
	if absf(facing.x) > absf(facing.y):
		return {"row": int(rows.get("side", 2)), "flip": facing.x < 0.0}
	return {"row": int(rows.get("up" if facing.y < 0.0 else "down", 0)), "flip": false}


## Column for [param anim] after [param t] seconds, or for a fixed
## [param index] (≥ 0) when the game state picks the frame itself.
func column(anim: String, t: float, index: int = -1) -> int:
	var cols: Array = anims.get(anim, anims.get("idle", [0]))
	if cols.is_empty():
		return 0
	var i := index
	if i < 0:
		var rate := float(fps.get(anim, 0.0))
		i = floori(t * rate) if rate > 0.0 else 0
		i = mini(i, cols.size() - 1) if once.has(anim) else i % cols.size()
	return int(cols[clampi(i, 0, cols.size() - 1)])


## Source rectangle in the sheet plus flip, ready for drawing.
func region(anim: String, t: float, facing: Vector2, index: int = -1) -> Dictionary:
	var d := direction(facing)
	var col := column(anim, t, index)
	return {
		"rect": Rect2(Vector2(col * frame_size.x, int(d["row"]) * frame_size.y), Vector2(frame_size)),
		"flip": d["flip"],
	}
