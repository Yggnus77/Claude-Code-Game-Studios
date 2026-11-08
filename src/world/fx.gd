class_name Fx
extends RefCounted
## Small one-shot effects (sparks, dust, ink splashes) and the room's
## floating motes. Each burst is a CPUParticles2D that frees itself.

## Sparks of a sword hit: bright and quick, thrown away from [param from].
static func hit_sparks(parent: Node, at: Vector2, from: Vector2, blocked: bool = false) -> CPUParticles2D:
	var away := (at - from).normalized() if at != from else Vector2.UP
	var color := Color("f6dc8a") if blocked else Color("fff2d0")
	var p := burst(at + Vector2(0, 2), away, color, 10 if blocked else 8, 95.0, 0.3, 40.0, 12.0)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
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
## The node sits at [param at] (so it sorts in front of what it hits) and the
## squares start [param lift] px above it.
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
	var fade := Gradient.new()
	fade.set_color(0, color)
	fade.set_color(1, Color(color, 0.0))
	p.color_ramp = fade
	p.position = at
	p.z_index = 2
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
