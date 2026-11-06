class_name Hook
extends RefCounted
## Gancho de Retorno (mecanicas-e-dificuldade.md §7, combate.json "hook").
## Pure rule: 0.10 s startup, a tip that travels up to 112 px at 360 px/s and
## checks the world every few pixels along the way (a wall stops it, so it
## never crosses one), then returns; 0.35 s cooldown after it is back. The
## owner moves at 35% while the cable is out. A latched traversal anchor
## turns into a pull, which the owner drives and ends with [method end_pull].

enum Phase { IDLE, STARTUP, OUT, BACK, PULL, COOLDOWN }

## Distance between world checks along the tip's path.
const STEP := 4.0

var reach: float
var startup: float
var tip_speed: float
var cooldown: float
var speed_factor: float
var phase := Phase.IDLE
var direction := Vector2.DOWN
## Distance of the tip from the origin.
var distance := 0.0

var _left := 0.0


func _init(params: Dictionary) -> void:
	reach = float(params.get("range", 112))
	startup = float(params.get("startup", 0.1))
	tip_speed = float(params.get("tip_speed", 360))
	cooldown = float(params.get("return_cooldown", 0.35))
	speed_factor = float(params.get("speed_factor", 0.35))


## Launches toward [param dir]. False while the hook is busy or cooling down.
func fire(dir: Vector2) -> bool:
	if phase != Phase.IDLE or dir == Vector2.ZERO:
		return false
	direction = dir.normalized()
	distance = 0.0
	phase = Phase.STARTUP
	_left = startup
	return true


## Advances the hook from [param origin]. [param probe] takes a world
## position and returns {} when nothing is there, or a Dictionary with a
## "type" ("wall", "anchor", "enemy", "weight"...). Returns the first thing
## the tip touched this step, else {}. The tip always returns after a touch.
func tick(delta: float, origin: Vector2, probe: Callable) -> Dictionary:
	match phase:
		Phase.STARTUP:
			_left -= delta
			if _left <= 0.0:
				phase = Phase.OUT
		Phase.OUT:
			var target := minf(reach, distance + tip_speed * delta)
			while distance < target:
				distance = minf(target, distance + STEP)
				var hit: Dictionary = probe.call(origin + direction * distance)
				if not hit.is_empty():
					phase = Phase.BACK
					return hit
			if distance >= reach:
				phase = Phase.BACK
		Phase.BACK:
			# An invalid or finished throw comes back fast (twice the speed).
			distance -= tip_speed * 2.0 * delta
			if distance <= 0.0:
				distance = 0.0
				_start_cooldown()
		Phase.COOLDOWN:
			_left -= delta
			if _left <= 0.0:
				phase = Phase.IDLE
	return {}


## The owner is being pulled to a latched anchor.
func begin_pull() -> void:
	phase = Phase.PULL


## Ends the pull on arrival and starts the cooldown.
func end_pull() -> void:
	distance = 0.0
	_start_cooldown()


## A hit or a room change reels the cable in at once.
func cancel() -> void:
	if phase in [Phase.STARTUP, Phase.OUT, Phase.PULL]:
		phase = Phase.BACK


## True from the launch until the tip is back (not during the cooldown).
func is_busy() -> bool:
	return phase in [Phase.STARTUP, Phase.OUT, Phase.BACK, Phase.PULL]


## Position of the tip seen from [param origin].
func tip(origin: Vector2) -> Vector2:
	return origin + direction * distance


## Back to idle with no cooldown.
func reset() -> void:
	phase = Phase.IDLE
	distance = 0.0


func _start_cooldown() -> void:
	phase = Phase.COOLDOWN
	_left = cooldown
