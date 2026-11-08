class_name Igris
extends StaticBody2D
## Igris, the tower operator bound to the bells (Etapa 7). Shows and applies
## what [IgrisFight] reports: announced waves under Yggnus, the chest muffler
## the hook can release, and the regulator the sword must hit. Ordinary hits
## only clang. Placeholder art.

## The muffler opened for the first time this attempt (hint bark).
signal muffler_opened
## Both cycles done: the outside control is broken.
signal control_broken

const COLOR_BODY := Color("4b5a6b")
const COLOR_HEAD := Color("b89a5a")
const COLOR_MUFFLER := Color("2a2a30")
const COLOR_REGULATOR := Color("7ee0ff")
const COLOR_WAVE := Color("e05a5a")

var fight: IgrisFight
var target: Node2D
var wiring: Dictionary
## False until the opening scene has been read (the fight waits for it).
var active := false
## Always false: Igris is freed, never defeated (kept for the sword/hook code).
var is_defeated := false

var _wave_center := Vector2.ZERO
var _wave_time := 0.0
var _wave_flash := 0.0
var _wave_mark: Node2D
var _wave_light: PointLight2D
var _hit_ids: Dictionary = {}
var _flash := 0.0
var _clang := 0.0
var _muffler_told := false


## Configure before adding to the tree.
func setup(rules: IgrisFight, player: Node2D, igris_wiring: Dictionary) -> void:
	fight = rules
	target = player
	wiring = igris_wiring


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = body_radius()
	shape.shape = circle
	add_child(shape)
	# The wave warning is drawn on its own node above everyone (it centres on
	# Yggnus, so his sprite must not hide it), with a red light under it.
	_wave_mark = WaveMark.new()
	_wave_mark.igris = self
	_wave_mark.z_index = 1
	add_child(_wave_mark)
	_wave_light = PointLight2D.new()
	_wave_light.texture = Room.light_texture()
	_wave_light.color = COLOR_WAVE
	_wave_light.texture_scale = 0.9
	_wave_light.visible = false
	add_child(_wave_light)


## Radius used by the sword and hook to reach Igris.
func body_radius() -> float:
	return float(wiring.get("body_radius", 14))


## The hook touched Igris. Releases the muffler when it is open.
func hook_muffler() -> bool:
	if not active:
		return false
	var ok := fight.hook_muffler()
	if ok:
		_flash = 0.2
	return ok


## Sword hit: counts on the open regulator; otherwise it only clangs.
func receive_sword_hit(_damage: int, attack_id: int, from: Vector2) -> bool:
	if not active or _hit_ids.has(attack_id):
		return false
	_hit_ids[attack_id] = true
	var landed := fight.hit_regulator()
	Fx.hit_sparks(get_parent(), global_position, from, not landed)
	if landed:
		_flash = 0.15
		if fight.is_done():
			active = false
			control_broken.emit()
		return true
	_clang = 0.15
	return false


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_clang = maxf(0.0, _clang - delta)
	_wave_flash = maxf(0.0, _wave_flash - delta)
	_wave_time = maxf(0.0, _wave_time - delta)
	if active and target and not (target.has_method("is_dead") and target.is_dead()):
		for event: String in fight.tick(delta):
			match event:
				"wave_announce":
					_wave_center = target.global_position
					_wave_time = fight.telegraph()
				"wave_strike":
					_wave_time = 0.0
					_wave_flash = 0.15
					if target.global_position.distance_to(_wave_center) <= float(wiring.get("wave_radius", 26)):
						# Ground wave: the shield does not stop it; a dodge does.
						target.receive_hit(int(wiring.get("wave_damage", 1)), _wave_center, false, true, "onda de Igris")
				"muffler_open":
					if not _muffler_told:
						_muffler_told = true
						muffler_opened.emit()
	queue_redraw()


## Waves: the danger zone is marked at full size and a second ring closes
## in on it; the strike lands when the two meet, then the zone flashes.
## Drawn by [WaveMark] on [param item] so it sits above the player.
func draw_wave(item: CanvasItem) -> void:
	var r := float(wiring.get("wave_radius", 26))
	if fight and fight.wave_announced and _wave_time > 0.0:
		var c := to_local(_wave_center)
		var left := clampf(_wave_time / maxf(fight.telegraph(), 0.01), 0.0, 1.0)
		var pulse := 0.5 + 0.5 * sin(_wave_time * 18.0)
		item.draw_circle(c, r, Color(COLOR_WAVE, 0.22 + 0.1 * pulse))
		item.draw_arc(c, r, 0, TAU, 32, Color("1b1420"), 5.0)
		item.draw_arc(c, r, 0, TAU, 32, Color("ff8a6a"), 3.0)
		item.draw_arc(c, r * (1.0 + 2.0 * left), 0, TAU, 40, Color("1b1420", 0.8), 4.0)
		item.draw_arc(c, r * (1.0 + 2.0 * left), 0, TAU, 40, Color(COLOR_WAVE, 0.95), 2.0)
	if _wave_flash > 0.0:
		item.draw_circle(to_local(_wave_center), r, Color("ffb090", 0.65))


func _draw() -> void:
	if _wave_mark:
		_wave_mark.queue_redraw()
	if _wave_light:
		var warning := fight != null and fight.wave_announced and _wave_time > 0.0
		_wave_light.visible = warning or _wave_flash > 0.0
		_wave_light.position = to_local(_wave_center)
		_wave_light.energy = 1.6 if _wave_flash > 0.0 else 0.9
	var art := SpriteAtlas.igris()
	if art:
		var frame := "idle"
		if fight:
			match fight.phase:
				IgrisFight.Phase.MUFFLER:
					frame = "muffler"
				IgrisFight.Phase.REGULATOR:
					frame = "regulator"
				IgrisFight.Phase.DONE:
					frame = "free"
		# Chest (sheet 24,29) sits where the muffler and regulator are hit (0,-18).
		art.draw(self, frame, Vector2(0, 13), _flash > 0.0)
		if fight and fight.phase == IgrisFight.Phase.MUFFLER and int(Time.get_ticks_msec() / 120.0) % 2 == 0:
			draw_rect(Rect2(Vector2(-6, -22), Vector2(12, 8)), Color("f2c14e"), false, 1.0)
	else:
		var body := COLOR_BODY.lightened(0.5) if _flash > 0.0 else COLOR_BODY
		draw_rect(Rect2(Vector2(-12, -30), Vector2(24, 32)), body)
		# Bell-shaped head.
		draw_colored_polygon(PackedVector2Array([Vector2(-10, -30), Vector2(10, -30), Vector2(7, -44), Vector2(-7, -44)]), COLOR_HEAD)
	if fight == null:
		return
	if art == null:
		_draw_phase_shapes()
	if _clang > 0.0:
		draw_arc(Vector2(0, -18), 14.0, -0.6, 0.6, 6, Color.WHITE, 2.0)
	# Cycles left, as small marks over the head.
	for i in fight.cycles:
		var done := i < fight.cycle
		draw_circle(Vector2(-6 + i * 12, -50), 2.5, Color("7ee0ff") if done else Color("555b66"))


## The placeholder look of each fight phase (used when the sheet is missing).
func _draw_phase_shapes() -> void:
	match fight.phase:
		IgrisFight.Phase.WAVES:
			draw_rect(Rect2(Vector2(-8, -24), Vector2(16, 12)), COLOR_MUFFLER)
		IgrisFight.Phase.MUFFLER:
			# Hookable now: the muffler blinks gold.
			var on := int(Time.get_ticks_msec() / 120.0) % 2 == 0
			draw_rect(Rect2(Vector2(-8, -24), Vector2(16, 12)), Color("f2c14e") if on else COLOR_MUFFLER)
		IgrisFight.Phase.REGULATOR:
			draw_circle(Vector2(0, -18), 6.0, COLOR_REGULATOR)
		IgrisFight.Phase.DONE:
			draw_circle(Vector2(0, -18), 4.0, Color("f2e6c4"))


class WaveMark extends Node2D:
	var igris: Igris

	func _draw() -> void:
		if igris and is_instance_valid(igris):
			igris.draw_wave(self)
