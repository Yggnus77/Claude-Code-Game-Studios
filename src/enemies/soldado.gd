class_name Soldado
extends EnemyBase
## Soldado de Corda: walks up, raises its sword slowly, cuts once, then stays
## open (bestiario: "corte lento; defesa e contra-ataque"). It does not flinch
## while winding up or cutting, so blocking first and countering is the answer.

enum State { IDLE, APPROACH, WINDUP, STRIKE, RECOVER }

const COLOR_BODY := Color("a0643c")
const COLOR_ROPE := Color("d9c08a")
const COLOR_BLADE := Color("dfe6ee")

var state: State = State.IDLE
var facing := Vector2.DOWN
var _timer := 0.0
var _strike_has_hit := false


func _flinches() -> bool:
	return not (bool(params.get("poise_while_attacking", true)) and (state == State.WINDUP or state == State.STRIKE))


func _think(delta: float) -> void:
	var to := to_target()
	var dist := to.length()
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist <= p("perception_range", 120):
				state = State.APPROACH
		State.APPROACH:
			if dist > 0.0:
				facing = to.normalized()
			velocity = facing * p("speed", 50)
			if dist <= p("attack_range", 26):
				_enter(State.WINDUP, p("telegraph", 0.65))
		State.WINDUP:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer > p("lock_direction_before", 0.25) and dist > 0.0:
				facing = to.normalized()
			if _timer <= 0.0:
				_strike_has_hit = false
				_enter(State.STRIKE, p("strike_active", 0.15))
		State.STRIKE:
			velocity = Vector2.ZERO
			_timer -= delta
			if not _strike_has_hit and try_hit_target(strike_center(), p("strike_half_width", 12), int(params.get("damage", 1))):
				_strike_has_hit = true
			if _timer <= 0.0:
				_enter(State.RECOVER, p("recovery", 0.75))
		State.RECOVER:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				state = State.APPROACH


## Centre of the cut, in global coordinates.
func strike_center() -> Vector2:
	return global_position + facing * p("strike_reach", 26) * 0.6


func _enter(next: State, seconds: float) -> void:
	state = next
	_timer = seconds


func _on_hurt() -> void:
	state = State.APPROACH


func _draw_body() -> void:
	var r := body_radius()
	var art := SpriteAtlas.enemies()
	if art:
		var frame := "soldado_idle"
		if state == State.WINDUP:
			frame = "soldado_windup"
		elif state == State.STRIKE:
			frame = "soldado_strike"
		var sideways := absf(facing.x) >= absf(facing.y)
		if state == State.STRIKE and not sideways:
			frame = "soldado_idle"  # the sheet's strike points sideways
		art.draw(self, frame, Vector2(0, 2), _flash > 0.0, facing.x < 0.0)
		# Markers over the body, so they stay readable when it faces up.
		if state == State.WINDUP:
			draw_arc(strike_center() - global_position, p("strike_half_width", 12), 0, TAU, 16, COLOR_WARN, 1.5)
		elif state == State.STRIKE and not sideways:
			var hand := Vector2(0, -r * 1.5) + facing * r
			draw_line(hand, hand + facing * p("strike_reach", 26), Color("d4a849"), 3.0)
		return
	var c := COLOR_FLASH if _flash > 0.0 else COLOR_BODY
	draw_rect(Rect2(Vector2(-r, -r * 3.0), Vector2(r * 2.0, r * 3.0)), c)
	draw_line(Vector2(-r, -r * 2.0), Vector2(r, -r * 1.2), COLOR_ROPE, 2.0)
	var hand := Vector2(0, -r * 1.5) + facing * r
	match state:
		State.WINDUP:
			# Sword raised high: a different silhouette, plus the warning ring.
			draw_line(hand, hand + Vector2(0, -r * 2.2) - facing * r, COLOR_BLADE, 3.0)
			draw_arc(strike_center() - global_position, p("strike_half_width", 12), 0, TAU, 16, COLOR_WARN, 1.5)
		State.STRIKE:
			draw_line(hand, hand + facing * p("strike_reach", 26), COLOR_BLADE, 4.0)
		_:
			draw_line(hand, hand + facing * r * 1.4, COLOR_BLADE, 2.0)
