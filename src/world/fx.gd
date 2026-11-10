class_name Fx
extends RefCounted
## Small one-shot effects (sparks, dust, ink splashes) and the room's
## floating motes. Each burst is a CPUParticles2D that frees itself.

static var _fades: Dictionary = {}


## A colour fading out, shared by every burst of that colour.
static func _fade(color: Color) -> Gradient:
	if not _fades.has(color):
		var g := Gradient.new()
		g.set_color(0, color)
		g.set_color(1, Color(color, 0.0))
		_fades[color] = g
	return _fades[color]


## Sparks of a sword hit: bright and quick, thrown away from [param from].
static func hit_sparks(parent: Node, at: Vector2, from: Vector2, blocked: bool = false) -> CPUParticles2D:
	var away := (at - from).normalized() if at != from else Vector2.UP
	var color := Color("f6dc8a") if blocked else Color("fff2d0")
	var p := burst(at + Vector2(0, 2), away, color, 10 if blocked else 8, 95.0, 0.3, 40.0, 12.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	p.z_index = 2  # sparks fly in front of everything
	if spawn(parent, p) == null:
		return null
	# A brief flash of light, so the sparks read in a dark room too.
	var flash := PointLight2D.new()
	flash.texture = Room.light_texture()
	flash.color = color
	flash.position = Vector2(0, -12)
	flash.energy = 1.6
	flash.texture_scale = 0.45
	p.add_child(flash)
	p.create_tween().tween_property(flash, "energy", 0.0, 0.18)
	return p


## A puff of dust at the feet (steps, landing from a dodge).
static func dust(parent: Node, at: Vector2, color: Color = Color(0.82, 0.76, 0.66, 0.55)) -> CPUParticles2D:
	var p := burst(at, Vector2.UP, color, 4, 14.0, 0.35, 70.0)
	p.gravity = Vector2(0, -12)
	p.scale_amount_max = 2.0
	return spawn(parent, p)


## The splash left when an enemy is beaten.
static func defeat_puff(parent: Node, at: Vector2, color: Color) -> CPUParticles2D:
	var p := burst(at + Vector2(0, 2), Vector2.UP, color, 14, 55.0, 0.45, 180.0, 12.0)
	p.gravity = Vector2(0, 90)
	p.scale_amount_max = 2.5
	return spawn(parent, p)


## A charge going off: a ring of fire and smoke, falling stone chips and a
## strong flash of light that fades (design/gdd/ferramentas.md §3).
static func explosion(parent: Node, at: Vector2, radius: float) -> CPUParticles2D:
	var fire := burst(at, Vector2.UP, Color("ffb85a"), 26, radius * 4.2, 0.4, 180.0, 6.0)
	fire.scale_amount_min = 2.5
	fire.scale_amount_max = 4.5
	fire.z_index = 2
	if spawn(parent, fire) == null:
		return null
	var smoke := burst(at, Vector2.UP, Color(0.36, 0.32, 0.36, 0.8), 18, radius * 2.2, 0.8, 180.0, 6.0)
	smoke.gravity = Vector2(0, -30)
	smoke.scale_amount_min = 3.0
	smoke.scale_amount_max = 5.0
	smoke.z_index = 1
	spawn(parent, smoke)
	var chips := burst(at, Vector2.UP, Color("8a8494"), 12, radius * 3.0, 0.55, 150.0, 4.0)
	chips.gravity = Vector2(0, 160)
	chips.scale_amount_max = 2.0
	spawn(parent, chips)
	var flash := PointLight2D.new()
	flash.texture = Room.light_texture()
	flash.color = Color("ffc074")
	flash.position = Vector2(0, -6)
	flash.energy = 2.4
	flash.texture_scale = radius * 4.0 / 128.0
	fire.add_child(flash)
	fire.create_tween().tween_property(flash, "energy", 0.0, 0.35)
	var ring := Shock.new()
	ring.radius = radius
	ring.position = at
	ring.z_index = 2
	parent.add_child(ring)
	return fire


## A small lick of flame (the lamp, a torch catching fire).
static func flame_puff(parent: Node, at: Vector2) -> CPUParticles2D:
	var p := burst(at, Vector2.UP, Color("ffd27a"), 8, 26.0, 0.4, 50.0, 2.0)
	p.gravity = Vector2(0, -40)
	p.scale_amount_max = 2.0
	return spawn(parent, p)


## Adds [param p] to [param parent] and starts it; without a parent (a
## test, a node being freed) the burst is dropped and null is returned.
static func spawn(parent: Node, p: CPUParticles2D) -> CPUParticles2D:
	if parent == null or not parent.is_inside_tree():
		p.free()
		return null
	parent.add_child(p)
	p.emitting = true
	return p


## Generic one-shot burst (not yet in the tree): [param count] squares
## thrown along [param dir] within [param spread] degrees, living [param life] s.
## The node sits at [param at] (it sorts by height like the rest, just in
## front of what it hits) and the squares start [param lift] px above it.
static func burst(at: Vector2, dir: Vector2, color: Color, count: int, speed: float, life: float, spread: float, lift: float = 0.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	if lift != 0.0:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
		p.emission_points = PackedVector2Array([Vector2(0, -lift)])
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = maxi(count, 1)
	p.lifetime = life
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2.ZERO
	p.damping_min = speed * 1.5
	p.damping_max = speed * 2.5
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.5
	p.color_ramp = _fade(color)
	p.position = at
	p.finished.connect(p.queue_free)
	return p


## Slow motes drifting in the room's light (dust, or fireflies outdoors).
static func motes(size_px: Vector2, color: Color, amount: int, top: float = 0.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Motes"
	p.amount = maxi(amount, 1)
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(size_px.x * 0.5, (size_px.y + top) * 0.5)
	p.position = Vector2(size_px.x * 0.5, (size_px.y - top) * 0.5)
	p.direction = Vector2(0.3, -1)
	p.spread = 60.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 6.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.0
	var fade := Gradient.new()
	fade.set_color(0, Color(color, 0.0))
	fade.set_color(1, Color(color, 0.0))
	fade.add_point(0.5, color)
	p.color_ramp = fade
	p.z_index = 3
	return p


## The blast itself: a white-hot disc that turns to a ring of fire running
## out to the charge's reach, then fades (0.32 s).
class Shock extends Node2D:
	const TIME := 0.32
	var radius := 28.0
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		if _t >= TIME:
			queue_free()
			return
		queue_redraw()

	func _draw() -> void:
		var k := clampf(_t / TIME, 0.0, 1.0)
		var r := radius * (0.35 + 0.75 * sqrt(k))
		if k < 0.35:
			draw_circle(Vector2(0, -2), r * 0.8, Color(1.0, 0.97, 0.85, 0.9 * (1.0 - k / 0.35)))
		draw_arc(Vector2(0, -2), r, 0, TAU, 32, Color(1.0, 0.72, 0.3, 0.9 * (1.0 - k)), 3.0 * (1.0 - k) + 1.0)
		draw_arc(Vector2(0, -2), r * 0.82, 0, TAU, 28, Color(1.0, 0.45, 0.2, 0.6 * (1.0 - k)), 1.5)
		# a flattened scorch on the ground
		draw_set_transform(Vector2(0, 3), 0.0, Vector2(1.0, 0.45))
		draw_circle(Vector2.ZERO, radius * 0.7, Color(0.1, 0.06, 0.05, 0.35 * (1.0 - k)))
		draw_set_transform(Vector2.ZERO)
