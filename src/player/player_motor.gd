class_name PlayerMotor
extends RefCounted
## Pure movement math for Yggnus: eight-direction walking with acceleration,
## deceleration and four-direction facing. No nodes, so it is unit-testable.
##
## Rules (design/kit/mecanicas-e-dificuldade.md, section 2):
## - the input vector is normalised, so walking diagonally is not faster;
## - velocity moves toward the target at [member acceleration] while there is
##   input and at [member deceleration] when there is none;
## - facing follows the dominant axis of the input; an exact diagonal tie keeps
##   the previous facing.

## Top walking speed, px/s.
var speed: float
## Rate used to reach the target velocity while input is held, px/s².
var acceleration: float
## Rate used to stop when input is released, px/s².
var deceleration: float
## Cardinal facing: one of Vector2.UP, DOWN, LEFT, RIGHT.
var facing: Vector2 = Vector2.DOWN


func _init(params: Dictionary) -> void:
	speed = float(params.get("speed", 0.0))
	acceleration = float(params.get("acceleration", 0.0))
	deceleration = float(params.get("deceleration", 0.0))


## Returns the new velocity after [param delta] seconds of [param input].
## [param speed_factor] scales the top speed (defence uses 0.45, for example).
func step(velocity: Vector2, input: Vector2, delta: float, speed_factor: float = 1.0) -> Vector2:
	var direction := input.limit_length(1.0)
	if direction.length_squared() > 0.0:
		_update_facing(direction)
		var target := direction * speed * speed_factor
		return velocity.move_toward(target, acceleration * delta)
	return velocity.move_toward(Vector2.ZERO, deceleration * delta)


func _update_facing(direction: Vector2) -> void:
	var ax := absf(direction.x)
	var ay := absf(direction.y)
	if is_equal_approx(ax, ay):
		return
	if ax > ay:
		facing = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		facing = Vector2.DOWN if direction.y > 0.0 else Vector2.UP
