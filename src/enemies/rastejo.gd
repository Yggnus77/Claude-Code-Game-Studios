class_name Rastejo
extends CharacterBody2D
## Rastejo de Tinta: easy enemy that inflates, then charges in a straight line
## (design/kit/bestiario.csv; numbers in assets/data/inimigos.json).
## States follow mecanicas-e-dificuldade.md §10: idle → approach → telegraph
## (direction locks for the last [code]lock_direction_before[/code] s) →
## charge → recovery. Hurt interrupts; each sword swing hits it at most once.

signal defeated(enemy: Rastejo)

enum State { IDLE, APPROACH, TELEGRAPH, CHARGE, RECOVER, HURT, DEAD }

const COLOR_BODY := Color("7a55b0")
const COLOR_INK := Color("2a1838")
const COLOR_FLASH := Color("ffffff")
const COLOR_WARN := Color("f2c14e")

var params: Dictionary
var health: Health
## Node with `global_position` and `receive_hit(damage, from)`.
var target: Node2D
var state: State = State.IDLE
var charge_direction := Vector2.ZERO

var _timer := 0.0
var _hit_ids: Dictionary = {}
var _charge_has_hit := false
var _flash := 0.0
var _knockback := Vector2.ZERO


## Configure from an inimigos.json entry before adding to the tree.
func setup(definition: Dictionary, chase: Node2D) -> void:
	params = definition
	target = chase
	health = Health.new(int(params.get("hp", 2)))


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius()
	shape.shape = circle
	add_child(shape)


func body_radius() -> float:
	return float(params.get("body_radius", 7))


func _p(key: String, fallback: float) -> float:
	return float(params.get(key, fallback))


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	if state == State.DEAD or target == null:
		return
	var to_target := target.global_position - global_position
	var dist := to_target.length()
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if dist <= _p("perception_range", 112):
				state = State.APPROACH
		State.APPROACH:
			velocity = to_target.normalized() * _p("speed", 48)
			if dist <= _p("attack_range", 64):
				_enter(State.TELEGRAPH, _p("telegraph", 0.65))
				charge_direction = to_target.normalized()
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer > _p("lock_direction_before", 0.2) and dist > 0.0:
				charge_direction = to_target.normalized()
			if _timer <= 0.0:
				_charge_has_hit = false
				_enter(State.CHARGE, _p("charge_duration", 0.35))
		State.CHARGE:
			velocity = charge_direction * _p("charge_speed", 150)
			_timer -= delta
			if not _charge_has_hit and dist <= body_radius() + 6.0 and target.has_method("receive_hit"):
				_charge_has_hit = true
				target.receive_hit(int(params.get("damage", 1)), global_position)
			if _timer <= 0.0 or get_slide_collision_count() > 0:
				_enter(State.RECOVER, _p("recovery", 0.8))
		State.RECOVER:
			velocity = Vector2.ZERO
			_timer -= delta
			if _timer <= 0.0:
				state = State.APPROACH
		State.HURT:
			velocity = _knockback
			_timer -= delta
			if _timer <= 0.0:
				state = State.APPROACH
	move_and_slide()
	queue_redraw()


func _enter(next: State, seconds: float) -> void:
	state = next
	_timer = seconds


## Called by the player's sword. Returns true if the hit landed.
## The same [param attack_id] never damages twice.
func receive_sword_hit(damage: int, attack_id: int, from: Vector2) -> bool:
	if state == State.DEAD or _hit_ids.has(attack_id):
		return false
	_hit_ids[attack_id] = true
	health.take_damage(damage)
	_flash = 0.08
	if health.is_dead():
		state = State.DEAD
		velocity = Vector2.ZERO
		collision_layer = 0
		defeated.emit(self)
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
		return true
	var away := (global_position - from).normalized()
	var stun := _p("hitstun", 0.2)
	_knockback = away * (_p("knockback", 10) / stun)
	_enter(State.HURT, stun)
	return true


func _draw() -> void:
	var r := body_radius()
	var squash := 1.0
	if state == State.TELEGRAPH:
		# Inflates while preparing the charge: shape changes, not only colour.
		var t := 1.0 - clampf(_timer / _p("telegraph", 0.65), 0.0, 1.0)
		squash = 1.0 + 0.45 * t
		draw_arc(Vector2.ZERO, r * squash + 3.0, 0, TAU, 20, COLOR_WARN, 1.5)
		draw_line(Vector2.ZERO, charge_direction * (r + 10.0), COLOR_WARN, 2.0)
	var color := COLOR_FLASH if _flash > 0.0 else COLOR_BODY
	draw_circle(Vector2(0, -r * 0.4), r * squash, color)
	draw_circle(Vector2(0, -r * 0.4), r * squash * 0.55, COLOR_INK if _flash <= 0.0 else COLOR_FLASH)
