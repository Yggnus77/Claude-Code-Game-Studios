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
## A sword swing hit something that took the hit.
signal sword_landed

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
const SHEET_PATH := "res://assets/art/personagens/yggnus.png"
const SHEET_META := "res://assets/art/personagens/yggnus.json"

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
## Sheet drawn by tools/art/gerar_yggnus.py; null keeps the shape placeholder.
var _sheet: Texture2D
var _picker: SpritePicker
var _anim := "idle"
var _anim_t := 0.0
var _last_step := -1

@onready var camera: Camera2D = $Camera2D
@onready var feet: CollisionShape2D = $Feet


## Where the last attack on Yggnus came from, and what it was (names a
## death's cause in the playtest record).
var last_hit_from := Vector2.ZERO
var last_hit_by := ""


## Applies every tunable from [param config]. Call before adding to the tree.
func configure(config: GameConfig) -> void:
	var p := config.player()
	motor = PlayerMotor.new(p)
	var frame: Array = p.get("sprite_frame", [32, 48])
	sprite_frame = Vector2(frame[0], frame[1])
	var foot: Array = p.get("foot_collision", [12, 10])
	_pending_foot = Vector2(foot[0], foot[1])
	var buffer := float(p.get("input_buffer", 0.12))
	combo = SwordCombo.new(config.combo(), config.weapon_damage("espada_oficina"), buffer,
		float(p.get("combo_chain_reset", 0.38)), float(p.get("finisher_cancel", 0.10)))
	dodge = Dodge.new(config.dodge(), buffer)
	guard = Guard.new(config.guard())
	healing = Healing.new(config.data.get("healing", {}))
	hook = Hook.new(config.data.get("hook", {}))
	health = Health.new(config.starting_life(), float(p.get("damage_invulnerability", 0.75)))
	health.died.connect(_on_died)
	_hitstun_time = float(p.get("hitstun", 0.18))
	_knockback_px = float(p.get("knockback", 18))


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = _pending_foot
	feet.shape = rect
	feet.position = Vector2.ZERO
	if ResourceLoader.exists(SHEET_PATH):
		_sheet = load(SHEET_PATH)
		_picker = SpritePicker.load_meta(SHEET_META)
		# A soft light around Yggnus, so he reads even in the darkest corner.
		var glow := PointLight2D.new()
		glow.name = "Glow"
		glow.texture = Room.light_texture()
		glow.position = Vector2(0, -14)
		glow.color = Color(1.0, 0.92, 0.8)
		glow.energy = 0.45
		glow.texture_scale = 72.0 * 2.0 / 128.0
		add_child(glow)
	queue_redraw()


## Clamps the camera to the room so it never shows outside the map;
## [param top] lets it rise above row 0 to show the tall top wall.
func set_camera_limits(size_px: Vector2i, top: int = 0) -> void:
	camera.limit_left = 0
	camera.limit_top = -top
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


## Places Yggnus at [param pos] with every action timer cleared. Life is
## restored only when [param restore_life] is true (death, new game); a door
## keeps the life the player walked in with (mecanicas: only marcos heal).
func respawn_at(pos: Vector2, restore_life: bool = true) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_hitstun = 0.0
	combo.reset()
	dodge.reset()
	guard.reset()
	healing.reset()
	hook.reset()
	if restore_life:
		health.reset()
	else:
		health.tick(INF)  # clears hit invulnerability only
	reset_physics_interpolation()


## Applies the numbers a relic may change (RelicLoadout.params), always the
## full set rebuilt from the base, so nothing accumulates. Unknown keys are
## for systems not in this slice yet and are ignored.
func apply_relic_params(p: Dictionary) -> void:
	healing.startup = float(p.get("healing.startup", healing.startup))
	healing.recovery = float(p.get("healing.recovery", healing.recovery))
	hook.cooldown = float(p.get("hook.return_cooldown", hook.cooldown))
	guard.perfect_window = float(p.get("guard.perfect_window", guard.perfect_window))
	motor.speed = float(p.get("player.speed", motor.speed))
	_knockback_px = float(p.get("player.knockback_max", _knockback_px))


## Starts drinking a flask (or eating bread). False at full life, with
## nothing to use, or while busy.
func request_heal() -> bool:
	if healing == null or is_dead() or health.current >= health.maximum:
		return false
	if combo.is_busy() or dodge.is_dodging() or _hitstun > 0.0:
		return false
	if not healing.start(int(heal_source.call())):
		return false
	# Drinking takes both hands: the shield comes down (mecanicas §8).
	guard.set_held(false)
	return true


## Throws the hook where Yggnus faces. False while busy or cooling down.
func fire_hook() -> bool:
	if hook == null or is_dead() or combo.is_busy() or dodge.is_dodging() or _hitstun > 0.0 or healing.is_busy():
		return false
	if not hook.fire(motor.facing):
		return false
	guard.set_held(false)
	return true


## Pulls Yggnus along the latched cable to [param target] (a safe tile
## across a gap). Walls and gaps are ignored only during this pull.
func start_pull(target: Vector2) -> void:
	_pull_target = target
	hook.begin_pull()


## True while attacking, dodging, healing, hooking or stunned: story scenes wait for this to end.
func is_busy() -> bool:
	return combo.is_busy() or dodge.is_dodging() or _hitstun > 0.0 or (healing != null and healing.is_busy()) or (hook != null and hook.is_busy())


## True once life reaches zero, until the respawn.
func is_dead() -> bool:
	return health != null and health.is_dead()


## Called by enemies. [param from] is the attacker's position.
func receive_hit(damage: int, from: Vector2, heavy: bool = false, unblockable: bool = false, source: String = "") -> HitResolver.Outcome:
	last_hit_from = from
	last_hit_by = source
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
	_advance_anim(delta)
	health.tick(delta)
	dodge.tick(delta)
	guard.tick(delta)
	if not combo.is_busy():
		# Buffer and chain-reset clocks run while hooking, dodging, healing or
		# stunned, so a press is not kept forever (mecanicas §3).
		combo.tick_idle(delta)
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
			if enemy.receive_sword_hit(combo.damage(), combo.attack_id, global_position):
				sword_landed.emit()


func _on_died() -> void:
	combo.reset()
	died.emit()


## The animation that shows what Yggnus is doing now (sheet column names).
func current_anim() -> String:
	if is_dead():
		return "fall"
	if dodge and dodge.is_dodging():
		return "dodge"
	if _hitstun > 0.0:
		return "hurt"
	if combo and combo.is_busy():
		return ["slash1", "slash2", "slash3"][clampi(combo.stage, 0, 2)]
	if guard and guard.is_up():
		return "guard"
	if hook and hook.is_busy():
		return "tool"
	if velocity.length() > 4.0:
		return "walk"
	return "idle"


## Frame picked by the swing phase, so the pose matches the hit window.
func _swing_index() -> int:
	if combo.phase == SwordCombo.Phase.STARTUP:
		return 0
	if combo.stage >= 2 and combo.phase == SwordCombo.Phase.RECOVERY:
		return 2
	return 1


func _advance_anim(delta: float) -> void:
	var a := current_anim()
	if a != _anim:
		if a == "dodge" and _sheet:
			Fx.dust(get_parent(), global_position - Vector2(0, 1))
		_anim = a
		_anim_t = 0.0
	else:
		_anim_t += delta
	# A little dust at every other step (the walk cycle has 4 frames).
	if _anim == "walk" and _sheet:
		var step := int(_anim_t * 4.0)
		if step != _last_step:
			_last_step = step
			if step % 2 == 0:
				Fx.dust(get_parent(), global_position - Vector2(0, 1))
	else:
		_last_step = -1


func _draw() -> void:
	var w := sprite_frame.x
	var h := sprite_frame.y
	var invisible_blink := health != null and health.is_invulnerable() and int(Time.get_ticks_msec() / 60) % 2 == 0
	var alpha := 0.35 if invisible_blink or (dodge and dodge.is_dodging()) else 1.0
	var f := motor.facing if motor else Vector2.DOWN
	if combo and combo.is_busy():
		f = _swing_facing
	if _sheet and _picker:
		_draw_sheet(f, alpha)
	else:
		_draw_shapes(f, alpha, w, h)
	if is_dead():
		return
	if hook and hook.distance > 0.0:
		var tip := hook.tip(Vector2.ZERO) + Vector2(0, -8)
		draw_line(Vector2(0, -8), tip, Color("c9c2b0"), 1.0)
		draw_circle(tip, 2.5, Color("f2c14e"))
	if healing and healing.phase == Healing.Phase.USING:
		draw_arc(Vector2(0, -h - 4), 4.0, 0, TAU, 10, Color("e05a5a"), 2.0)
	if guard and guard.is_up():
		# The covered side, also when the shield itself is hidden (facing up).
		var perfect := guard.is_perfect() or _last_outcome_flash > 0.0
		var center := f * 10.0 + Vector2(0, -8)
		draw_arc(center, 12.0, f.angle() - guard.half_angle, f.angle() + guard.half_angle, 12, COLOR_PERFECT if perfect else Color(COLOR_SHIELD, 0.7), 2.0)
	if combo and combo.is_active():
		# The swing's trail covers the real hit box (sword_rect).
		var box := sword_rect()
		box.position -= global_position
		var c := box.get_center()
		var r := maxf(box.size.x, box.size.y) * 0.5
		var a := f.angle()
		# Drawn at chest height (the hit box itself sits at the feet).
		var o := c - f * r * 0.5 + Vector2(0, -10)
		# A crescent: wide faint glow, the bright edge, a white core.
		draw_arc(o, r - 1.5, a - 1.25, a + 1.25, 16, Color(0.7, 0.85, 1.0, 0.22), 6.0)
		draw_arc(o, r, a - 1.2, a + 1.2, 16, Color(COLOR_SWORD, 0.85), 3.0)
		draw_arc(o, r, a - 0.8, a + 0.8, 12, Color(1, 1, 1, 0.95), 1.0)
		draw_arc(o, r - 4.0, a - 0.9, a + 0.9, 12, Color(COLOR_SWORD, 0.3), 2.0)


func _draw_sheet(f: Vector2, alpha: float) -> void:
	var index := _swing_index() if combo and combo.is_busy() else -1
	var reg := _picker.region(_anim, _anim_t, f, index)
	var size := Vector2(_picker.frame_size)
	var at := -Vector2(_picker.pivot)
	if reg["flip"]:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
	draw_texture_rect_region(_sheet, Rect2(at, size), reg["rect"], Color(1, 1, 1, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The coloured shapes used before the art existed (and if the sheet is missing).
func _draw_shapes(f: Vector2, alpha: float, w: float, h: float) -> void:
	if is_dead():
		draw_rect(Rect2(Vector2(-w * 0.4, -6), Vector2(w * 0.8, 8)), Color(COLOR_CLOAK, 0.8))
		return
	draw_rect(Rect2(Vector2(-w * 0.3, -h * 0.75), Vector2(w * 0.6, h * 0.7)), Color(COLOR_CLOAK, alpha))
	draw_circle(Vector2(0, -h * 0.8), w * 0.22, Color(COLOR_BODY, alpha))
	draw_circle(Vector2(0, -h * 0.4) + f * w * 0.35, 3.0, COLOR_FACING)
	if guard and guard.is_up():
		var center := f * 10.0 + Vector2(0, -8)
		draw_arc(center, 10.0, f.angle() - guard.half_angle, f.angle() + guard.half_angle, 12, COLOR_SHIELD, 3.0)
