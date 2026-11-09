class_name Breakable
extends StaticBody2D
## A bush or a pot (design/gdd/exploracao.md §2). It blocks the way until a
## sword swing breaks it; then it bursts into leaves or shards, tells the
## game (which rolls the drop) and leaves its stub, if any. The room builds
## them again whenever it is entered.

signal broken(breakable: Breakable)

## Radius used by the sword check (like an enemy's body).
const RADIUS := 7.0

var room: Room
var rules: Breakables
var kind := ""
var tile := Vector2i.ZERO
var is_broken := false


func _ready() -> void:
	add_to_group("breakables")
	collision_layer = Room.WORLD_LAYER if rules == null or rules.is_solid(kind) else 0
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 12)
	shape.shape = rect
	shape.position = Vector2(0, 1)
	add_child(shape)


func body_radius() -> float:
	return RADIUS


## The sword's hit: breaks it once. Returns true when it broke.
func receive_sword_hit(_damage: int, _attack_id: int, from: Vector2) -> bool:
	if is_broken:
		return false
	break_open(from)
	return true


func break_open(from: Vector2 = Vector2.ZERO) -> void:
	if is_broken:
		return
	is_broken = true
	collision_layer = 0
	var color := rules.fx_color(kind) if rules else Color.WHITE
	var away := (global_position - from).normalized() if from != Vector2.ZERO and from != global_position else Vector2.UP
	var p := Fx.burst(position + Vector2(0, 1), away, color, 12, 60.0, 0.45, 160.0, 6.0)
	p.gravity = Vector2(0, 110)
	p.scale_amount_max = 2.5
	Fx.spawn(get_parent(), p)
	broken.emit(self)
	if rules == null or rules.stub(kind).is_empty():
		queue_free()
	else:
		queue_redraw()


func _draw() -> void:
	if room == null or not is_instance_valid(room):
		return
	var shown := kind if not is_broken else (rules.stub(kind) if rules else "")
	if not shown.is_empty():
		room.draw_object_on(self, shown)
