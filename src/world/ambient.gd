class_name Ambient
extends Node2D
## Movement in a painted room's picture (design/gdd/salas-pintadas.md §3):
## mill sails, gears and wheels turn, banners sway, the painted flames
## breathe and water glints. What moves and where comes from
## assets/data/animacoes-salas.json (tools/art/animacoes_salas.py), the
## moving pieces from assets/art/salas/anim/. Draws over the background and
## under everything that stands in the room.

const DATA_PATH := "res://assets/data/animacoes-salas.json"
const ANIM_DIR := "res://assets/art/salas/anim"
const GLOW_COLOR := Color(1.0, 0.72, 0.38)
const GLINT_COLOR := Color(0.85, 0.95, 1.0)

static var _all: Dictionary = {}
static var _loaded := false

## The room's moving pieces ("tipo" spin, sway, glow or water).
var items: Array = []
var _textures: Dictionary = {}
var _t := 0.0
var _light: Node2D
var _has_body := false
var _has_light := false


## The pieces listed for [param room_id] (empty when it has none).
static func pieces_for(room_id: String) -> Array:
	if not _loaded:
		_loaded = true
		if FileAccess.file_exists(DATA_PATH):
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
			if parsed is Dictionary:
				_all = parsed
	return _all.get(room_id, []) as Array


## Fills this node for [param room_id]; returns false when nothing moves.
func setup(room_id: String) -> bool:
	items = pieces_for(room_id)
	for it: Dictionary in items:
		var tex := str(it.get("textura", ""))
		if not tex.is_empty():
			var path := "%s/%s.png" % [ANIM_DIR, tex]
			if ResourceLoader.exists(path):
				_textures[tex] = load(path)
	# Light (flames, glints) adds to the picture instead of covering it.
	_light = Node2D.new()
	_light.name = "Light"
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_light.material = mat
	_light.draw.connect(_draw_light)
	add_child(_light)
	for it: Dictionary in items:
		match str(it.get("tipo", "")):
			"spin", "sway":
				_has_body = true
			"glow", "water":
				_has_light = true
	set_process(_has_body or _has_light)
	return not items.is_empty()


## The angle [param item] (a "spin" piece) has turned to so far.
func turn_of(item: Dictionary) -> float:
	return _t * float(item.get("vel", 1.0))


func _process(delta: float) -> void:
	_t += delta
	# Only the layer that has something to move is redrawn.
	if _has_body:
		queue_redraw()
	if _has_light:
		_light.queue_redraw()


func _draw() -> void:
	for it: Dictionary in items:
		var tex: Texture2D = _textures.get(str(it.get("textura", "")))
		if tex == null:
			continue
		match str(it.get("tipo", "")):
			"spin":
				var c := _vec(it["centro"])
				var k := float(it.get("achata", 1.0))
				var a := turn_of(it)
				# Turn in the picture's own proportions: the piece was squashed
				# by the room's height/width scale, so unsquash, turn, squash.
				var xf := Transform2D(0.0, c) * Transform2D(0.0, Vector2(1.0, k), 0.0, Vector2.ZERO) \
					* Transform2D(a, Vector2.ZERO) * Transform2D(0.0, Vector2(1.0, 1.0 / k), 0.0, Vector2.ZERO)
				draw_set_transform_matrix(xf)
				draw_texture(tex, -_vec(it["pivo"]))
				draw_set_transform_matrix(Transform2D.IDENTITY)
			"sway":
				var at := _vec(it["pos"])
				var h := tex.get_height()
				var amp := float(it.get("amplitude", 1.6))
				var speed := float(it.get("vel", 2.2))
				for y in range(0, h, 2):
					# Hung from the top: the lower edge moves most.
					var u := float(y) / maxf(1.0, h - 1.0)
					var dx := roundf(amp * u * u * sin(_t * speed - u * 2.2))
					draw_texture_rect_region(tex, Rect2(at + Vector2(dx, y), Vector2(tex.get_width(), mini(2, h - y))),
						Rect2(0, y, tex.get_width(), mini(2, h - y)))


func _draw_light() -> void:
	var i := 0
	for it: Dictionary in items:
		i += 1
		match str(it.get("tipo", "")):
			"glow":
				var p := _vec(it["pos"])
				var r := float(it.get("raio", 14.0))
				var breath := 0.5 + 0.3 * sin(_t * 6.0 + i * 1.9) + 0.2 * sin(_t * 13.0 + i)
				_light.draw_circle(p, r, Color(GLOW_COLOR, 0.05 + 0.05 * breath))
				_light.draw_circle(p, r * 0.5, Color(GLOW_COLOR, 0.08 + 0.10 * breath))
				_light.draw_circle(p, 2.0, Color(1, 0.9, 0.6, 0.25 + 0.3 * breath))
			"water":
				var c := _vec(it["centro"])
				var rad := _vec(it["raio"])
				var n := clampi(int(rad.x * rad.y / 30.0), 4, 40)
				for j in n:
					# Fixed spots (hashed from j) that drift sideways and blink.
					var u := fposmod(sin(j * 12.9898 + i) * 43758.5453, 1.0)
					var v := fposmod(sin(j * 78.233 + i) * 12345.6789, 1.0)
					var ang := u * TAU
					var dist := sqrt(v)
					var p := c + Vector2(cos(ang) * rad.x * dist, sin(ang) * rad.y * dist)
					p.x += sin(_t * 0.8 + j) * 2.0
					var blink := maxf(0.0, sin(_t * 2.5 + j * 2.3))
					if blink > 0.05:
						_light.draw_rect(Rect2(p.floor(), Vector2(2, 1)), Color(GLINT_COLOR, 0.45 * blink))


static func _vec(v: Variant) -> Vector2:
	var a: Array = v
	return Vector2(float(a[0]), float(a[1]))
