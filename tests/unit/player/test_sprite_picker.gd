extends TestCase
## Arte P1: the frame shown follows direction, animation clock and swing phase.

const META := {
	"frame_size": [32, 48], "pivot": [16, 44],
	"rows": {"down": 0, "up": 1, "side": 2},
	"anims": {"idle": [0, 1], "walk": [2, 3, 4, 5], "fall": [18, 19], "slash1": [6, 7]},
	"fps": {"idle": 2, "walk": 8, "fall": 6},
}


func test_direction_picks_row_and_flips_left() -> void:
	var p := SpritePicker.new(META)
	assert_eq(p.direction(Vector2.DOWN)["row"], 0, "down")
	assert_eq(p.direction(Vector2.UP)["row"], 1, "up")
	assert_eq(p.direction(Vector2.RIGHT), {"row": 2, "flip": false}, "right is the side row")
	assert_eq(p.direction(Vector2.LEFT), {"row": 2, "flip": true}, "left is the side row, flipped")


func test_walk_loops_and_fall_holds_last_frame() -> void:
	var p := SpritePicker.new(META)
	assert_eq(p.column("walk", 0.0), 2, "first walk frame")
	assert_eq(p.column("walk", 0.5), 2, "8 fps: frame 4 wraps to the first")
	assert_eq(p.column("fall", 10.0), 19, "fall stays down")


func test_swing_index_overrides_clock_and_region_uses_frame_size() -> void:
	var p := SpritePicker.new(META)
	assert_eq(p.column("slash1", 99.0, 1), 7, "phase picks the strike frame")
	var reg := p.region("slash1", 0.0, Vector2.UP, 1)
	assert_eq(reg["rect"], Rect2(224, 48, 32, 48), "column 7, row 1")


func test_the_shipped_sheet_has_every_animation_the_player_asks_for() -> void:
	var p := SpritePicker.load_meta("res://assets/art/personagens/yggnus.json")
	for a in ["idle", "walk", "slash1", "slash2", "slash3", "guard", "dodge", "hurt", "fall", "tool"]:
		assert_true(p.anims.has(a), "sheet has '%s'" % a)
	assert_eq(p.anims["slash3"].size(), 3, "finisher: wind, hit, recovery")
