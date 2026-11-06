class_name BellPuzzle
extends RefCounted
## Galeria dos sinos (scene t06): ring the three bells in the order drawn on
## the inscription. A wrong bell restarts the sequence; nothing is lost.

enum Result { PROGRESS, WRONG, SOLVED, ALREADY_SOLVED }

var order: Array
var solved := false
var _next := 0


func _init(bell_order: Array, already_solved: bool = false) -> void:
	order = bell_order
	solved = already_solved


## How many bells of the sequence are already right.
func progress() -> int:
	return _next


## Rings [param bell_id].
func ring(bell_id: String) -> Result:
	if solved:
		return Result.ALREADY_SOLVED
	if bell_id == str(order[_next]):
		_next += 1
		if _next >= order.size():
			solved = true
			return Result.SOLVED
		return Result.PROGRESS
	_next = 1 if bell_id == str(order[0]) else 0
	return Result.WRONG
