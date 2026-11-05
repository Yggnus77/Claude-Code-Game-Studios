class_name Health
extends RefCounted
## Life points with post-hit invulnerability (design/kit/mecanicas-e-dificuldade.md §6).
## Invulnerability starts in the same call that applies damage, so two contacts
## in one physics step never stack.

signal changed(current: int, maximum: int)
signal died

var maximum: int
var current: int
## Seconds of invulnerability granted after each hit.
var invulnerability: float
var _invulnerable_left := 0.0


func _init(max_life: int, invulnerability_seconds: float = 0.0) -> void:
	maximum = max_life
	current = max_life
	invulnerability = invulnerability_seconds


## Advances the invulnerability timer.
func tick(delta: float) -> void:
	_invulnerable_left = maxf(0.0, _invulnerable_left - delta)


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func is_dead() -> bool:
	return current <= 0


## Applies [param amount] damage unless invulnerable or already dead.
## Returns true when the damage was applied.
func take_damage(amount: int) -> bool:
	if is_dead() or is_invulnerable() or amount <= 0:
		return false
	current = maxi(0, current - amount)
	_invulnerable_left = invulnerability
	changed.emit(current, maximum)
	if current == 0:
		died.emit()
	return true


## Restores [param amount] life, never above [member maximum].
func heal(amount: int) -> void:
	if is_dead():
		return
	current = mini(maximum, current + amount)
	changed.emit(current, maximum)


## Back to full life with no invulnerability (respawn at a checkpoint).
func reset() -> void:
	current = maximum
	_invulnerable_left = 0.0
	changed.emit(current, maximum)
