class_name Torch
extends Node2D
## A standing torch the Lamparina lights (design/gdd/ferramentas.md §3).
## Unlit it is a cold iron basket; lit it burns, flickers and casts its own
## light. The game keeps which torches are lit and the puzzle's flag.

const LIGHT_COLOR := Color("ffa850")

var room: Room
## Reach of the torch's light when lit (ferramentas.json lamparina.torch_light_radius).
var light_radius := 104.0
## The map entity this torch comes from.
var entity: Dictionary = {}
var lit := false
## A lamp painted in the room's picture (map "painted"): the torch draws
## only the flame and the light, at [member flame_offset].
var painted := false
## Where the painted lamp's glass is, from the torch's position.
var flame_offset := Vector2.ZERO
var _light: PointLight2D
var _t := 0.0


func _ready() -> void:
	_light = PointLight2D.new()
	_light.texture = Room.light_texture()
	_light.color = LIGHT_COLOR
	_light.position = flame_offset if painted else Vector2(0, -18)
	_light.texture_scale = light_radius * 2.0 / 128.0
	add_child(_light)
	set_lit(lit)


func entity_id() -> String:
	return str(entity.get("id", ""))


## The flag that all torches with it set when every one is lit.
func puzzle_flag() -> String:
	return str(entity.get("sets_flag", ""))


## Removes the torch's light (the copy of a room drawn during a slide must
## not add lights).
func drop_light() -> void:
	if _light:
		_light.queue_free()
		_light = null


func set_lit(value: bool) -> void:
	lit = value
	if _light:
		_light.visible = lit
		_light.energy = 1.15
	queue_redraw()


func _process(delta: float) -> void:
	if not lit:
		return
	_t += delta
	if _light:
		_light.energy = 1.15 * (0.9 + 0.07 * sin(_t * 8.0) + 0.03 * sin(_t * 15.0))
	queue_redraw()


func _draw() -> void:
	if painted:
		if lit:
			# The cold glass of the picture lights up: a warm core and a halo.
			var f := flame_offset
			var flick := 0.6 * sin(_t * 9.0)
			draw_circle(f, 7.0 + flick, Color(1.0, 0.66, 0.3, 0.28))
			draw_circle(f, 4.0, Color(1.0, 0.78, 0.42, 0.85))
			var h := 2.0 + 1.0 * sin(_t * 11.0)
			draw_colored_polygon(PackedVector2Array([f + Vector2(-2, 3), f + Vector2(0.5 * sin(_t * 7.0), -2 - h), f + Vector2(2, 3)]), Color(1, 0.96, 0.8, 0.95))
		return
	if room and is_instance_valid(room):
		room.draw_object_on(self, "torch_on" if lit else "torch_off")
	if lit:
		# A live tongue of flame over the painted one.
		var h := 2.0 + 1.5 * sin(_t * 11.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-1.5, -17), Vector2(0.5 * sin(_t * 7.0), -20 - h), Vector2(1.5, -17)]), Color(1, 0.95, 0.75, 0.8))
