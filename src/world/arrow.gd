class_name Arrow
extends Node2D
## A needle shot by the Arco de Fio (design/gdd/ferramentas.md §3). It flies
## straight, asks [member probe] what is at its tip every few pixels (so it
## never crosses a wall), and stops at the first thing it touches. The game
## decides what that thing does through [signal stopped].
##
## Example:
##   var a := Arrow.new()
##   a.direction = Vector2.RIGHT
##   a.probe = func(pos: Vector2) -> Dictionary: return {}
##   a.stopped.connect(func(hit: Dictionary, at: Vector2) -> void: pass)

## The needle stopped at [param at]: [param hit] is what the probe returned,
## or {"type": "range"} when it flew its whole range.
signal stopped(hit: Dictionary, at: Vector2)

## Distance between checks along the path (as the hook).
const STEP := 4.0
const COLOR_SHAFT := Color("d8d2c4")
const COLOR_SHAFT_LO := Color("8a8478")
const COLOR_TIP := Color("e8f4ff")
const COLOR_THREAD := Color("7ee0ff")

var direction := Vector2.RIGHT
var speed := 260.0
var max_range := 224.0
## Callable(pos: Vector2) -> Dictionary: {} when nothing is there, else
## {"type": "enemy" | "plate" | "wall" | "solid", ...}.
var probe: Callable = func(_pos: Vector2) -> Dictionary: return {}
var travelled := 0.0
var done := false


func _ready() -> void:
	add_to_group("projectiles")
	direction = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	rotation = direction.angle()


## Moves the needle [param delta] seconds. Returns true when it stopped.
func advance(delta: float) -> bool:
	if done:
		return true
	var target := minf(max_range, travelled + speed * delta)
	while travelled < target:
		travelled = minf(target, travelled + STEP)
		var at := global_position + direction * STEP
		var hit: Dictionary = probe.call(at)
		if not hit.is_empty():
			_stop(hit, global_position)
			return true
		global_position = at
	if travelled >= max_range:
		_stop({"type": "range"}, global_position)
		return true
	return false


func _stop(hit: Dictionary, at: Vector2) -> void:
	done = true
	stopped.emit(hit, at)
	queue_free()


func _physics_process(delta: float) -> void:
	advance(delta)


func _draw() -> void:
	# Drawn along +x (the node is rotated to the flight direction): a pale
	# thread trailing, the bronze-grey shaft, a bright steel point.
	for i in range(1, 4):
		draw_line(Vector2(-6.0 - i * 3.0, 0), Vector2(-4.0 - i * 3.0, 0), Color(COLOR_THREAD, 0.5 - i * 0.12), 1.0)
	draw_line(Vector2(-6, 0), Vector2(3, 0), COLOR_SHAFT, 1.0)
	draw_line(Vector2(-6, 1), Vector2(2, 1), COLOR_SHAFT_LO, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(3, -1.5), Vector2(7, 0), Vector2(3, 1.5)]), COLOR_TIP)
	draw_line(Vector2(-7, -1.5), Vector2(-5, 0), COLOR_THREAD, 1.0)
	draw_line(Vector2(-7, 1.5), Vector2(-5, 0), COLOR_THREAD, 1.0)
