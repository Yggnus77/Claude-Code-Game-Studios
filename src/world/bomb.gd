class_name Bomb
extends Node2D
## A Carga de Bronze on the ground (design/gdd/ferramentas.md §3): its fuse
## burns for [member fuse] seconds, blinking faster near the end, then it
## explodes once and tells the game where through [signal exploded]. The
## game decides what the blast reaches (enemies, pots, cracked walls,
## Yggnus).
##
## Example:
##   var b := Bomb.new()
##   b.fuse = 1.6
##   b.exploded.connect(func(bomb: Bomb) -> void: print(bomb.global_position))

signal exploded(bomb: Bomb)

const COLOR_BODY := Color("b8873a")
const COLOR_BODY_HI := Color("e0b555")
const COLOR_BODY_LO := Color("7d5a26")
const COLOR_BAND := Color("5a3e18")
const COLOR_OUTLINE := Color("1a1420")
const COLOR_SPARK := Color("fff2c0")
const COLOR_SPARK_HOT := Color("ff8a3a")

var fuse := 1.6
var radius := 28.0
var left := 1.6
var done := false
var _t := 0.0


func _ready() -> void:
	add_to_group("projectiles")
	left = fuse


## Burns the fuse [param delta] seconds. Returns true when it went off.
func burn(delta: float) -> bool:
	if done:
		return true
	left -= delta
	_t += delta
	if left <= 0.0:
		detonate()
		return true
	return false


## Goes off now (the fuse ran out, or another blast reached it).
func detonate() -> void:
	if done:
		return
	done = true
	Fx.explosion(get_parent(), position, radius)
	exploded.emit(self)
	queue_free()


func _physics_process(delta: float) -> void:
	burn(delta)
	queue_redraw()


func _draw() -> void:
	# Blinks red-hot in the last part of the fuse, faster and faster.
	var hot := left < fuse * 0.45 and int(_t * (6.0 if left > fuse * 0.2 else 14.0)) % 2 == 0
	draw_circle(Vector2(0, 3), 5.0, Color(0, 0, 0, 0.35))
	draw_circle(Vector2(0, -2), 5.5, COLOR_OUTLINE)
	draw_circle(Vector2(0, -2), 4.5, COLOR_SPARK_HOT.darkened(0.2) if hot else COLOR_BODY)
	draw_circle(Vector2(-1.2, -3.4), 2.2, COLOR_BODY_HI if not hot else COLOR_SPARK_HOT)
	draw_line(Vector2(-4.4, -1), Vector2(4.4, -1), COLOR_BAND, 1.0)
	draw_rect(Rect2(-1.5, -6.5, 3, 2), COLOR_BODY_LO)
	# The fuse, shorter as it burns, with its spark at the tip.
	var k := clampf(left / maxf(fuse, 0.01), 0.0, 1.0)
	var tip := Vector2(1.0 + 3.0 * k, -7.0 - 4.0 * k)
	draw_line(Vector2(0, -6.5), tip, Color("6a5a48"), 1.0)
	var flick := 1.0 + 0.6 * sin(_t * 40.0)
	draw_circle(tip, 1.3 * flick, COLOR_SPARK_HOT)
	draw_circle(tip, 0.7, COLOR_SPARK)
