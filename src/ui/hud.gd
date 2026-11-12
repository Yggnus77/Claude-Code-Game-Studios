class_name Hud
extends CanvasLayer
## The game's heads-up display, after the user's reference screens
## (design/gdd/telas-e-mochila.md §3.4):
## - top left: Yggnus's panel, his name, "5 / 6" and the life bar, one
##   segment per point of life, with the four Anchor Fragment diamonds;
## - top right: the area panel (region, room, the dungeon mini map, Bronze
##   and keys);
## - bottom left: the action slots (sword, equipped item, cure, relic),
##   each with its key, shown only once the player has it;
## - bottom right: the objective box;
## plus toasts, the "game saved" note, a key line that shows for a while
## when it changes, and the backpack inventory.

const COLOR_TEXT := UiArt.TEXT
const COLOR_FRAGMENT := Color("6fe0e0")
const DATA_PATH := "res://assets/data/hud.json"
const STATUS_AT := Vector2(8, 6)
const STATUS_WIDTH := 150.0
const SEGMENT_GAP := 2.0
const AREA_AT := Vector2(486, 6)
const AREA_WIDTH := 146.0
const SLOT_SIZE := Vector2(40, 42)
const SLOTS_AT := Vector2(8, 312)
const OBJECTIVE_AT := Vector2(404, 312)
const OBJECTIVE_SIZE := Vector2(228, 42)

## Returns the dungeon map view for the current room ({} outside dungeons).
var dungeon_view: Callable = func() -> Dictionary: return {}
## Keys of the current dungeon: {"small_keys": n, "boss_key": bool}, or {}
## outside dungeons.
var key_view: Callable = func() -> Dictionary: return {}
## What the HUD may show: {"sword": bool, "tools": bool, "flask": bool}.
var hint_state: Callable = func() -> Dictionary: return {"sword": true, "tools": true}
## Extra inventory lines from the game (ammo, relic slot, mysteries).
var inventory_extra: Callable = func() -> PackedStringArray: return PackedStringArray()
## Uses an item picked in the backpack; returns a status line.
var item_action: Callable = Callable()
## A line the game adds under an item's description (a relic's effect).
var item_detail: Callable = func(_id: String) -> String: return ""
## True if the item is the equipped tool or relic.
var is_equipped: Callable = func(_id: String) -> bool: return false

var _data: Dictionary = {}
var _status: Control
var _area: Control
var _slots: Control
var _objective_box: PanelContainer
var _objective: Label
var _banner: Label
var _toast: Label
var _toast_left := 0.0
var _saved: Label
var _saved_left := 0.0
## The equipped item's line ("Arco 7 · Q troca"), shown under its slot.
var _item: Label
var _item_tool := "frasco"
var _item_icon := ""
var _hint: Label
var _hint_left := 0.0
var _inventory: InventoryScreen
var _state: GameState
var _counts := {}
var _current := 0
var _maximum := 1
var _area_name := ""
var _room_name := ""
## Anchor Fragments gauge: one diamond lit per fragment toward the next
## point of life (GameState.FRAGMENTS_PER_LIFE).
var _fragments := -1
var _gauge_flash := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_data = GameConfig.read_json(DATA_PATH)
	_status = _panel_control(STATUS_AT, Vector2(STATUS_WIDTH, 34), _draw_status)
	_area = _panel_control(AREA_AT, Vector2(AREA_WIDTH, 30), _draw_area)
	_slots = Control.new()
	_slots.position = SLOTS_AT
	_slots.size = Vector2(4 * (SLOT_SIZE.x + 4), SLOT_SIZE.y)
	_slots.draw.connect(_draw_slots)
	add_child(_slots)
	# The item's line names it inside its slot; the label keeps the text.
	_item = _small_label("", 8, UiArt.DIM)
	_item.visible = false
	add_child(_item)
	_objective_box = PanelContainer.new()
	_objective_box.add_theme_stylebox_override("panel", UiArt.panel_style(5.0))
	_objective_box.position = OBJECTIVE_AT
	_objective_box.custom_minimum_size = OBJECTIVE_SIZE
	add_child(_objective_box)
	var obj := VBoxContainer.new()
	obj.add_theme_constant_override("separation", 0)
	_objective_box.add_child(obj)
	obj.add_child(_small_label("Objetivo", 8, UiArt.ACCENT))
	_objective = _small_label("", 9, COLOR_TEXT)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.custom_minimum_size = Vector2(OBJECTIVE_SIZE.x - 12, 0)
	_objective.max_lines_visible = 2
	obj.add_child(_objective)
	_objective_box.visible = false
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position.y = 60
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.visible = false
	add_child(_banner)
	_toast = Label.new()
	# Two-line barks grow upward from the same baseline.
	_toast.position = Vector2(16, 228)
	_toast.size = Vector2(608, 40)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_toast.add_theme_font_size_override("font_size", 11)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 4)
	add_child(_toast)
	_saved = _small_label("Jogo salvo", 8, UiArt.DIM)
	_saved.position = AREA_AT + Vector2(0, -2)
	_saved.size = Vector2(AREA_WIDTH - 6, 12)
	_saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_saved.modulate.a = 0.0
	add_child(_saved)
	_hint = _small_label("", 8, UiArt.DIM)
	_hint.position = Vector2(8, 296)
	_hint.size = Vector2(390, 12)
	add_child(_hint)
	_inventory = InventoryScreen.new()
	_inventory.extra_lines = func() -> PackedStringArray: return inventory_extra.call()
	_inventory.item_action = func(id: String) -> String: return str(item_action.call(id)) if item_action.is_valid() else ""
	_inventory.is_equipped = func(id: String) -> bool: return bool(is_equipped.call(id))
	_inventory.dungeon_view = func() -> Dictionary: return dungeon_view.call()
	_inventory.item_detail = func(id: String) -> String: return str(item_detail.call(id))
	add_child(_inventory)
	refresh_hint()


func _panel_control(at: Vector2, panel_size: Vector2, drawer: Callable) -> Control:
	var c := Control.new()
	c.position = at
	c.size = panel_size
	c.draw.connect(drawer)
	add_child(c)
	return c


## A label with an outline, readable over any floor.
func _small_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l


## Rewrites the key line from the current bindings and shows it for a while
## (hud.json "hint_seconds"). It lists only what the player already has
## (jogabilidade-classica.md §3.6).
func refresh_hint() -> void:
	if _hint == null:
		return
	var k := func(action: String) -> String: return Controls.key_label(Controls.key_of(action))
	var walk := "/".join([k.call("move_up"), k.call("move_left"), k.call("move_down"), k.call("move_right")])
	if walk == "W/A/S/D":
		walk = "WASD"
	var has: Dictionary = hint_state.call()
	var parts := PackedStringArray(["%s andar" % walk])
	if has.get("sword", false):
		parts.append("%s espada (segure: giro)" % k.call("attack"))
	parts.append("%s examinar" % k.call("interact"))
	if has.get("tools", false):
		parts.append("%s item · %s troca" % [k.call("item"), k.call("quick_swap")])
	elif has.get("flask", false):
		parts.append("%s frasco" % k.call("item"))
	parts.append("%s mochila" % k.call("map"))
	parts.append("%s reinicia a sala" % k.call("reset_room"))
	var text := " · ".join(parts)
	if text != _hint.text:
		_hint_left = float(_data.get("hint_seconds", 10.0))
	_hint.text = text
	for size in [8, 7]:
		_hint.add_theme_font_size_override("font_size", size)
		if _hint.get_minimum_size().x <= 380.0:
			break
	if _slots:
		_slots.queue_redraw()


## Follows [param health]'s changes.
func bind(health: Health) -> void:
	health.changed.connect(set_life)
	set_life(health.current, health.maximum)


func set_life(current: int, maximum: int) -> void:
	_current = current
	_maximum = maxi(1, maximum)
	_status.queue_redraw()


## Life shown now, as "current/maximum" (for tests and the inventory).
func life_text() -> String:
	return "%d/%d" % [_current, _maximum]


## The life numbers drawn on Yggnus's panel ("5 / 6").
func life_numbers() -> String:
	return "%d / %d" % [_current, _maximum]


## The inventory pauses the game, so the node that opened it (main) stops
## receiving input; the HUD always runs, moves the backpack's cursor, uses
## the picked item and closes it with Tab or Esc.
func _unhandled_input(event: InputEvent) -> void:
	if not is_inventory_open():
		return
	if event.is_action_pressed("map") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_inventory.close()
		_show_play_hud(true)
		get_tree().paused = false
	elif event.is_action_pressed("quick_swap"):
		_inventory.next_tab()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_inventory.use_selected()
		_status.queue_redraw()
		_slots.queue_redraw()
	else:
		var dir := Vector2i.ZERO
		if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
			dir = Vector2i.LEFT
		elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
			dir = Vector2i.RIGHT
		elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
			dir = Vector2i.UP
		elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
			dir = Vector2i.DOWN
		if dir == Vector2i.ZERO:
			return
		_inventory.move(dir)
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _gauge_flash > 0.0:
		_gauge_flash = maxf(0.0, _gauge_flash - delta)
		_status.queue_redraw()
	if _saved_left > 0.0:
		_saved_left -= delta
		_saved.modulate.a = clampf(_saved_left / 0.4, 0.0, 0.8)
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.4, 0.0, 1.0)
	if _hint_left > 0.0:
		_hint_left -= delta
	_hint.modulate.a = clampf(_hint_left / 0.6, 0.0, 0.85)


## Shows a short message above the dialogue area for [param seconds].
func toast(text: String, seconds: float = 2.5) -> void:
	_toast.text = text
	_toast_left = seconds
	_toast.modulate.a = 1.0


## A quiet "Jogo salvo" note in the corner; never blocks input.
func flash_saved() -> void:
	_saved_left = 1.2
	_saved.modulate.a = 0.8


## Follows Bronze, reserve, flasks and fragments from [param state].
func bind_state(state: GameState) -> void:
	_state = state
	state.changed.connect(func() -> void:
		_show_bronze(state)
		_show_fragments(state.fragments.size()))
	_show_bronze(state)
	_show_fragments(state.fragments.size())


## Number of lit diamonds (fragments toward the next point of life).
func fragment_gauge() -> int:
	return maxi(0, _fragments) % GameState.FRAGMENTS_PER_LIFE


func _show_fragments(count: int) -> void:
	if _fragments >= 0 and count == _fragments + 1 and count % GameState.FRAGMENTS_PER_LIFE == 0:
		_gauge_flash = 1.2  # a full set: the gauge shines, then empties
	_fragments = count
	_status.queue_redraw()


## Rewrites the status (Bronze, flasks, keys), e.g. after a room change.
func refresh_status(state: GameState) -> void:
	_show_bronze(state)


## Names the area panel: [param room_id]'s region (hud.json "areas") and
## [param room_name].
func set_area(room_id: String, room_name: String) -> void:
	var areas: Dictionary = _data.get("areas", {})
	_area_name = str(areas.get(room_id.left(1), "")).to_upper()
	_room_name = room_name
	_area.queue_redraw()


func _show_bronze(state: GameState) -> void:
	_counts = {
		"bronze": state.bronze,
		"wallet": state.wallet_capacity,
		"reserve": state.bronze_reserve,
		"flasks": state.flasks().size(),
		"full_flasks": state.full_flask_count(),
		"bread": state.item_count("pao_porto"),
		"keys": key_view.call(),
	}
	_area.queue_redraw()
	_slots.queue_redraw()


## The counters as text (for tests): "Bronze 12 · Chaves 1 ...".
func counters_text() -> String:
	var parts := PackedStringArray(["Bronze %d" % int(_counts.get("bronze", 0))])
	var keys: Dictionary = _counts.get("keys", {})
	if not keys.is_empty():
		parts.append("Chaves %d" % int(keys.get("small_keys", 0)))
		if keys.get("boss_key", false):
			parts.append("Chave Grande")
	if int(_counts.get("flasks", 0)) > 0:
		parts.append("Frascos %d/%d" % [int(_counts.get("full_flasks", 0)), int(_counts.get("flasks", 0))])
	if int(_counts.get("bread", 0)) > 0:
		parts.append("Pão %d" % int(_counts.get("bread", 0)))
	return " · ".join(parts)


func is_inventory_open() -> bool:
	return _inventory.is_open()


## Opens or closes the backpack for [param state].
func toggle_inventory(state: GameState, config: GameConfig) -> void:
	if _inventory.is_open():
		_inventory.close()
	else:
		_inventory.open(state, config)
	_show_play_hud(not _inventory.is_open())


## The play HUD hides under the backpack, so nothing shows through it.
func _show_play_hud(on: bool) -> void:
	for n: CanvasItem in [_status, _area, _slots, _objective_box, _hint, _toast, _saved]:
		n.visible = on
	if on:
		_objective_box.visible = not _objective.text.is_empty()


## The backpack screen (for tests and screenshots).
func inventory() -> InventoryScreen:
	return _inventory


## Shows the current goal in the objective box; empty hides it.
func set_objective(text: String) -> void:
	_objective.text = text
	_objective_box.visible = not text.is_empty() and not is_inventory_open()


## Shows the item on the item button: [param label] ("Arco 12") and the
## drawing of [param tool_id] ([param item_id] picks its icon).
func set_item(label: String, can_swap: bool = false, tool_id: String = "frasco", item_id: String = "") -> void:
	_item.text = label + ("  ·  %s troca" % DialogueBox._key("quick_swap") if can_swap else "")
	_item_tool = tool_id
	_item_icon = item_id
	_slots.queue_redraw()


## The objective text on screen (for tests).
func objective_text() -> String:
	return _objective.text


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = not text.is_empty()


# --------------------------------------------------------------- drawing

func _panel(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_rect(rect, UiArt.PANEL)
	ci.draw_rect(rect, UiArt.EDGE, false, 1.0)


func _text(ci: CanvasItem, at: Vector2, text: String, font_size: int, color: Color, width: float = -1.0, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	var font := ThemeDB.fallback_font
	ci.draw_string_outline(font, at, text, align, width, font_size, 3, Color(0, 0, 0, 0.8))
	ci.draw_string(font, at, text, align, width, font_size, color)


## Width in px of one life segment for [param maximum] points
## (telas-e-mochila.md §4): 6 → 20, 14 → 7.
static func segment_width(maximum: int) -> float:
	var m := maxi(1, maximum)
	return floorf(minf(20.0, (STATUS_WIDTH - 16.0 - SEGMENT_GAP * (m - 1)) / m))


## Filled and empty life segments now: [filled, total].
func life_segments() -> Vector2i:
	return Vector2i(clampi(_current, 0, _maximum), _maximum)


## Yggnus's panel: name, life numbers, one segment per point of life and
## the fragment diamonds.
func _draw_status() -> void:
	var w := STATUS_WIDTH
	var gap := SEGMENT_GAP
	var seg_w := segment_width(_maximum)
	_panel(_status, Rect2(0, 0, w, 34))
	_text(_status, Vector2(7, 11), "YGGNUS", 8, UiArt.CREAM)
	_text(_status, Vector2(0, 11), life_numbers(), 8, UiArt.CREAM, w - 7.0, HORIZONTAL_ALIGNMENT_RIGHT)
	for i in _maximum:
		var r := Rect2(7.0 + i * (seg_w + gap), 15.0, seg_w, 6.0)
		_status.draw_rect(r, UiArt.LIFE if i < _current else UiArt.LIFE_EMPTY)
		if i < _current:
			_status.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), UiArt.LIFE.lightened(0.35))
	var lit := fragment_gauge()
	var full := _gauge_flash > 0.0 and lit == 0
	_text(_status, Vector2(7, 31), "Fragmentos", 7, UiArt.DIM)
	for i in GameState.FRAGMENTS_PER_LIFE:
		var c := Vector2(58.0 + i * 9.0, 27.5)
		var pts := PackedVector2Array([c + Vector2(0, -4), c + Vector2(3, 0), c + Vector2(0, 4), c + Vector2(-3, 0)])
		_status.draw_colored_polygon(pts, Color(0.05, 0.08, 0.1, 0.9))
		if full or i < lit:
			var color := COLOR_FRAGMENT.lightened(0.5 * absf(sin(_gauge_flash * 9.0))) if full else COLOR_FRAGMENT
			_status.draw_colored_polygon(pts, color)
			_status.draw_rect(Rect2(c + Vector2(-1, -2), Vector2(1, 1)), Color.WHITE)
		pts.append(pts[0])
		_status.draw_polyline(pts, COLOR_FRAGMENT.darkened(0.3), 1.0)


## The area panel: region, room, the mini map in a dungeon, Bronze and keys.
func _draw_area() -> void:
	var view: Dictionary = dungeon_view.call()
	var map_h := 0.0
	if not view.is_empty() and not (view.get("rooms", []) as Array).is_empty():
		map_h = 40.0
	var keys: Dictionary = _counts.get("keys", {})
	var h := 34.0 + map_h + (11.0 if not keys.is_empty() else 0.0)
	_area.size.y = h
	_panel(_area, Rect2(0, 0, AREA_WIDTH, h))
	_text(_area, Vector2(7, 11), _area_name if not _area_name.is_empty() else _room_name.to_upper(), 8, UiArt.CREAM, AREA_WIDTH - 12.0)
	_text(_area, Vector2(7, 21), _room_name, 7, UiArt.DIM, AREA_WIDTH - 12.0)
	if map_h > 0.0:
		_draw_mini_map(view, Rect2(7, 25, AREA_WIDTH - 14.0, map_h - 4.0))
	var y := 31.0 + map_h
	var reserve := int(_counts.get("reserve", 0))
	HudIcons.coin(_area, Vector2(11, y - 3))
	_text(_area, Vector2(18, y), "Bronze %d / %d" % [int(_counts.get("bronze", 0)), int(_counts.get("wallet", 0))] + (" (+%d)" % reserve if reserve > 0 else ""), 8, UiArt.DIM)
	if not keys.is_empty():
		y += 11.0
		HudIcons.key(_area, Vector2(11, y - 3))
		var line := "Chaves %d" % int(keys.get("small_keys", 0)) + ("  ·  Chave Grande" if keys.get("boss_key", false) else "")
		_text(_area, Vector2(18, y), line, 8, UiArt.DIM)


## The dungeon's rooms as small boxes; the player's room marked.
func _draw_mini_map(view: Dictionary, area: Rect2) -> void:
	var rooms: Array = view.get("rooms", [])
	var lo := Vector2i(999, 999)
	var hi := Vector2i(-999, -999)
	for r: Dictionary in rooms:
		if not r["shown"]:
			continue
		var c: Vector2i = r["cell"]
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	if lo.x > hi.x:
		return
	var span := Vector2(hi - lo + Vector2i.ONE)
	var cell := minf(minf(area.size.x / span.x, area.size.y / span.y), 14.0)
	var box := Vector2(cell - 3.0, cell * 0.7 - 2.0)
	var origin := area.position + (area.size - Vector2(span.x * cell, span.y * cell * 0.7)) * 0.5
	for r: Dictionary in rooms:
		if not r["shown"]:
			continue
		var c: Vector2i = r["cell"]
		var at := origin + Vector2((c.x - lo.x) * cell, (c.y - lo.y) * cell * 0.7)
		var rect := Rect2(at, box)
		_area.draw_rect(rect, Color(UiArt.ACCENT, 0.35) if r["visited"] else Color(UiArt.EDGE, 0.6))
		_area.draw_rect(rect, UiArt.ACCENT.darkened(0.3), false, 1.0)
		if r["here"]:
			_area.draw_circle(rect.get_center(), 2.0, UiArt.CREAM)


## The action slots along the bottom: what the player has, with its key.
func _draw_slots() -> void:
	var slots := action_slots()
	for i in slots.size():
		var s: Array = slots[i]
		var r := Rect2(Vector2(i * (SLOT_SIZE.x + 4.0), 0), SLOT_SIZE)
		_panel(_slots, r)
		var tex := UiArt.icon(str(s[0]))
		if tex:
			_slots.draw_texture(tex, r.position + Vector2((SLOT_SIZE.x - 24.0) * 0.5, 3))
		_text(_slots, r.position + Vector2(0, SLOT_SIZE.y - 4), str(s[1]), 7, UiArt.CREAM, SLOT_SIZE.x, HORIZONTAL_ALIGNMENT_CENTER)
		if bool(s[4]):
			_text(_slots, r.position + Vector2(0, 9), Controls.key_label(Controls.key_of("quick_swap")) + "↻", 7, UiArt.DIM, SLOT_SIZE.x - 3.0, HORIZONTAL_ALIGNMENT_RIGHT)
		if not str(s[2]).is_empty():
			_text(_slots, r.position + Vector2(3, 9), Controls.key_label(Controls.key_of(str(s[2]))), 7, UiArt.ACCENT)
		if not str(s[3]).is_empty():
			_text(_slots, r.position + Vector2(0, 27), str(s[3]), 8, UiArt.CREAM, SLOT_SIZE.x - 3.0, HORIZONTAL_ALIGNMENT_RIGHT)


## The slots along the bottom, in order: [icon id, label, action whose
## key is shown ("" none), corner number, shows the swap key]. The flask
## has its own Cura slot, so a flask on the item button adds no item slot.
func action_slots() -> Array:
	var has: Dictionary = hint_state.call()
	var tools := bool(has.get("tools", false))
	var slots: Array = []
	if has.get("sword", false):
		slots.append(["espada_oficina", "Atacar", "attack", "", false])
	if _item_tool != "frasco":
		slots.append([_item_icon if not _item_icon.is_empty() else "_generico", _item.text.split("  ·  ")[0].split(" ")[0], "item", _ammo_text(), tools])
	if int(_counts.get("flasks", 0)) > 0:
		var full := int(_counts.get("full_flasks", 0))
		var on_button := _item_tool == "frasco"
		slots.append(["frasco_cheio" if full > 0 else "frasco_01", "Cura %d/%d" % [full, int(_counts.get("flasks", 0))],
			"item" if on_button else "", "", on_button and tools])
	if _state != null and _state.has_flag(GameState.RELIC_SLOT_FLAG):
		slots.append([_state.equipped_relic if not _state.equipped_relic.is_empty() else "_generico", "Relíquia", "", "", false])
	return slots


## The ammo count in the item's label ("Arco 7" → "7"), or "".
func _ammo_text() -> String:
	var words := _item.text.split("  ·  ")[0].split(" ")
	var last := words[words.size() - 1] if not words.is_empty() else ""
	return last if last.is_valid_int() else ""
