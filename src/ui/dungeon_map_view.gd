class_name DungeonMapView
extends Control
## The dungeon map in the inventory (design/gdd/masmorras.md §3): one box per
## room on the grid from [method Dungeons.map_view]. Visited rooms are lit,
## rooms known only from the map are dim, the player's room has Yggnus's
## marker, and with the compass a chest dot and the boss mark show.

const COLOR_ROOM := Color("3a4a5e")
const COLOR_VISITED := Color("6f88a8")
const COLOR_HERE := Color("f2c14e")
const COLOR_EDGE := Color("1a2230")
const COLOR_CHEST := Color("e0b555")
const COLOR_BOSS := Color("d0505a")
const COLOR_TEXT := Color("cfd6e0")

## What [method Dungeons.map_view] returned, plus "name".
var view: Dictionary = {}
var _blink := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(190, 210)


func show_view(v: Dictionary) -> void:
	view = v
	visible = not v.is_empty()
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_blink += delta
		queue_redraw()


func _draw() -> void:
	if view.is_empty():
		return
	var font := get_theme_default_font()
	draw_string(font, Vector2(0, 10), str(view.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, size.x, 10, COLOR_HERE)
	var rooms: Array = view.get("rooms", [])
	if rooms.is_empty():
		return
	var lo := Vector2i(999, 999)
	var hi := Vector2i(-999, -999)
	for r: Dictionary in rooms:
		var c: Vector2i = r["cell"]
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var span := Vector2(hi - lo + Vector2i.ONE)
	var area := Rect2(0, 18, size.x, size.y - 58)
	var cell := minf(area.size.x / span.x, area.size.y / span.y)
	cell = minf(cell, 34.0)
	var box := Vector2(cell - 6.0, cell * 0.7 - 4.0)
	var origin := area.position + (area.size - Vector2(span.x * cell, span.y * cell * 0.7)) * 0.5
	var center := func(c: Vector2i) -> Vector2:
		return origin + Vector2((c.x - lo.x) * cell + cell * 0.5, (c.y - lo.y) * cell * 0.7 + cell * 0.35)
	var shown := {}
	for r: Dictionary in rooms:
		if r["shown"]:
			shown[r["cell"]] = true
	for link: Array in view.get("links", []):
		if shown.has(link[0]) and shown.has(link[1]):
			draw_line(center.call(link[0]), center.call(link[1]), COLOR_VISITED.darkened(0.3), 2.0)
	for r: Dictionary in rooms:
		if not r["shown"]:
			continue
		var at: Vector2 = center.call(r["cell"])
		var rect := Rect2(at - box * 0.5, box)
		draw_rect(rect, COLOR_VISITED if r["visited"] else COLOR_ROOM)
		draw_rect(rect, COLOR_EDGE, false, 1.0)
		if r["chest"]:
			draw_rect(Rect2(at + Vector2(box.x * 0.5 - 7, -box.y * 0.5 + 2), Vector2(5, 4)), COLOR_CHEST)
		if r["boss"]:
			var b := at + Vector2(-box.x * 0.5 + 5, -box.y * 0.5 + 5)
			draw_circle(b, 3.0, COLOR_BOSS)
			draw_rect(Rect2(b + Vector2(-1.5, 0), Vector2(1, 1)), COLOR_EDGE)
			draw_rect(Rect2(b + Vector2(0.5, 0), Vector2(1, 1)), COLOR_EDGE)
		if r["here"] and int(_blink * 3.0) % 2 == 0:
			draw_circle(at, 3.0, COLOR_HERE)
			draw_arc(at, 4.5, 0, TAU, 12, COLOR_EDGE, 1.0)
	var y := size.y - 34
	var lines := PackedStringArray()
	lines.append("Chaves pequenas: %d" % int(view.get("small_keys", 0)) + ("   ·   Chave Grande" if view.get("boss_key", false) else ""))
	var tools := PackedStringArray()
	if view.get("has_map", false):
		tools.append("Mapa")
	if view.get("has_compass", false):
		tools.append("Bússola")
	lines.append(" · ".join(tools) if not tools.is_empty() else "Sem mapa: só as salas visitadas")
	for line in lines:
		draw_string(font, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x, 9, COLOR_TEXT)
		y += 13
