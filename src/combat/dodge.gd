class_name Dodge
extends RefCounted
## Dodge timing (design/kit/mecanicas-e-dificuldade.md §5, combate.json "dodge").
## Invulnerable only inside [invulnerability_start, invulnerability_end];
## cooldown counts from the start; holding the button does not repeat it.
## Walls are respected because the player moves with move_and_slide().

var duration: float
var speed: float
var invuln_start: float
var invuln_end: float
var cooldown: float
var input_buffer: float

## Direction of the dodge in progress.
var direction := Vector2.ZERO
var _elapsed := -1.0
var _since_start := INF
var _buffer := 0.0


func _init(params: Dictionary, buffer: float = 0.12) -> void:
	duration = float(params.get("duration", 0.22))
	speed = float(params.get("speed", 230))
	invuln_start = float(params.get("invulnerability_start", 0.03))
	invuln_end = float(params.get("invulnerability_end", 0.15))
	cooldown = float(params.get("cooldown_from_start", 0.65))
	input_buffer = buffer


## Registers a dodge press (call on just-pressed only).
func request() -> void:
	_buffer = input_buffer


## True while a press is buffered and the cooldown has passed.
func wants_to_start() -> bool:
	return _buffer > 0.0 and is_ready()


## True when the cooldown allows a new dodge.
func is_ready() -> bool:
	return not is_dodging() and _since_start >= cooldown


## True while the dodge moves Yggnus.
func is_dodging() -> bool:
	return _elapsed >= 0.0 and _elapsed < duration


## True inside the dodge's invulnerable frames.
func is_invulnerable() -> bool:
	return is_dodging() and _elapsed >= invuln_start and _elapsed < invuln_end


## Starts the dodge toward [param dir] (normalised). Consumes the buffer.
func start(dir: Vector2) -> void:
	direction = dir.normalized()
	_elapsed = 0.0
	_since_start = 0.0
	_buffer = 0.0


## Velocity to apply this step.
func velocity() -> Vector2:
	return direction * speed if is_dodging() else Vector2.ZERO


## Advances the dodge, its cooldown and the press buffer.
func tick(delta: float) -> void:
	_buffer = maxf(0.0, _buffer - delta)
	_since_start += delta
	if _elapsed >= 0.0:
		_elapsed += delta
		if _elapsed >= duration:
			_elapsed = -1.0


## Clears any dodge and cooldown (respawn).
func reset() -> void:
	_elapsed = -1.0
	_since_start = INF
	_buffer = 0.0
