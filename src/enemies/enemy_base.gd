class_name EnemyBase
extends CharacterBody2D
## Shared enemy plumbing: data from inimigos.json, life, one-hit-per-swing,
## hurt knockback, hit flash, defeat. Subclasses implement [method _think]
## and [method _draw_body]; numbers always come from [member params].

signal defeated(enemy: EnemyBase)

const COLOR_FLASH := Color("ffffff")
const COLOR_WARN := Color("f2c14e")
const COLOR_BLOCK := Color("9fd8ff")

var params: Dictionary
var health: Health
## Node with `global_position` and `receive_hit(damage, from, heavy)`.
var target: Node2D
## True once life reaches zero.
var is_defeated := false

var _hit_ids: Dictionary = {}
var _flash := 0.0
var _block_flash := 0.0
var _hurt_left := 0.0
var _knockback := Vector2.ZERO


## Configure from an inimigos.json entry before adding to the tree.
func setup(definition: Dictionary, chase: Node2D) -> void:
	params = definition
	target = chase
	health = Health.new(int(params.get("hp", 1)))


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


## Radius used by the sword to reach this enemy.
func body_radius() -> float:
	return p("body_radius", 7)


## Numeric parameter [param key] from the enemy's data.
func p(key: String, fallback: float) -> float:
	return float(params.get(key, fallback))


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_block_flash = maxf(0.0, _block_flash - delta)
	if is_defeated or target == null:
		return
	if target.has_method("is_dead") and target.is_dead():
		# Nothing to fight during the respawn delay: stand still.
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if _hurt_left > 0.0:
		_hurt_left -= delta
		velocity = _knockback
	else:
		_think(delta)
	move_and_slide()
	queue_redraw()


## Per-step behaviour; set [code]velocity[/code]. Override.
func _think(_delta: float) -> void:
	velocity = Vector2.ZERO


## Whether a sword hit from [param from] is blocked. Override (e.g. shields).
func _blocks(_from: Vector2) -> bool:
	return false


## Whether the enemy can be hit at all right now (e.g. a flying moth). Override.
func _hittable() -> bool:
	return true


## Whether a landed hit interrupts the current action. Override.
func _flinches() -> bool:
	return true


## Called after a hit lands and the enemy survives. Override to reset state.
func _on_hurt() -> void:
	pass


## Called by the player's sword. Returns true if damage was applied.
## The same [param attack_id] never counts twice, blocked or not.
func receive_sword_hit(damage: int, attack_id: int, from: Vector2) -> bool:
	if is_defeated or _hit_ids.has(attack_id) or not _hittable():
		return false
	_hit_ids[attack_id] = true
	if _blocks(from):
		_block_flash = 0.12
		return false
	health.take_damage(damage)
	_flash = 0.08
	if health.is_dead():
		_defeat()
		return true
	if _flinches():
		var stun := maxf(p("hitstun", 0.2), 0.01)
		_hurt_left = stun
		_knockback = (global_position - from).normalized() * (p("knockback", 8) / stun)
		_on_hurt()
	return true


func _defeat() -> void:
	is_defeated = true
	velocity = Vector2.ZERO
	collision_layer = 0
	defeated.emit(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)


## Direction and distance to the target.
func to_target() -> Vector2:
	return target.global_position - global_position


## Hits the target if [param hit_center] is within [param radius] of its feet.
func try_hit_target(hit_center: Vector2, radius: float, damage: int, heavy: bool = false) -> bool:
	if target == null or not target.has_method("receive_hit"):
		return false
	if hit_center.distance_to(target.global_position) > radius + Player.FEET_RADIUS:
		return false
	target.receive_hit(damage, global_position, heavy, false, str(params.get("name", "inimigo")))
	return true


func _draw() -> void:
	_draw_body()
	if _block_flash > 0.0:
		draw_arc(Vector2(0, -body_radius() * 0.4), body_radius() + 5.0, 0, TAU, 16, COLOR_BLOCK, 2.0)


## Placeholder art. Override.
func _draw_body() -> void:
	draw_circle(Vector2.ZERO, body_radius(), COLOR_FLASH if _flash > 0.0 else Color.GRAY)
