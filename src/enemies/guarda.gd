class_name Guarda
extends EnemyBase
## Guarda de Contrapeso: shield always turned to the player; walks up and
## slams its counterweight (heavy: breaks the player's guard). After the slam
## it stays turned the same way for [code]opening[/code] seconds (0.70 s), and
## hits from the sides or back land (auditoria item 1). The hook will later
## open it for [code]hook_opening[/code] seconds via [method expose].

enum State { IDLE, APPROACH, WINDUP, SLAM, OPENING }

const COLOR_BODY := Color("5f6b78")
const COLOR_SHIELD := Color("c9b27a")
const COLOR_WEIGHT := Color("3a3f47")

var state: State = State.IDLE
var facing := Vector2.DOWN
var _timer := 0.0
var _slam_has_hit := false


func _flinches() -> bool:
	return false


## True while the shield cannot be turned (after a slam, or opened by the hook).
func is_open() -> bool:
	return state == State.OPENING


## Opens the guard for [param seconds] (the hook); by default for its own
## [code]hook_opening[/code] from inimigos.json.
func expose(seconds: float = -1.0) -> void:
	_enter(State.OPENING, seconds if seconds > 0.0 else p("hook_opening", 1.2))


func _blocks(from: Vector2) -> bool:
	if not is_open():
		return true
	var to_attacker := from - global_position
	var half := deg_to_rad(p("shield_angle_degrees", 100) * 0.5)
	return absf(facing.angle_to(to_attacker)) <= half


func _turn_toward(dir: Vector2, delta: float) -> void:
	if dir == Vector2.ZERO:
		return
	var step := deg_to_rad(p("turn_speed_deg", 240)) * delta
	var a := facing.angle()
	facing = Vector2.from_angle(rotate_toward(a, dir.angle(), step))


func _think(delta: float) -> void:
	var to := to_target()
	var dist := to.length()
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			_turn_toward(to.normalized(), delta)
			if dist <= p("perception_range", 120):
				state = State.APPROACH
		State.APPROACH:
			_turn_toward(to.normalized(), delta)
			velocity = to.normalized() * p("speed", 40)
			if dist <= p("attack_range", 30):
				_enter(State.WINDUP, p("telegraph", 0.8))
		State.WINDUP:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer > 0.2:
				_turn_toward(to.normalized(), delta)
			if _timer <= 0.0:
				_slam_has_hit = false
				_enter(State.SLAM, p("slam_active", 0.12))
		State.SLAM:
			velocity = Vector2.ZERO
			_timer -= delta
			if not _slam_has_hit and try_hit_target(slam_center(), p("slam_radius", 22), int(params.get("damage", 2)), bool(params.get("slam_heavy", true))):
				_slam_has_hit = true
			if _timer <= 0.0:
				_enter(State.OPENING, p("opening", 0.7))
		State.OPENING:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				state = State.APPROACH


## Centre of the slam area, in global coordinates.
func slam_center() -> Vector2:
	return global_position + facing * p("slam_offset", 16)


func _enter(next: State, seconds: float) -> void:
	state = next
	_timer = seconds


func _draw_body() -> void:
	var r := body_radius()
	var art := SpriteAtlas.enemies()
	if art:
		var frame := "guarda_open" if is_open() else ("guarda_raise" if state == State.WINDUP else "guarda_idle")
		art.draw(self, frame, Vector2(0, 2), _flash > 0.0, facing.x > 0.0)
	else:
		var c := COLOR_FLASH if _flash > 0.0 else COLOR_BODY
		draw_rect(Rect2(Vector2(-r, -r * 2.6), Vector2(r * 2.0, r * 2.6)), c)
	var shield_c := COLOR_SHIELD if not is_open() else Color(COLOR_SHIELD, 0.35)
	var half := deg_to_rad(p("shield_angle_degrees", 100) * 0.5)
	draw_arc(Vector2(0, -r) + facing * (r * 0.4), r + 3.0, facing.angle() - half, facing.angle() + half, 12, shield_c, 4.0)
	match state:
		State.WINDUP:
			# Counterweight lifted overhead and the slam area marked on the floor.
			draw_rect(Rect2(Vector2(-r * 0.7, -r * 4.4), Vector2(r * 1.4, r * 1.2)), _weight_color(art))
			draw_arc(slam_center() - global_position, p("slam_radius", 22), 0, TAU, 24, COLOR_WARN, 1.5)
		State.SLAM:
			draw_circle(slam_center() - global_position, p("slam_radius", 22), Color(COLOR_WARN, 0.35))
		State.OPENING:
			draw_rect(Rect2(facing * p("slam_offset", 16) - Vector2(r * 0.7, r * 0.6), Vector2(r * 1.4, r * 1.2)), _weight_color(art))
			# The punish window: above the head, outlined, never on the sprite.
			var mark := Vector2(-3, -50) if art else Vector2(-3, -r * 3.0)
			# A dark badge behind it, so it reads on lamp-lit wood and gold alike.
			draw_circle(mark + Vector2(3, -5), 8.0, Color("1b1420", 0.85))
			draw_arc(mark + Vector2(3, -5), 8.0, 0, TAU, 16, COLOR_WARN, 1.0)
			draw_string_outline(ThemeDB.fallback_font, mark, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 4, Color("1b1420"))
			draw_string(ThemeDB.fallback_font, mark, "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COLOR_WARN)


## The counterweight block: brass beside the painted guard, grey otherwise.
func _weight_color(art: SpriteAtlas) -> Color:
	return Color("b8873a") if art else COLOR_WEIGHT


func _defeat_color() -> Color:
	return Color("b8873a")
