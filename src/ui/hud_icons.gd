class_name HudIcons
extends RefCounted
## Small pixel drawings for the HUD (design/gdd/jogabilidade-classica.md
## §3.6): hearts, the equipped tool, Bronze, keys and the flask. Drawn with
## rectangles on any CanvasItem, one logical pixel each, so they stay crisp
## at every window size.

const OUTLINE := Color("1b1420")
const HEART := Color("e0403a")
const HEART_HI := Color("ff9a8a")
const HEART_EMPTY := Color("4a2a30")
const BRASS := Color("d9ad4f")
const BRASS_HI := Color("f6dc8a")
const BRASS_LO := Color("8a6428")
const STEEL := Color("dfe5ec")
const STEEL_LO := Color("8f99a6")
const WOOD := Color("8a5a34")
const GLASS := Color("bfe6f0")
const POTION := Color("e05a7a")
const FLAME := Color("ffb84a")

## A heart, 9×8: "X" outline, "R" fill, "W" shine.
const HEART_ROWS := [
	".XX...XX.",
	"XRRX.XRRX",
	"XRWRXRRRX",
	"XRRRRRRRX",
	".XRRRRRX.",
	"..XRRRX..",
	"...XRX...",
	"....X....",
]
const HEART_SIZE := Vector2(9, 8)


## How full each heart is for [param current] of [param maximum] life:
## 2 full, 1 half, 0 empty (one heart = 2 points; formula §4).
static func heart_fills(current: int, maximum: int) -> Array[int]:
	var out: Array[int] = []
	var hearts := ceili(maxi(1, maximum) / 2.0)
	for i in hearts:
		out.append(clampi(current - 2 * i, 0, 2))
	return out


## Draws one heart with its top-left at [param at]; [param fill] 0, 1 or 2.
static func heart(ci: CanvasItem, at: Vector2, fill: int) -> void:
	for y in HEART_ROWS.size():
		var row: String = HEART_ROWS[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			var c := OUTLINE
			if ch != "X":
				var lit := fill == 2 or (fill == 1 and x <= 4)
				c = (HEART_HI if ch == "W" else HEART) if lit else HEART_EMPTY
			ci.draw_rect(Rect2(at + Vector2(x, y), Vector2.ONE), c)


## The equipped tool [param tool] drawn around [param c] (about 16 px).
static func tool(ci: CanvasItem, tool_id: String, c: Vector2) -> void:
	match tool_id:
		"gancho":
			ci.draw_line(c + Vector2(-6, 6), c + Vector2(3, -3), OUTLINE, 4.0)
			ci.draw_line(c + Vector2(-6, 6), c + Vector2(3, -3), WOOD, 2.0)
			ci.draw_arc(c + Vector2(3, 0), 4.0, -PI * 0.5, PI * 0.9, 8, OUTLINE, 4.0)
			ci.draw_arc(c + Vector2(3, 0), 4.0, -PI * 0.5, PI * 0.9, 8, BRASS, 2.0)
			ci.draw_rect(Rect2(c + Vector2(2, -6), Vector2(2, 2)), BRASS_HI)
		"arco":
			ci.draw_arc(c + Vector2(2, 0), 8.0, PI * 0.55, PI * 1.45, 12, OUTLINE, 4.0)
			ci.draw_arc(c + Vector2(2, 0), 8.0, PI * 0.55, PI * 1.45, 12, WOOD, 2.0)
			var top := c + Vector2(2, 0) + Vector2.from_angle(PI * 1.45) * 8.0
			var bottom := c + Vector2(2, 0) + Vector2.from_angle(PI * 0.55) * 8.0
			ci.draw_line(top, bottom, STEEL, 1.0)
			ci.draw_line(c + Vector2(-5, 0), c + Vector2(7, 0), OUTLINE, 3.0)
			ci.draw_line(c + Vector2(-5, 0), c + Vector2(7, 0), STEEL, 1.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(8, 0), c + Vector2(5, -2), c + Vector2(5, 2)]), STEEL_LO)
		"cargas":
			ci.draw_circle(c + Vector2(0, 2), 6.0, OUTLINE)
			ci.draw_circle(c + Vector2(0, 2), 5.0, BRASS)
			ci.draw_circle(c + Vector2(-2, 0), 2.0, BRASS_HI)
			ci.draw_line(c + Vector2(-5, 2), c + Vector2(5, 2), BRASS_LO, 1.0)
			ci.draw_line(c + Vector2(0, -4), c + Vector2(3, -7), Color("6a5a48"), 1.0)
			ci.draw_circle(c + Vector2(3, -7), 1.5, FLAME)
		"lamparina":
			ci.draw_rect(Rect2(c + Vector2(-5, -2), Vector2(10, 9)), OUTLINE)
			ci.draw_rect(Rect2(c + Vector2(-4, -1), Vector2(8, 7)), BRASS)
			ci.draw_rect(Rect2(c + Vector2(-2, 0), Vector2(4, 4)), Color("fff2c0"))
			ci.draw_arc(c + Vector2(0, -3), 3.5, PI, TAU, 8, OUTLINE, 2.0)
			ci.draw_circle(c + Vector2(0, -6), 1.8, FLAME)
		_:
			flask(ci, c, true)


## A flask, full (rose liquid) or empty.
static func flask(ci: CanvasItem, c: Vector2, full: bool) -> void:
	ci.draw_rect(Rect2(c + Vector2(-2, -8), Vector2(4, 5)), OUTLINE)
	ci.draw_rect(Rect2(c + Vector2(-1, -7), Vector2(2, 4)), GLASS)
	ci.draw_rect(Rect2(c + Vector2(-2, -9), Vector2(4, 2)), WOOD)
	ci.draw_circle(c + Vector2(0, 2), 6.0, OUTLINE)
	ci.draw_circle(c + Vector2(0, 2), 5.0, GLASS)
	if full:
		ci.draw_circle(c + Vector2(0, 3), 4.0, POTION)
	ci.draw_rect(Rect2(c + Vector2(-3, -1), Vector2(1, 2)), Color.WHITE)


## A Bronze coin, about 8 px.
static func coin(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_circle(c, 4.5, OUTLINE)
	ci.draw_circle(c, 3.5, BRASS)
	ci.draw_rect(Rect2(c + Vector2(-0.5, -2), Vector2(1, 4)), BRASS_LO)
	ci.draw_rect(Rect2(c + Vector2(-2, -2), Vector2(1, 1)), BRASS_HI)


## A small key; [param big] draws the boss key (larger, darker bit).
static func key(ci: CanvasItem, c: Vector2, big: bool = false) -> void:
	var s := 1.3 if big else 1.0
	ci.draw_circle(c + Vector2(0, -3) * s, 2.8 * s, OUTLINE)
	ci.draw_circle(c + Vector2(0, -3) * s, 1.8 * s, Color("e05a3a") if big else BRASS)
	ci.draw_line(c + Vector2(0, -1) * s, c + Vector2(0, 5) * s, OUTLINE, 3.0)
	ci.draw_line(c + Vector2(0, -1) * s, c + Vector2(0, 5) * s, BRASS, 1.0)
	ci.draw_rect(Rect2(c + Vector2(1, 3) * s, Vector2(2, 1) * s), BRASS)
