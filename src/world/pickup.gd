class_name Pickup
extends Node2D
## A Bronze coin dropped by a common enemy (inimigos.json "repeatable_drop",
## e.g. "bronze_5"), a drop of life from a bush or a pot ("vida_1",
## exploracao.json), or needles for the Arco de Fio (a missed needle, or a
## pot's drop; ferramentas.md). Collected on touch; lost when the room
## changes.

signal collected(pickup: Pickup)

const COLOR_COIN := Color("d9a441")
const COLOR_LIFE := Color("e0505a")
const KIND_BRONZE := "bronze"
const KIND_LIFE := "life"
const KIND_NEEDLE := "agulha"
const COLOR_NEEDLE := Color("d8d2c4")
const COLOR_THREAD := Color("7ee0ff")
## Distance from the player's feet that collects it.
const REACH := 10.0
## Seconds before it fades away.
const LIFETIME := 12.0

var amount := 1
## [constant KIND_BRONZE], [constant KIND_LIFE] or [constant KIND_NEEDLE].
var kind := KIND_BRONZE
var lifetime := LIFETIME
var target: Node2D
## False keeps it on the ground when touched (a full quiver).
var can_collect: Callable = func() -> bool: return true
var _age := 0.0


## Parses a drop id like "bronze_5"; returns 0 for drops that are not Bronze.
static func bronze_amount(drop_id: String) -> int:
	if not drop_id.begins_with("bronze_"):
		return 0
	return int(drop_id.trim_prefix("bronze_"))


func _ready() -> void:
	add_to_group("pickups")


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= REACH and can_collect.call():
		collected.emit(self)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var blink := _age > lifetime - 2.0 and int(_age * 8.0) % 2 == 0
	if blink:
		return
	if kind == KIND_LIFE:
		# A small heart that bobs.
		var y := -2.0 + sin(_age * 5.0)
		draw_circle(Vector2(-1.5, y - 1.0), 2.0, COLOR_LIFE)
		draw_circle(Vector2(1.5, y - 1.0), 2.0, COLOR_LIFE)
		draw_colored_polygon(PackedVector2Array([Vector2(-3.4, y - 0.4), Vector2(3.4, y - 0.4), Vector2(0, y + 3.5)]), COLOR_LIFE)
		draw_rect(Rect2(-1.8, y - 2.2, 1.0, 1.0), COLOR_LIFE.lightened(0.6))
		return
	if kind == KIND_NEEDLE:
		# Needles stuck in the ground, glinting, with a wisp of their thread.
		var glint := 0.5 + 0.5 * sin(_age * 6.0)
		for i in mini(amount, 3):
			var x := -2.0 + i * 2.0
			draw_line(Vector2(x, 2), Vector2(x + 1, -4), COLOR_NEEDLE, 1.0)
			draw_rect(Rect2(x + 0.5, -5, 1, 1), Color(1, 1, 1, glint))
		draw_line(Vector2(-3, 2), Vector2(3, 1), Color(COLOR_THREAD, 0.6), 1.0)
		return
	var r := 3.0 if amount < 5 else 4.0
	draw_circle(Vector2.ZERO, r, COLOR_COIN)
	draw_circle(Vector2(-1, -1), r * 0.4, COLOR_COIN.lightened(0.5))
