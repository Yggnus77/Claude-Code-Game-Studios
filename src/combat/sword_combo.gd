class_name SwordCombo
extends RefCounted
## Timing state machine for the three-hit sword combo
## (design/kit/mecanicas-e-dificuldade.md §3–4, numbers in combate.json).
##
## - each press is buffered for [member input_buffer] seconds and used once;
## - the next hit only starts if the player asked for it (no auto-combo);
## - [member chain_reset] seconds idle after a recovery restarts at hit 1;
## - every swing gets a new [member attack_id], so a target is hit at most
##   once per active window;
## - hits 1–2 may be cancelled by a dodge after their active window; the
##   finisher only in the last [member finisher_cancel] seconds of recovery.

enum Phase { IDLE, STARTUP, ACTIVE, RECOVERY }

static var _next_attack_id := 1

var steps: Array
var damages: Array
var input_buffer: float
var chain_reset: float
var finisher_cancel: float

var phase: Phase = Phase.IDLE
## Index (0-based) of the swing in progress, or of the last one when idle.
var stage := -1
## Unique id of the swing in progress (0 when idle).
var attack_id := 0
var _timer := 0.0
var _buffer := 0.0
var _idle := 0.0
var _next_stage := 0


## [param combo] is combate.json "combo"; [param weapon_damage] overrides the
## per-hit damage (combate.json "weapons"), when given.
func _init(combo: Array, weapon_damage: Array = [], buffer: float = 0.12, reset_after: float = 0.38, finisher_cancel_window: float = 0.10) -> void:
	steps = combo
	damages = []
	for i in combo.size():
		damages.append(int(weapon_damage[i]) if i < weapon_damage.size() else int(combo[i].get("damage", 1)))
	input_buffer = buffer
	chain_reset = reset_after
	finisher_cancel = finisher_cancel_window


## Registers an attack press.
func request() -> void:
	_buffer = input_buffer


func is_busy() -> bool:
	return phase != Phase.IDLE


func is_active() -> bool:
	return phase == Phase.ACTIVE


## Damage of the swing in progress.
func damage() -> int:
	return damages[stage] if stage >= 0 else 0


## Reach in pixels of the swing in progress.
func reach() -> float:
	return float(steps[stage].get("range", 20)) if stage >= 0 else 0.0


## True when a dodge may cancel the current swing.
func can_cancel() -> bool:
	if phase == Phase.IDLE:
		return true
	if phase != Phase.RECOVERY:
		return false
	if stage < steps.size() - 1:
		return true
	return _timer <= finisher_cancel + 0.00001


## Stops the swing (dodge cancel, hit stun). The chain continues from the
## next hit if the player attacks again within the reset window.
func cancel() -> void:
	if phase == Phase.IDLE:
		return
	_finish_swing()


## Forgets the chain entirely (death, room change).
func reset() -> void:
	phase = Phase.IDLE
	stage = -1
	attack_id = 0
	_buffer = 0.0
	_idle = 0.0
	_next_stage = 0


## Advances timers. Returns true on the step a new swing starts.
func tick(delta: float) -> bool:
	_buffer = maxf(0.0, _buffer - delta)
	match phase:
		Phase.IDLE:
			_idle += delta
			if _idle > chain_reset:
				_next_stage = 0
		Phase.STARTUP:
			_timer -= delta
			if _timer <= 0.0:
				phase = Phase.ACTIVE
				_timer += float(steps[stage]["active"])
		Phase.ACTIVE:
			_timer -= delta
			if _timer <= 0.0:
				phase = Phase.RECOVERY
				_timer += float(steps[stage]["recovery"])
		Phase.RECOVERY:
			_timer -= delta
			if _timer <= 0.0:
				_finish_swing()
	if phase == Phase.IDLE and _buffer > 0.0:
		_buffer = 0.0
		_start(_next_stage)
		return true
	return false


func _start(index: int) -> void:
	stage = index
	phase = Phase.STARTUP
	_timer = float(steps[index]["startup"])
	attack_id = _next_attack_id
	_next_attack_id += 1


func _finish_swing() -> void:
	phase = Phase.IDLE
	attack_id = 0
	_idle = 0.0
	_next_stage = stage + 1 if stage + 1 < steps.size() else 0
