class_name Pickup
extends Node2D
## A Bronze coin dropped by a common enemy (inimigos.json "repeatable_drop",
## e.g. "bronze_5"). Collected on touch; lost when the room changes.

signal collected(pickup: Pickup)

const COLOR_COIN := Color("d9a441")
## Distance from the player's feet that collects it.
const REACH := 10.0
## Seconds before it fades away.
const LIFETIME := 12.0

var amount := 1
var target: Node2D
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
	if _age >= LIFETIME:
		queue_free()
		return
	if target and is_instance_valid(target) and global_position.distance_to(target.global_position) <= REACH:
		collected.emit(self)
		queue_free()
	queue_redraw()


func _draw() -> void:
	var blink := _age > LIFETIME - 2.0 and int(_age * 8.0) % 2 == 0
	if blink:
		return
	var r := 3.0 if amount < 5 else 4.0
	draw_circle(Vector2.ZERO, r, COLOR_COIN)
	draw_circle(Vector2(-1, -1), r * 0.4, COLOR_COIN.lightened(0.5))
