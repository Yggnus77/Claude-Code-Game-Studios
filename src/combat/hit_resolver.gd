class_name HitResolver
extends RefCounted
## Decides what an incoming hit does to the player. Pure function, no nodes.
## Order: already invulnerable → dodge i-frames → guard → damage.

enum Outcome { IGNORED, DODGED, BLOCKED, PERFECT_BLOCK, GUARD_BREAK, HIT }


## [param damage]: 1 light, 2 medium, 3 strong. [param heavy] marks attacks
## that break the guard; [param unblockable] skips the guard entirely.
static func resolve(health: Health, dodge: Dodge, guard: Guard, facing: Vector2, to_attacker: Vector2, damage: int, heavy: bool = false, unblockable: bool = false) -> Outcome:
	if health.is_dead() or health.is_invulnerable():
		return Outcome.IGNORED
	if dodge.is_invulnerable():
		return Outcome.DODGED
	if not unblockable and guard.is_up() and guard.covers(facing, to_attacker):
		if not heavy:
			return Outcome.PERFECT_BLOCK if guard.is_perfect() else Outcome.BLOCKED
		guard.break_guard()
		health.take_damage(mini(damage, guard.heavy_damage))
		return Outcome.GUARD_BREAK
	health.take_damage(damage)
	return Outcome.HIT
