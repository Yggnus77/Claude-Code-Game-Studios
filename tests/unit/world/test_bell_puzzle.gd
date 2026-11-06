extends TestCase
## Bell gallery order (scene t06: circle, gap, waves).

const ORDER := ["circle", "gap", "waves"]


func test_right_order_solves() -> void:
	var b := BellPuzzle.new(ORDER)
	assert_eq(b.ring("circle"), BellPuzzle.Result.PROGRESS, "1")
	assert_eq(b.ring("gap"), BellPuzzle.Result.PROGRESS, "2")
	assert_eq(b.ring("waves"), BellPuzzle.Result.SOLVED, "3")
	assert_eq(b.ring("circle"), BellPuzzle.Result.ALREADY_SOLVED, "stays solved")


func test_wrong_bell_restarts() -> void:
	var b := BellPuzzle.new(ORDER)
	b.ring("circle")
	assert_eq(b.ring("waves"), BellPuzzle.Result.WRONG, "wrong")
	assert_eq(b.progress(), 0, "back to the start")
	b.ring("circle")
	assert_eq(b.ring("circle"), BellPuzzle.Result.WRONG, "circle twice is wrong")
	assert_eq(b.progress(), 1, "but it counts as a new start")
	b.ring("gap")
	assert_eq(b.ring("waves"), BellPuzzle.Result.SOLVED, "solved after the restart")


func test_grapple_destination_needs_item_and_start_point() -> void:
	var room := RoomData.load_room("t03_treino")
	var has := func(_i: String) -> bool: return true
	var none := func(_i: String) -> bool: return false
	var near_left := room.tile_center(Vector2i(13, 12))
	assert_eq(room.grapple_destination(Vector2i(20, 12), near_left, 32, has), Vector2i(20, 12), "left → right")
	assert_eq(room.grapple_destination(Vector2i(20, 12), near_left, 32, none), Vector2i(-1, -1), "needs the hook")
	assert_eq(room.grapple_destination(Vector2i(20, 12), room.tile_center(Vector2i(5, 5)), 32, has), Vector2i(-1, -1), "only from the marked start")
	assert_eq(room.grapple_destination(Vector2i(12, 12), room.tile_center(Vector2i(21, 12)), 32, has), Vector2i(12, 12), "and back")
	assert_true(not room.is_walkable(Vector2i(15, 12)), "the gap is not floor")
