class_name Healing
extends RefCounted
## Using a Restorative flask or eating bread (mecanicas-e-dificuldade.md §8,
## combate.json "healing"): a 0.65 s use at 25% speed, then a 0.20 s recovery.
## The item is consumed only at the effect frame; a hit before that cancels
## the use and nothing is spent. Starting at full life does nothing.

enum Phase { IDLE, USING, RECOVERY }

var startup: float
var recovery: float
var movement_factor: float
var phase := Phase.IDLE

var _left := 0.0
var _amount := 0


func _init(params: Dictionary) -> void:
	startup = float(params.get("startup", 0.65))
	recovery = float(params.get("recovery", 0.2))
	movement_factor = float(params.get("movement_factor", 0.25))


## Begins a use that restores [param amount]. False when busy or amount ≤ 0.
func start(amount: int) -> bool:
	if phase != Phase.IDLE or amount <= 0:
		return false
	phase = Phase.USING
	_left = startup
	_amount = amount
	return true


## Advances the use. Returns the life to restore on the effect frame, else 0.
func tick(delta: float) -> int:
	if phase == Phase.IDLE:
		return 0
	_left -= delta
	if _left > 0.0:
		return 0
	if phase == Phase.USING:
		phase = Phase.RECOVERY
		_left = recovery
		return _amount
	phase = Phase.IDLE
	return 0


## A hit or a dodge cancels the use before anything is consumed; during the
## recovery (after the effect) it only ends the recovery early.
func interrupt() -> void:
	phase = Phase.IDLE


func is_busy() -> bool:
	return phase != Phase.IDLE


## Movement multiplier while using.
func speed_factor() -> float:
	return movement_factor if is_busy() else 1.0


func reset() -> void:
	phase = Phase.IDLE
