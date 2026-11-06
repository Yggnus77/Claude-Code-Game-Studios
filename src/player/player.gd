class_name Player
extends CharacterBody2D
## Yggnus: walking (step 1) plus the minimal combat of step 2 — sword combo,
## dodge, guard, life, damage, invulnerability and knockback.
## The rules live in pure classes ([PlayerMotor], [SwordCombo], [Dodge],
## [Guard], [Health], [HitResolver]); this node feeds them input and applies
## the result in the physics step only.

signal hit_taken(outcome: HitResolver.Outcome)
signal died
## The hook's tip touched something: {"type": "wall" | "anchor" | "enemy" | ...}.
signal hook_hit(result: Dictionary)
## The item button was pressed; the owner decides what the equipped item does.
signal item_pressed

const COLOR_BODY := Color("e8d9b5")
const COLOR_CLOAK := Color("3d6fa8")
const COLOR_FACING := Color("f2c14e")
const COLOR_SWORD := Color("dfe6ee")
const COLOR_SHIELD := Color("c98b3a")
const COLOR_PERFECT := Color("7ee0ff")
## Half width of the sword hit box, across the swing direction.
const SWORD_HALF_WIDTH := 12.0
## Distance from the feet to where the blade starts.
const SWORD_OFFSET := 2.0
## Radius of the feet used when enemies check contact.
const FEET_RADIUS := 6.0

var motor: PlayerMotor
var combo: SwordCombo
var dodge: Dodge
var guard: Guard
var health: Health
var healing: Healing
var hook: Hook
## Returns what is at a world position for the hook's tip ({} = nothing).
var hook_probe: Callable = func(_pos: Vector2) -> Dictionary: return {}
## Returns the life the best healing item would restore now (0 = none).
var heal_source: Callable = func() -> int: return 0
## Consumes that item at the effect frame; false if it is gone.
var heal_commit: Callable = func() -> bool: return false
## Size of the drawn placeholder sprite (combate.json player.sprite_frame).
var sprite_frame := Vector2(32, 48)
## When false the node ignores the input map; tests drive the fields below.
var read_input := true
## Movement input used when [member read_input] is false.
var input_override := Vector2.ZERO
## Guard button state used when [member read_input] is false.
var guard_override := false
## False until the sword is in the inventory: a new game starts unarmed
## (plano-implementacao.md Etapa 4); attack presses are ignored.
var has_sword := true
## False until the shield is in the inventory: the guard button does nothing.
var has_shield := true

var _hitstun := 0.0
var _hitstun_time := 0.18
var _knockback_px := 18.0
var _knockback := Vector2.ZERO
var _swing_facing := Vector2.DOWN
var _pending_foot := Vector2(12, 10)
var _last_outcome_flash := 0.0
var _pull_target := Vector2.ZERO

@onready var camera: Camera2D = $Camera2D
@onready var feet: CollisionShape2D = $Feet


## Applies every tunable from [param config]. Call before adding to the tree.
func configure(config: GameConfig) -> void:
	var p := config.player()
	motor = PlayerMotor.new(p)
	var frame: Array = p.get("sprite_frame", [32, 48])
	sprite_frame = Vector2(frame[0], frame[1])
	var foot: Array = p.get("foot_collision", [12, 10])
	_pending_foot = Vector2(foot[0], foot[1])
	var buffer := float(p.get("input_buffer", 0.12))
	combo = SwordCombo.new(config.combo(), config.weapon_damage("espada_oficina"), buffer)
	dodge = Dodge.new(config.dodge(), buffer)
	guard = Guard.new(config.guard())
	healing = Healing.new(config.data.get("healing", {}))
	hook = Hook.new(config.data.get("hook", {}))
	health = Health.new(config.starting_life(), float(p.get("damage_invulnerability", 0.75)))
	health.died.connect(_on_died)
	_hitstun_time = float(p.get("hitstun", 0.18))


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = _pending_foot
	feet.shape = rect
	feet.position = Vector2.ZERO
	queue_redraw()


## Clamps the camera to the room so it never shows outside the map.
func set_camera_limits(size_px: Vector2i) -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = size_px.x
	camera.limit_bottom = size_px.y
	camera.reset_smoothing()
	reset_physics_interpolation()


## Queues a sword press (same as the attack action).
func request_attack() -> void:
	if combo and has_sword:
		combo.request()


## Queues a dodge press (same as the dodge action).
func request_dodge() -> void:
	if dodge:
		dodge.request()


## Full life, no timers (respawn at a checkpoint).
func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_hitstun = 0.0
	combo.reset()
	dodge.reset()
	guard.reset()
	healing.reset()
	hook.reset()
	health.reset()
	reset_physics_interpolation()


## Starts drinking a flask (or eating bread). False at full life, with
## nothing to use, or while busy.
func request_heal() -> bool:
	if healing == null or is_dead() or health.current >= health.maximum:
		return false
	if combo.is_busy() or dodge.is_dodging() or _hitstun > 0.0:
		return false
	return healing.start(int(heal_source.call()))


## Throws the hook where Yggnus faces. False while busy or cooling down.
func fire_hook() -> bool:
	if hook == null or is_dead() or combo.is_busy() or dodge.is_dodging() or _hitstun > 0.0 or healing.is_busy():
		return false
	return hook.fire(motor.facing)


## Pulls Yggnus along the latched cable to [param target] (a safe tile
## across a gap). Walls and gaps are ignored only during this pull.
func start_pull(target: Vector2) -> void:
	_pull_target = target
	hook.begin_pull()


## True while attacking, dodging, healing, hooking or stunned: story scenes wait for this to end.
func is_busy() -> bool:
	return combo.is_busy() or dodge.is_dodging() or _hitstun > 0.0 or (healing != null and healing.is_busy()) or (hook != null and hook.is_busy())


func is_dead() -> bool:
	return health != null and health.is_dead()


## Called by enemies. [param from] is the attacker's position.
func receive_hit(damage: int, from: Vector2, heavy: bool = false, unblockable: bool = false) -> HitResolver.Outcome:
	if hook.phase == Hook.Phase.PULL:
		# Crossing on the cable: nothing interrupts the pull over a gap.
		return HitResolver.Outcome.IGNORED
	var outcome := HitResolver.resolve(health, dodge, guard, motor.facing, from - global_position, damage, heavy, unblockable)
	match outcome:
		HitResolver.Outcome.HIT:
			_start_hitstun(from, _hitstun_time)
		HitResolver.Outcome.GUARD_BREAK:
			_start_hitstun(from, guard.break_time)
		HitResolver.Outcome.BLOCKED, HitResolver.Outcome.PERFECT_BLOCK:
			_last_outcome_flash = 0.12
	hit_taken.emit(outcome)
	return outcome


func _start_hitstun(from: Vector2, seconds: float) -> void:
	combo.cancel()
	healing.interrupt()
	if hook.phase != Hook.Phase.PULL:
		hook.cancel()
	_hitstun = seconds
	var away := (global_position - from).normalized()
	if away == Vector2.ZERO:
		away = -motor.facing
	# Knockback distance comes from the design (≤ 18 px); walls shorten it.
	_knockback = away * (_knockback_px / maxf(seconds, 0.01))


func _unhandled_input(event: InputEvent) -> void:
	if not read_input or is_dead():
		return
	if event.is_action_pressed("attack") and not healing.is_busy():
		request_attack()
	elif event.is_action_pressed("item"):
		item_pressed.emit()
	elif event.is_action_pressed("dodge"):
		request_dodge()


func _physics_process(delta: float) -> void:
	if motor == null:
		return
	health.tick(delta)
	dodge.tick(delta)
	guard.tick(delta)
	_last_outcome_flash = maxf(0.0, _last_outcome_flash - delta)
	if is_dead():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var input := input_override
	var guard_pressed := guard_override
	if read_input:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		guard_pressed = Input.is_action_pressed("guard")

	if _hitstun > 0.0:
		_hitstun -= delta
		velocity = _knockback if _hitstun > 0.0 else Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return

	if hook.phase == Hook.Phase.PULL:
		var step := hook.tip_speed * delta
		if global_position.distance_to(_pull_target) <= step:
			global_position = _pull_target
			hook.end_pull()
		else:
			global_position += (_pull_target - global_position).normalized() * step
			hook.distance = global_position.distance_to(_pull_target)
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var hook_result := hook.tick(delta, global_position, hook_probe)
	if not hook_result.is_empty():
		hook_hit.emit(hook_result)
	if hook.is_busy():
		velocity = motor.step(velocity, input, delta, hook.speed_factor)
		move_and_slide()
		queue_redraw()
		return
	if healing.is_busy():
		var restored := healing.tick(delta)
		if restored > 0 and heal_commit.call():
			health.heal(restored)
		if healing.is_busy() and not dodge.wants_to_start():
			velocity = motor.step(velocity, input, delta, healing.speed_factor())
			move_and_slide()
			queue_redraw()
			return
		healing.interrupt()
	# Priority: dodge > guard > attack > movement (mecanicas §3).
	if dodge.wants_to_start() and combo.can_cancel():
		combo.cancel()
		guard.set_held(false)
		dodge.start(input if input != Vector2.ZERO else motor.facing)
	if dodge.is_dodging():
		velocity = dodge.velocity()
		move_and_slide()
		queue_redraw()
		return

	guard.set_held(guard_pressed and has_shield and not combo.is_busy())
	if guard.is_up():
		combo.reset()
		velocity = motor.step(velocity, input, delta, guard.speed_factor)
	else:
		combo.tick(delta)
		if combo.is_busy():
			if combo.phase == SwordCombo.Phase.STARTUP and input != Vector2.ZERO:
				# The blade can still be aimed during the startup.
				motor.step(Vector2.ZERO, input, delta)
			if combo.phase == SwordCombo.Phase.STARTUP or _swing_facing == Vector2.ZERO:
				_swing_facing = motor.facing
			velocity = velocity.move_toward(Vector2.ZERO, motor.deceleration * delta)
		else:
			velocity = motor.step(velocity, input, delta)
	move_and_slide()
	if combo.is_active():
		_apply_sword_hits()
	queue_redraw()


## Hit box of the swing in progress, in global coordinates.
func sword_rect() -> Rect2:
	var reach := combo.reach()
	var f := _swing_facing
	var along := f * (SWORD_OFFSET + reach * 0.5)
	var size := Vector2(absf(f.x) * reach + absf(f.y) * SWORD_HALF_WIDTH * 2.0, absf(f.y) * reach + absf(f.x) * SWORD_HALF_WIDTH * 2.0)
	return Rect2(global_position + along - size * 0.5, size)


func _apply_sword_hits() -> void:
	var box := sword_rect()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("receive_sword_hit"):
			continue
		var r: float = enemy.body_radius() if enemy.has_method("body_radius") else 6.0
		var closest := Vector2(clampf(enemy.global_position.x, box.position.x, box.end.x), clampf(enemy.global_position.y, box.position.y, box.end.y))
		if closest.distance_to(enemy.global_position) <= r:
			enemy.receive_sword_hit(combo.damage(), combo.attack_id, global_position)


func _on_died() -> void:
	combo.reset()
	died.emit()


func _draw() -> void:
	var w := sprite_frame.x
	var h := sprite_frame.y
	var invisible_blink := health != null and health.is_invulnerable() and int(Time.get_ticks_msec() / 60) % 2 == 0
	var alpha := 0.35 if invisible_blink or (dodge and dodge.is_dodging()) else 1.0
	if is_dead():
		draw_rect(Rect2(Vector2(-w * 0.4, -6), Vector2(w * 0.8, 8)), Color(COLOR_CLOAK, 0.8))
		return
	draw_rect(Rect2(Vector2(-w * 0.3, -h * 0.75), Vector2(w * 0.6, h * 0.7)), Color(COLOR_CLOAK, alpha))
	draw_circle(Vector2(0, -h * 0.8), w * 0.22, Color(COLOR_BODY, alpha))
	var f := motor.facing if motor else Vector2.DOWN
	draw_circle(Vector2(0, -h * 0.4) + f * w * 0.35, 3.0, COLOR_FACING)
	if hook and hook.distance > 0.0:
		var tip := hook.tip(Vector2.ZERO) + Vector2(0, -8)
		draw_line(Vector2(0, -8), tip, Color("c9c2b0"), 1.0)
		draw_circle(tip, 2.5, Color("f2c14e"))
	if healing and healing.phase == Healing.Phase.USING:
		draw_arc(Vector2(0, -h - 4), 4.0, 0, TAU, 10, Color("e05a5a"), 2.0)
	if guard and guard.is_up():
		var c := COLOR_PERFECT if guard.is_perfect() or _last_outcome_flash > 0.0 else COLOR_SHIELD
		var center := f * 10.0 + Vector2(0, -8)
		draw_arc(center, 10.0, f.angle() - guard.half_angle, f.angle() + guard.half_angle, 12, c, 3.0)
	if combo and combo.is_busy():
		var box := sword_rect()
		box.position -= global_position
		var col := COLOR_SWORD if combo.is_active() else Color(COLOR_SWORD, 0.3)
		if combo.is_active():
			draw_rect(box, col)
		else:
			draw_rect(box, col, false, 1.0)
