class_name YameInvasion
extends Node2D
## Yame Black in the workshop (prologue tutorial, chefes.json "yame_oficina").
## The creature cannot be hurt: it throws paper at Yggnus while three
## bindings hold the exit shut. Each binding breaks after a few sword hits
## and is recorded by a receipt, so a death or a reload keeps the cut ones.
## When the last one breaks, Yame flees over the roof and [signal cleared]
## fires. Placeholder art; numbers come from the encounter data.

## First paper thrown (the defence hint bark plays here).
signal thrown(paper: Node2D)
## A binding broke; [param left] are the ones still holding.
signal binding_cut(binding_id: String, left: int)
## Every binding is cut: the invasion is over.
signal cleared
## A sword swing reached Yame, who cannot be hurt (once per swing).
signal sword_deflected

const COLOR_YAME := Color("1b1530")
const COLOR_PAGE := Color("efe6cf")
const COLOR_EYE := Color("c44a6a")
const COLOR_THREAD := Color("b23a48")
## The bindings read as iron chains to break (user feedback, 2026-11-13).
const COLOR_IRON := Color("9aa3ad")
const COLOR_IRON_DARK := Color("2a2730")
const COLOR_IRON_SHINE := Color("e6edf2")
const LINK_STEP := 7.0
const FLEE_TIME := 0.8

var def: Dictionary
var state: GameState
var prologue: Prologue
var room_data: RoomData
var target: Node2D

var _throw_left := 0.0
var _telegraph_left := 0.0
var _thrown_any := false
var _fleeing := 0.0
var _door_center := Vector2.ZERO
var _bindings: Array[Node2D] = []
var _deflected_attacks: Dictionary = {}


## Configure before adding to the tree.
func setup(encounter: Dictionary, game_state: GameState, rules: Prologue, data: RoomData, player: Node2D) -> void:
	def = encounter
	state = game_state
	prologue = rules
	room_data = data
	target = player


func _ready() -> void:
	# In the group only so the sword finds Yame and can say it does nothing.
	add_to_group("enemies")
	var yt: Array = def.get("yame_tile", [12, 2])
	position = room_data.tile_center(Vector2i(int(yt[0]), int(yt[1])))
	for door in room_data.doors:
		if str(door.get("id", "")) == str(def.get("blocks_exit", "")):
			_door_center = room_data.tile_center(Vector2i(int(door["tile"][0]), int(door["tile"][1])))
	for entity in room_data.entities:
		var id := str(entity.get("id", ""))
		if not prologue.bindings_left(state).has(id):
			continue
		var b := Binding.new()
		b.binding_id = id
		b.hits_needed = int(def.get("binding_hits", 2))
		b.radius = float(def.get("binding_radius", 7))
		b.cut.connect(_on_binding_cut)
		add_child(b)
		b.global_position = room_data.tile_center(Vector2i(int(entity["tile"][0]), int(entity["tile"][1])))
		_bindings.append(b)
	_throw_left = prologue.throw_interval(state)


func is_fleeing() -> bool:
	return _fleeing > 0.0


func _physics_process(delta: float) -> void:
	if _fleeing > 0.0:
		_fleeing -= delta
		position.y -= 60.0 * delta
		modulate.a = clampf(_fleeing / FLEE_TIME, 0.0, 1.0)
		if _fleeing <= 0.0:
			cleared.emit()
			queue_free()
		queue_redraw()
		return
	if target == null or (target.has_method("is_dead") and target.is_dead()):
		return
	if _telegraph_left > 0.0:
		_telegraph_left -= delta
		if _telegraph_left <= 0.0:
			_throw()
	else:
		_throw_left -= delta
		if _throw_left <= 0.0:
			_telegraph_left = float(def.get("projectile_telegraph", 0.45))
			_throw_left = prologue.throw_interval(state)
	queue_redraw()


func _throw() -> void:
	var paper := Paper.new()
	paper.room_data = room_data
	paper.target = target
	paper.damage = int(def.get("projectile_damage", 1))
	paper.radius = float(def.get("projectile_radius", 4))
	var aim := (target.global_position - global_position).normalized()
	paper.velocity = (aim if aim != Vector2.ZERO else Vector2.DOWN) * float(def.get("projectile_speed", 95))
	get_parent().add_child(paper)
	paper.global_position = global_position + paper.velocity.normalized() * 10.0
	if not _thrown_any:
		_thrown_any = true
		thrown.emit(paper)


## Size of Yame's body for the sword.
func body_radius() -> float:
	return 12.0


## Yame cannot be hurt (roteiro: "Não é possível matar a criatura"). The
## swing is answered with [signal sword_deflected] so the player is told
## to cut the bindings instead. Always false: nothing took damage.
func receive_sword_hit(_damage: int, attack_id: int, from: Vector2) -> bool:
	if not _deflected_attacks.has(attack_id):
		_deflected_attacks[attack_id] = true
		Fx.hit_sparks(get_parent(), global_position, from, true)
		sword_deflected.emit()
	return false


func _on_binding_cut(b: Node2D) -> void:
	_bindings.erase(b)
	# The chain bursts: iron sparks where it held.
	Fx.hit_sparks(get_parent(), b.global_position, b.global_position + Vector2(0, 8), true)
	state.apply([{"op": "add_receipt", "receipt_id": Prologue.binding_receipt(b.binding_id)}])
	var left := prologue.bindings_left(state).size()
	binding_cut.emit(b.binding_id, left)
	if left == 0:
		_fleeing = FLEE_TIME
		_telegraph_left = 0.0


func _draw() -> void:
	for b in _bindings:
		if is_instance_valid(b) and _door_center != Vector2.ZERO:
			draw_chain(self, to_local(b.global_position), to_local(_door_center))
		if is_instance_valid(b):
			draw_chain(self, to_local(b.global_position), Vector2(0, 6), 0.6)
	var art := SpriteAtlas.enemies()
	if art:
		art.draw(self, "yame_telegraph" if _telegraph_left > 0.0 else "yame_idle", Vector2(0, 14))
		return
	# Body: a dark mass of pages with one eye that brightens before a throw.
	draw_circle(Vector2.ZERO, 12.0, COLOR_YAME)
	for i in 6:
		var a := TAU * i / 6.0 + Time.get_ticks_msec() / 900.0
		var c := Vector2(cos(a), sin(a)) * 11.0
		draw_rect(Rect2(c - Vector2(3, 4), Vector2(6, 8)), COLOR_PAGE)
	var eye := COLOR_EYE.lightened(0.5) if _telegraph_left > 0.0 else COLOR_EYE
	draw_circle(Vector2.ZERO, 3.5 if _telegraph_left > 0.0 else 2.5, eye)


## Draws an iron chain on [param canvas] from [param a] to [param b]: oval
## links that alternate face-on and edge-on, outlined so they read on any floor.
static func draw_chain(canvas: CanvasItem, a: Vector2, b: Vector2, alpha := 1.0) -> void:
	var length := a.distance_to(b)
	if length < 1.0:
		return
	var dir := (b - a) / length
	var side := Vector2(-dir.y, dir.x)
	var n := maxi(1, int(length / LINK_STEP))
	for i in n + 1:
		var c := a + dir * (length * i / n)
		if i % 2 == 0:
			var ring := PackedVector2Array()
			for k in 13:
				var t := TAU * k / 12.0
				ring.append(c + dir * cos(t) * 4.5 + side * sin(t) * 2.8)
			canvas.draw_polyline(ring, Color(COLOR_IRON_DARK, alpha), 3.0)
			canvas.draw_polyline(ring, Color(COLOR_IRON, alpha), 1.5)
			canvas.draw_line(c - dir * 2.0 + side * 1.6, c + dir * 1.0 + side * 1.6, Color(COLOR_IRON_SHINE, alpha), 1.0)
		else:
			canvas.draw_line(c - dir * 4.5, c + dir * 4.5, Color(COLOR_IRON_DARK, alpha), 3.5)
			canvas.draw_line(c - dir * 4.0, c + dir * 4.0, Color(COLOR_IRON, alpha), 1.5)


## One binding: hit it with the sword to break it. Joins the "enemies"
## group only so the player's sword finds it; it never attacks.
class Binding extends Node2D:
	signal cut(binding: Node2D)

	var binding_id := ""
	var hits_needed := 2
	var radius := 7.0
	var _hits := 0
	var _seen_attacks: Dictionary = {}
	var _flash := 0.0

	func _ready() -> void:
		add_to_group("enemies")

	func body_radius() -> float:
		return radius

	## True when this swing counted toward cutting the binding.
	func receive_sword_hit(_damage: int, attack_id: int, _from: Vector2) -> bool:
		if _seen_attacks.has(attack_id) or _hits >= hits_needed:
			return false
		_seen_attacks[attack_id] = true
		_hits += 1
		_flash = 0.1
		queue_redraw()
		if _hits >= hits_needed:
			remove_from_group("enemies")
			cut.emit(self)
			queue_free()
		return true

	func _physics_process(delta: float) -> void:
		if _flash > 0.0:
			_flash = maxf(0.0, _flash - delta)
			queue_redraw()

	func _draw() -> void:
		# An iron stake with a ring per hit still needed, cracked once struck.
		var iron := Color.WHITE if _flash > 0.0 else COLOR_IRON
		draw_rect(Rect2(Vector2(-4, -14), Vector2(8, 17)), COLOR_IRON_DARK)
		draw_rect(Rect2(Vector2(-3, -13), Vector2(6, 15)), Color("5b5f68"))
		draw_rect(Rect2(Vector2(-2, -12), Vector2(1, 13)), Color("8b919b"))
		draw_rect(Rect2(Vector2(-5, -15), Vector2(10, 3)), COLOR_IRON_DARK)
		for i in hits_needed - _hits:
			var c := Vector2(0, -6 - i * 6)
			draw_arc(c, 6.0, 0, TAU, 14, COLOR_IRON_DARK, 4.0)
			draw_arc(c, 6.0, 0, TAU, 14, iron, 2.0)
			draw_arc(c, 6.0, PI * 1.1, PI * 1.5, 4, COLOR_IRON_SHINE, 1.0)
		if _hits > 0:
			# A crack shows the chain is about to give.
			draw_polyline(PackedVector2Array([Vector2(-3, -10), Vector2(0, -7), Vector2(-1, -4), Vector2(2, -1)]), COLOR_IRON_SHINE, 1.0)


## A sheet of paper flying in a straight line. The shield stops it from the
## front, a dodge goes through it, and it tears on walls.
class Paper extends Node2D:
	var room_data: RoomData
	var target: Node2D
	var velocity := Vector2.ZERO
	var damage := 1
	var radius := 4.0

	func _ready() -> void:
		add_to_group("projectiles")

	func _physics_process(delta: float) -> void:
		position += velocity * delta
		rotation += 8.0 * delta
		var tile := Vector2i((global_position / room_data.tile_size).floor())
		if room_data.cell(tile) == RoomData.WALL:
			queue_free()
			return
		if target == null or not is_instance_valid(target):
			return
		if global_position.distance_to(target.global_position) > radius + Player.FEET_RADIUS:
			return
		var outcome: int = target.receive_hit(damage, global_position, false, false, "papel de Yame Black")
		if outcome != HitResolver.Outcome.DODGED and outcome != HitResolver.Outcome.IGNORED:
			queue_free()

	func _draw() -> void:
		draw_rect(Rect2(Vector2(-radius, -radius * 0.7), Vector2(radius * 2, radius * 1.4)), COLOR_PAGE)
		draw_line(Vector2(-radius * 0.6, 0), Vector2(radius * 0.6, 0), Color("6b6b6b"), 1.0)
