class_name Mariposa
extends EnemyBase
## Mariposa de Papel: flies to a spot near the player, lands (telegraph),
## dives in a straight line, then rests on the ground (bestiario: "mergulho
## após pousar; defesa ou golpe no pouso"). Only hittable while landed.

enum State { IDLE, HOVER, LAND, DIVE, REST }

const COLOR_PAPER := Color("e9e1cf")
const COLOR_FOLD := Color("9b8f78")

var state: State = State.IDLE
var dive_direction := Vector2.ZERO
var _timer := 0.0
var _dive_has_hit := false


func _hittable() -> bool:
	return state == State.LAND or state == State.REST


func _think(delta: float) -> void:
	var to := to_target()
	var dist := to.length()
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist <= p("perception_range", 140):
				state = State.HOVER
		State.HOVER:
			var spot := target.global_position - to.normalized() * p("hover_distance", 72)
			var to_spot := spot - global_position
			velocity = to_spot.limit_length(1.0) * p("speed", 70) if to_spot.length() > 2.0 else Vector2.ZERO
			if to_spot.length() <= 6.0:
				_enter(State.LAND, p("telegraph", 0.6))
				dive_direction = to.normalized()
		State.LAND:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer > p("lock_direction_before", 0.2) and dist > 0.0:
				dive_direction = to.normalized()
			if _timer <= 0.0:
				_dive_has_hit = false
				_enter(State.DIVE, p("dive_duration", 0.4))
		State.DIVE:
			velocity = dive_direction * p("dive_speed", 190)
			_timer -= delta
			if not _dive_has_hit and try_hit_target(global_position, body_radius(), int(params.get("damage", 1))):
				_dive_has_hit = true
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				_enter(State.REST, p("recovery", 0.8))
		State.REST:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				state = State.HOVER


func _enter(next: State, seconds: float) -> void:
	state = next
	_timer = seconds


func _on_hurt() -> void:
	state = State.REST
	_timer = p("recovery", 0.8)


func _draw_body() -> void:
	var r := body_radius()
	var flying := state == State.HOVER or state == State.IDLE or state == State.DIVE
	var lift := -14.0 if flying and state != State.DIVE else -2.0
	if flying:
		# Shadow on the ground shows where it is while it flies.
		draw_circle(Vector2.ZERO, r * 0.7, Color(0, 0, 0, 0.35))
	var art := SpriteAtlas.enemies()
	if art:
		var frame := "mariposa_dive" if state == State.DIVE or state == State.LAND else "mariposa_fly%d" % (int(Time.get_ticks_msec() / 110) % 2)
		# The sheet draws the body at y 30; the pivot is the feet (y 44).
		art.draw(self, frame, Vector2(0, lift + 14.0), _flash > 0.0)
		if state == State.LAND:
			draw_arc(Vector2(0, lift), r + 6.0, 0, TAU, 16, COLOR_WARN, 1.5)
			draw_line(Vector2(0, lift), Vector2(0, lift) + dive_direction * (r + 12.0), COLOR_WARN, 2.0)
		return
	var flap := 1.0 if state != State.HOVER else 0.6 + 0.4 * absf(sin(Time.get_ticks_msec() / 90.0))
	var c := COLOR_FLASH if _flash > 0.0 else COLOR_PAPER
	var body := Vector2(0, lift)
	draw_colored_polygon(PackedVector2Array([body, body + Vector2(-r * 1.6, -r * flap), body + Vector2(-r * 1.2, r * 0.6)]), c)
	draw_colored_polygon(PackedVector2Array([body, body + Vector2(r * 1.6, -r * flap), body + Vector2(r * 1.2, r * 0.6)]), c)
	draw_line(body + Vector2(0, -r * 0.6), body + Vector2(0, r * 0.6), COLOR_FOLD, 2.0)
	if state == State.LAND:
		draw_arc(body, r + 6.0, 0, TAU, 16, COLOR_WARN, 1.5)
		draw_line(body, body + dive_direction * (r + 12.0), COLOR_WARN, 2.0)
