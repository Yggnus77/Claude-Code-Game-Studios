class_name Rastejo
extends EnemyBase
## Rastejo de Tinta: easy enemy that inflates, then charges in a straight line
## (design/kit/bestiario.csv; numbers in assets/data/inimigos.json).
## idle → approach → telegraph (direction locks for the last
## [code]lock_direction_before[/code] s) → charge → recovery. Hits interrupt.

enum State { IDLE, APPROACH, TELEGRAPH, CHARGE, RECOVER }

const COLOR_BODY := Color("7a55b0")
const COLOR_INK := Color("2a1838")

var state: State = State.IDLE
var charge_direction := Vector2.ZERO
var _timer := 0.0
var _charge_has_hit := false


func _think(delta: float) -> void:
	var to := to_target()
	var dist := to.length()
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist <= p("perception_range", 112):
				state = State.APPROACH
		State.APPROACH:
			velocity = to.normalized() * p("speed", 48)
			if dist <= p("attack_range", 64):
				_enter(State.TELEGRAPH, p("telegraph", 0.65))
				charge_direction = to.normalized()
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer > p("lock_direction_before", 0.2) and dist > 0.0:
				charge_direction = to.normalized()
			if _timer <= 0.0:
				_charge_has_hit = false
				_enter(State.CHARGE, p("charge_duration", 0.35))
		State.CHARGE:
			velocity = charge_direction * p("charge_speed", 150)
			_timer -= delta
			if not _charge_has_hit and try_hit_target(global_position, body_radius(), int(params.get("damage", 1))):
				_charge_has_hit = true
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				_enter(State.RECOVER, p("recovery", 0.8))
		State.RECOVER:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				state = State.APPROACH


func _enter(next: State, seconds: float) -> void:
	state = next
	_timer = seconds


func _on_hurt() -> void:
	state = State.APPROACH


func _draw_body() -> void:
	var r := body_radius()
	var squash := 1.0
	if state == State.TELEGRAPH:
		# Inflates while preparing the charge: shape changes, not only colour.
		var t := 1.0 - clampf(_timer / p("telegraph", 0.65), 0.0, 1.0)
		squash = 1.0 + 0.45 * t
		draw_arc(Vector2.ZERO, r * squash + 3.0, 0, TAU, 20, COLOR_WARN, 1.5)
		draw_line(Vector2.ZERO, charge_direction * (r + 10.0), COLOR_WARN, 2.0)
	var art := SpriteAtlas.enemies()
	if art:
		var frame := "rastejo_idle%d" % (int(Time.get_ticks_msec() / 300) % 2)
		if state == State.TELEGRAPH:
			frame = "rastejo_telegraph"
		elif state == State.CHARGE:
			frame = "rastejo_charge"
		art.draw(self, frame, Vector2(0, 2), _flash > 0.0, charge_direction.x < 0.0)
		return
	var color := COLOR_FLASH if _flash > 0.0 else COLOR_BODY
	draw_circle(Vector2(0, -r * 0.4), r * squash, color)
	draw_circle(Vector2(0, -r * 0.4), r * squash * 0.55, COLOR_INK if _flash <= 0.0 else COLOR_FLASH)
