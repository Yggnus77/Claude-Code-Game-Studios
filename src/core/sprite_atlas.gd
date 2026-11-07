class_name SpriteAtlas
extends RefCounted
## Named frames of a sheet drawn by tools/art (e.g. inimigos.png with its
## JSON). Loaded once per path and shared; nodes draw a frame by name.

static var _cache: Dictionary = {}

var texture: Texture2D
var frame_size := Vector2(32, 48)
var pivot := Vector2(16, 44)
var frames: Array = []


## The atlas for [param png] described by [param meta_path] under [param key]
## ("" = the top level of the JSON). Null when the files are missing.
static func get_atlas(png: String, meta_path: String, key: String = "") -> SpriteAtlas:
	var id := "%s|%s" % [png, key]
	if _cache.has(id):
		return _cache[id]
	var atlas: SpriteAtlas = null
	var f := FileAccess.open(meta_path, FileAccess.READ)
	if f and ResourceLoader.exists(png):
		var json := JSON.new()
		if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
			var d: Dictionary = json.data
			if not key.is_empty():
				d = d.get(key, {})
			atlas = SpriteAtlas.new()
			atlas.texture = load(png)
			var fs: Array = d.get("frame_size", [32, 48])
			var pv: Array = d.get("pivot", [16, 44])
			atlas.frame_size = Vector2(float(fs[0]), float(fs[1]))
			atlas.pivot = Vector2(float(pv[0]), float(pv[1]))
			atlas.frames = d.get("frames", [])
	_cache[id] = atlas
	return atlas


## The enemies' sheet (assets/art/personagens/inimigos.png).
static func enemies() -> SpriteAtlas:
	return get_atlas("res://assets/art/personagens/inimigos.png", "res://assets/art/personagens/inimigos.json")


static func igris() -> SpriteAtlas:
	return get_atlas("res://assets/art/personagens/igris.png", "res://assets/art/personagens/inimigos.json", "igris")


func has_frame(frame_name: String) -> bool:
	return frames.has(frame_name)


## Draws [param frame_name] on [param item] with the frame's pivot at
## [param at]. [param flash] whitens it (a hit), [param flip] mirrors it.
func draw(item: CanvasItem, frame_name: String, at: Vector2 = Vector2.ZERO, flash: bool = false, flip: bool = false, alpha: float = 1.0) -> void:
	var col := frames.find(frame_name)
	if col < 0:
		return
	var src := Rect2(Vector2(col * frame_size.x, 0), frame_size)
	var tint := Color(2.6, 2.6, 2.6, alpha) if flash else Color(1, 1, 1, alpha)
	if flip:
		item.draw_set_transform(at, 0.0, Vector2(-1, 1))
		item.draw_texture_rect_region(texture, Rect2(-pivot, frame_size), src, tint)
		item.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		item.draw_texture_rect_region(texture, Rect2(at - pivot, frame_size), src, tint)
