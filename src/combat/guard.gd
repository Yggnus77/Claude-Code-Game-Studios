class_name Guard
extends RefCounted
## Shield guard (design/kit/mecanicas-e-dificuldade.md §5, combate.json "guard").
## Frontal cone; light hits are fully blocked, heavy hits break the guard.
## A precise guard is the first [member perfect_window] seconds of a press;
## a new attempt needs a release and at least [member minimum_retrigger] s.

var half_angle: float
var speed_factor: float
var perfect_window: float
var minimum_retrigger: float
var heavy_damage: int
var break_time: float

var _held := false
var _held_for := 0.0
var _since_press := INF
var _broken_left := 0.0


func _init(params: Dictionary) -> void:
	half_angle = deg_to_rad(float(params.get("angle_degrees", 100)) * 0.5)
	speed_factor = float(params.get("speed_factor", 0.45))
	perfect_window = float(params.get("perfect_window", 0.11))
	minimum_retrigger = float(params.get("minimum_retrigger", 0.25))
	heavy_damage = int(params.get("heavy_guard_damage", 1))
	break_time = float(params.get("guard_break", 0.45))


## Feeds the button state each physics step.
func set_held(pressed: bool) -> void:
	if pressed and not _held:
		if _since_press < minimum_retrigger or is_broken():
			return
		_held = true
		_held_for = 0.0
		_since_press = 0.0
	elif not pressed:
		_held = false


func is_up() -> bool:
	return _held and not is_broken()


func is_perfect() -> bool:
	return is_up() and _held_for < perfect_window


func is_broken() -> bool:
	return _broken_left > 0.0


## True when an attack coming from [param to_attacker] (player → attacker)
## lands inside the frontal cone of [param facing].
func covers(facing: Vector2, to_attacker: Vector2) -> bool:
	if to_attacker.length_squared() == 0.0:
		return true
	return absf(facing.angle_to(to_attacker)) <= half_angle + 0.0001


## Breaks the guard (heavy hit): no guard for [member break_time] seconds.
func break_guard() -> void:
	_held = false
	_broken_left = break_time


func tick(delta: float) -> void:
	_since_press += delta
	if _held:
		_held_for += delta
	_broken_left = maxf(0.0, _broken_left - delta)


func reset() -> void:
	_held = false
	_since_press = INF
	_broken_left = 0.0
