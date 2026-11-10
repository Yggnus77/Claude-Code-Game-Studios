class_name Player
extends CharacterBody2D
## Yggnus: walking plus the classic combat of design/gdd/jogabilidade-classica.md
## — a wide sword swing, the charged spin, the passive shield, life, damage,
## invulnerability and knockback. The dodge waits for a later item.
## The rules live in pure classes ([PlayerMotor], [SwordSwing], [Dodge],
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
## Where the drawn blade turns, above the feet (chest height).
const BLADE_PIVOT := Vector2(0, -12)
const COLOR_BLADE_EDGE := Color("8f99a6")
const COLOR_HILT := Color("d9ad4f")
const COLOR_GRIP := Color("7d4d31")
const COLOR_OUTLINE := Color("1b1420")
## Radius of the feet used when enemies check contact.
const FEET_RADIUS := 6.0
const SHEET_PATH := "res://assets/art/personagens/yggnus.png"
const SHEET_META := "res://assets/art/personagens/yggnus.json"

var motor: PlayerMotor
var sword: SwordSwing
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
## Sword button held, used when [member read_input] is false (charging).
var attack_held_override := false
## False until the sword is in the inventory: a new game starts unarmed
## (plano-implementacao.md Etapa 4); attack presses are ignored.
var has_sword := true
## False until the shield is in the inventory: no passive guard.
var has_shield := true
## False until an item gives the dash: the dodge button does nothing
## (jogabilidade-classica.md §1).
var has_dodge := false

var _hitstun := 0.0
## Seconds left drawing the bow (or another tool's start): busy meanwhile.
var _tool_lock := 0.0
## The soft light around Yggnus, as it is outside dark rooms.
const GLOW_RADIUS := 72.0
const GLOW_ENERGY := 0.45
var _hitstun_time := 0.18
var _knockback_px := 18.0
var _knockback := Vector2.ZERO
var _swing_facing := Vector2.DOWN
var _pending_foot := Vector2(12, 10)
var _last_outcome_flash := 0.0
## Seconds left of the flash when the charge fills.
var _charged_flash := 0.0
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
	sword = SwordSwing.new(config.sword(), config.weapon_damage("espada_oficina"), buffer)
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
		glow.energy = GLOW_ENERGY
		glow.texture_scale = GLOW_RADIUS * 2.0 / 128.0
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
	if sword and has_sword and _tool_lock <= 0.0:
		sword.press()


## Queues a dodge press (same as the dodge action); nothing until an item
## gives the dash ([member has_dodge]).
func request_dodge() -> void:
	if dodge and has_dodge and _tool_lock <= 0.0:
		dodge.request()


## Places Yggnus at [param pos] with every action timer cleared. Life is
## restored only when [param restore_life] is true (death, new game); a door
## keeps the life the player walked in with (mecanicas: only marcos heal).
func respawn_at(pos: Vector2, restore_life: bool = true) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_hitstun = 0.0
	_tool_lock = 0.0
	sword.reset()
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
	if sword.is_busy() or dodge.is_dodging() or _hitstun > 0.0:
		return false
	if not healing.start(int(heal_source.call())):
		return false
	# Drinking takes both hands: the shield comes down (mecanicas §8).
	guard.set_held(false)
	return true


## Throws the hook where Yggnus faces. False while busy or cooling down.
func fire_hook() -> bool:
	if hook == null or is_dead() or sword.is_busy() or dodge.is_dodging() or _hitstun > 0.0 or healing.is_busy() or _tool_lock > 0.0:
		return false
	if not hook.fire(motor.facing):
		return false
	guard.set_held(false)
	return true


## Readies a tool on the item button (bow, charge, lamp): false while
## attacking, dodging, healing, hooking, stunned or dead. Using a tool
## lowers the shield, as the hook does, and keeps Yggnus busy for
## [param lock] seconds (the bow's draw).
func ready_tool(lock: float = 0.0) -> bool:
	if is_dead() or is_busy():
		return false
	guard.set_held(false)
	_tool_lock = maxf(0.0, lock)
	return true


## Size and strength of the soft light around Yggnus (the lamp widens it
## in dark rooms). No effect without the sprite sheet (no glow then).
func set_glow(radius: float, energy: float) -> void:
	var glow := get_node_or_null("Glow") as PointLight2D
	if glow:
		glow.texture_scale = radius * 2.0 / 128.0
		glow.energy = energy


## Pulls Yggnus along the latched cable to [param target] (a safe tile
## across a gap). Walls and gaps are ignored only during this pull.
func start_pull(target: Vector2) -> void:
	_pull_target = target
	hook.begin_pull()


## True while attacking, dodging, healing, hooking or stunned: story scenes wait for this to end.
func is_busy() -> bool:
	return sword.is_busy() or dodge.is_dodging() or _hitstun > 0.0 or _tool_lock > 0.0 or (healing != null and healing.is_busy()) or (hook != null and hook.is_busy())


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
	sword.cancel()
	healing.interrupt()
	if hook.phase != Hook.Phase.PULL:
		hook.cancel()
	_hitstun = seconds
	var away := (global_position - from).normalized()
	if away == Vector2.ZERO:
		away = -motor.facing
	# Knockback distance comes from combate.json; walls shorten it.
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
	_tool_lock = maxf(0.0, _tool_lock - delta)
	guard.tick(delta)
	# The press buffer ages while hooking, dodging, healing or stunned, so a
	# press is not kept forever.
	sword.tick_idle(delta)
	_last_outcome_flash = maxf(0.0, _last_outcome_flash - delta)
	_charged_flash = maxf(0.0, _charged_flash - delta)
	if is_dead():
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var input := input_override
	var attack_held := attack_held_override
	if read_input:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		attack_held = Input.is_action_pressed("attack")
	sword.set_held(attack_held and has_sword)

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
	# The dash (a later item) cancels the sword.
	if dodge.wants_to_start() and not sword.is_swinging():
		sword.cancel()
		guard.set_held(false)
		dodge.start(input if input != Vector2.ZERO else motor.facing)
	if dodge.is_dodging():
		velocity = dodge.velocity()
		move_and_slide()
		queue_redraw()
		return

	var event := sword.tick(delta)
	if event == "swing":
		_swing_facing = motor.facing
	elif event == "spin":
		Fx.dust(get_parent(), global_position - Vector2(0, 1))
	elif event == "charged":
		_charged_flash = 0.18
	if sword.is_swinging():
		if sword.in_startup() and input != Vector2.ZERO:
			# The blade can still be aimed during the startup.
			motor.step(Vector2.ZERO, input, delta)
			_swing_facing = motor.facing
		velocity = velocity.move_toward(Vector2.ZERO, motor.deceleration * delta)
	elif sword.is_charging():
		# Charging: slow, and Yggnus keeps facing where the blade points.
		velocity = motor.step(velocity, input, delta, sword.charge_speed_factor)
		motor.facing = _swing_facing
	else:
		velocity = motor.step(velocity, input, delta)
	# The shield is passive: up whenever Yggnus is free (§3.3).
	guard.set_held(has_shield and not sword.is_busy() and _tool_lock <= 0.0)
	move_and_slide()
	if sword.is_cutting():
		_apply_sword_hits()
	queue_redraw()


## Whether the blade's last sweep touches a target of [param radius] at
## [param point] (global coordinates).
func sword_touches(point: Vector2, radius: float) -> bool:
	if not sword.is_cutting():
		return false
	var arc := sword.sweep()
	return SwordSwing.sweep_hits(global_position + sword.hit_pivot, _swing_facing.angle(), arc.x, arc.y,
		sword.blade_inner, sword.current_reach(), point, radius)


func _apply_sword_hits() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.has_method("receive_sword_hit"):
			continue
		var r: float = enemy.body_radius() if enemy.has_method("body_radius") else 6.0
		if sword_touches(enemy.global_position, r):
			if enemy.receive_sword_hit(sword.damage(), sword.attack_id, global_position):
				sword_landed.emit()
	# Bushes and pots in reach break too (exploração §2).
	for b in get_tree().get_nodes_in_group("breakables"):
		if sword_touches(b.global_position, b.body_radius()):
			b.receive_sword_hit(sword.damage(), sword.attack_id, global_position)


func _on_died() -> void:
	sword.reset()
	died.emit()


## The animation that shows what Yggnus is doing now (sheet column names).
func current_anim() -> String:
	if is_dead():
		return "fall"
	if dodge and dodge.is_dodging():
		return "dodge"
	if _hitstun > 0.0:
		return "hurt"
	if sword and sword.is_charging():
		return "hold"
	if sword and sword.is_swinging():
		return "swing"
	if hook and hook.is_busy():
		return "tool"
	if velocity.length() > 4.0:
		return "walk"
	return "idle"


## Frame picked by the swing phase: arm raised in the startup, out after.
func _swing_index() -> int:
	return 0 if sword.in_startup() else 1


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
	var blade := sword != null and sword.is_busy() and not sword.in_startup() and not is_dead()
	var blade_dir := Vector2.from_angle(_swing_facing.angle() + sword.angle()) if blade else Vector2.ZERO
	if sword and sword.is_busy():
		f = _swing_facing
		if sword.phase == SwordSwing.Phase.SPIN:
			f = _cardinal(blade_dir)
	# A blade pointing up is behind Yggnus.
	var behind := blade and blade_dir.y < -0.35
	if behind:
		_draw_blade(blade_dir, alpha)
	if _sheet and _picker:
		_draw_sheet(f, alpha)
	else:
		_draw_shapes(f, alpha, w, h)
	if blade and not behind:
		_draw_blade(blade_dir, alpha)
	if is_dead():
		return
	if hook and hook.distance > 0.0:
		var tip := hook.tip(Vector2.ZERO) + Vector2(0, -8)
		draw_line(Vector2(0, -8), tip, Color("c9c2b0"), 1.0)
		draw_circle(tip, 2.5, Color("f2c14e"))
	if healing and healing.phase == Healing.Phase.USING:
		draw_arc(Vector2(0, -h - 4), 4.0, 0, TAU, 10, Color("e05a5a"), 2.0)
	if _last_outcome_flash > 0.0:
		# A blocked hit: a spark on the shield side.
		var center := f * 10.0 + Vector2(0, -12)
		draw_arc(center, 9.0, f.angle() - 0.9, f.angle() + 0.9, 10, COLOR_PERFECT, 2.0)


## The nearest of the four directions to [param v].
static func _cardinal(v: Vector2) -> Vector2:
	if absf(v.x) > absf(v.y):
		return Vector2.RIGHT if v.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if v.y > 0.0 else Vector2.UP


## The sword, big and bright, with the swept trail behind it
## (jogabilidade-classica.md §1). [param d] is the blade direction.
func _draw_blade(d: Vector2, alpha: float) -> void:
	var o := BLADE_PIVOT
	var spin := sword.phase == SwordSwing.Phase.SPIN
	var length := sword.current_reach() - 4.0
	var a := d.angle()
	# Trail: a fan behind the blade, fading toward where it started.
	var span := 0.0
	if spin:
		span = minf(sword.angle(), 2.6)
	elif sword.phase == SwordSwing.Phase.SWING:
		span = minf(sword.angle() - sword.arc_from, 1.9)
	if span > 0.05:
		var steps := 10
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var edge := PackedVector2Array()
		for i in steps + 1:
			var t := float(i) / steps
			var ang := a - span * (1.0 - t)
			pts.append(o + Vector2.from_angle(ang) * (length + 2.0))
			cols.append(Color(1.0, 1.0, 1.0, 0.7 * t * t * alpha))
			edge.append(o + Vector2.from_angle(ang) * (length + 1.0))
		for i in range(steps, -1, -1):
			var t := float(i) / steps
			var ang := a - span * (1.0 - t)
			pts.append(o + Vector2.from_angle(ang) * (length * 0.55))
			cols.append(Color(0.6, 0.85, 1.0, 0.0))
		draw_polygon(pts, cols)
		# A bright edge where the tip passed.
		for i in range(1, edge.size()):
			var t := float(i) / steps
			draw_line(edge[i - 1], edge[i], Color(1, 1, 1, 0.9 * t * alpha), 1.5)
	var n := d.orthogonal()
	var base := o + d * 6.0
	var tip := o + d * length
	var near_tip := o + d * (length - 4.0)
	var body := PackedVector2Array([base + n * 1.8, near_tip + n * 1.8, tip, near_tip - n * 1.8, base - n * 1.8])
	var rim := PackedVector2Array([base + n * 2.8 - d, near_tip + n * 2.8, tip + d * 1.4, near_tip - n * 2.8, base - n * 2.8 - d])
	draw_colored_polygon(rim, Color(COLOR_OUTLINE, alpha))
	draw_colored_polygon(body, Color(COLOR_SWORD, alpha))
	draw_line(base - n * 1.2, near_tip - n * 1.2, Color(COLOR_BLADE_EDGE, alpha), 1.0)
	draw_line(base + d + n * 0.5, near_tip - d * 2.0 + n * 0.5, Color(1, 1, 1, alpha), 1.0)
	# Guard, grip and pommel.
	draw_line(o + d * 1.0, o + d * 5.0, Color(COLOR_OUTLINE, alpha), 3.5)
	draw_line(o + d * 1.5, o + d * 4.5, Color(COLOR_GRIP, alpha), 2.0)
	draw_line(o + d * 5.5 + n * 4.5, o + d * 5.5 - n * 4.5, Color(COLOR_OUTLINE, alpha), 3.5)
	draw_line(o + d * 5.5 + n * 3.5, o + d * 5.5 - n * 3.5, Color(COLOR_HILT, alpha), 2.0)
	draw_circle(o + d * 0.5, 1.6, Color(COLOR_HILT, alpha))
	if sword.is_charging():
		# The tip gathers light while charging and shines when full.
		var k := clampf(sword.charge / maxf(sword.charge_time, 0.01), 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.03)
		if sword.is_charged():
			var r := 3.5 + 1.5 * pulse + _charged_flash * 12.0
			draw_line(tip - d * r, tip + d * r, Color(1, 1, 1, 0.9), 1.5)
			draw_line(tip - n * r, tip + n * r, Color(1, 1, 1, 0.9), 1.5)
			draw_circle(tip, 2.2, Color("bff4ff"))
		else:
			draw_circle(tip, 0.8 + 1.4 * k, Color(1, 1, 1, 0.4 + 0.5 * k))


func _draw_sheet(f: Vector2, alpha: float) -> void:
	var index := _swing_index() if sword and sword.is_swinging() else -1
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
