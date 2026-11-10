class_name Hud
extends CanvasLayer
## The game's heads-up display (design/gdd/jogabilidade-classica.md §3.6):
## hearts top right (half a heart = 1 point of life), the equipped item's
## box and the Bronze, key and flask counters top left, the objective, the
## toasts, the inventory and a key hint that lists only what the player
## already has.

const COLOR_BACK := Color("1a1c22")
const COLOR_LIFE := Color("e0a030")
const COLOR_TEXT := Color("f2e6c4")
## Hearts per row before a second row starts.
const HEARTS_PER_ROW := 10
## Right edge of the hearts and the objective.
const RIGHT_EDGE := 632.0
## Hearts and the item drawing are drawn this many times their pixel size,
## so they read at a glance on the 640×360 screen.
const ICON_SCALE := 2.0

var _hearts: Control
var _life_caption: Label
var _banner: Label
## Bronze, keys, flasks and bread, drawn with icons.
var _counters: Control
## The box with the equipped item's drawing.
var _item_box: Control
var _item_tool := "frasco"
var _counts := {}
var _toast: Label
var _toast_left := 0.0
var _saved: Label
var _saved_left := 0.0
var _objective: Label
var _item: Label
var _inventory: PanelContainer
var _inventory_text: Label
## Dungeon map beside the inventory text (masmorras §3).
var _dungeon_map: DungeonMapView
## Returns the dungeon map view for the current room ({} outside dungeons).
var dungeon_view: Callable = func() -> Dictionary: return {}
## Keys of the current dungeon: {"small_keys": n, "boss_key": bool}, or {}
## outside dungeons.
var key_view: Callable = func() -> Dictionary: return {}
## What the key hint may list: {"sword": bool, "tools": bool}.
var hint_state: Callable = func() -> Dictionary: return {"sword": true, "tools": true}
var _hint: Label
var _inventory_status := ""
var _inv_state: GameState
var _inv_config: GameConfig
## Extra inventory lines from the game (relic slot, mysteries).
var inventory_extra: Callable = func() -> PackedStringArray: return PackedStringArray()
## Called by K while the inventory is open; returns a status line.
var relic_cycle: Callable = Callable()
var _current := 0
var _maximum := 1
## Anchor Fragments gauge: four diamonds next to the life numbers, one lit per
## fragment toward the next point of life (GameState.FRAGMENTS_PER_LIFE).
var _gauge: Control
var _fragments := -1
var _gauge_flash := 0.0
const COLOR_FRAGMENT := Color("6fe0e0")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_life_caption = _small_label("— VIDA —", 8, COLOR_TEXT)
	_life_caption.size = Vector2(120, 10)
	_life_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_life_caption)
	_hearts = Control.new()
	_hearts.draw.connect(_draw_hearts)
	add_child(_hearts)
	_item_box = Control.new()
	_item_box.position = Vector2(8, 6)
	_item_box.size = Vector2(32, 32)
	_item_box.draw.connect(_draw_item_box)
	add_child(_item_box)
	_counters = Control.new()
	_counters.position = Vector2(46, 7)
	_counters.size = Vector2(300, 12)
	_counters.draw.connect(_draw_counters)
	add_child(_counters)
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position.y = 40
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.visible = false
	add_child(_banner)
	_gauge = Control.new()
	_gauge.size = Vector2(4 * 9, 12)
	_gauge.draw.connect(_draw_gauge)
	add_child(_gauge)
	_objective = Label.new()
	_objective.position = Vector2(RIGHT_EDGE - 400.0, 40)
	_objective.size = Vector2(400, 16)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective.add_theme_font_size_override("font_size", 10)
	_objective.add_theme_color_override("font_color", Color("f2e6c4"))
	_objective.add_theme_color_override("font_outline_color", Color.BLACK)
	_objective.add_theme_constant_override("outline_size", 4)
	add_child(_objective)
	_item = _small_label("", 9, Color("cfd6e0"))
	_item.position = Vector2(46, 22)
	add_child(_item)
	_toast = Label.new()
	# Two-line barks grow upward from the same baseline.
	_toast.position = Vector2(16, 224)
	_toast.size = Vector2(608, 40)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_toast.add_theme_font_size_override("font_size", 11)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 4)
	add_child(_toast)
	_saved = Label.new()
	_saved.text = "Jogo salvo"
	_saved.position = Vector2(532, 18)
	_saved.size = Vector2(100, 12)
	_saved.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_saved.add_theme_font_size_override("font_size", 8)
	_saved.add_theme_color_override("font_color", Color("cfd6e0"))
	_saved.modulate.a = 0.0
	add_child(_saved)
	_inventory = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.94)
	style.border_color = COLOR_LIFE
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	_inventory.add_theme_stylebox_override("panel", style)
	_inventory.position = Vector2(80, 16)
	_inventory.size = Vector2(480, 328)
	_inventory_text = Label.new()
	_inventory_text.add_theme_font_size_override("font_size", 10)
	_inventory_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inventory_text.custom_minimum_size = Vector2(464, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_inventory.add_child(row)
	row.add_child(_inventory_text)
	_inventory_text.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_dungeon_map = DungeonMapView.new()
	_dungeon_map.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_dungeon_map.visible = false
	row.add_child(_dungeon_map)
	_inventory.visible = false
	add_child(_inventory)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 9)
	_hint.modulate = Color(1, 1, 1, 0.7)
	_hint.position = Vector2(6, 342)
	add_child(_hint)
	_layout_life()
	refresh_hint()


## A label with an outline, readable over any floor.
func _small_label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	return l


## Places the hearts, their caption and the fragment gauge at the top right
## for the current maximum life.
func _layout_life() -> void:
	var hearts := HudIcons.heart_fills(_current, _maximum).size()
	var per_row := mini(hearts, HEARTS_PER_ROW)
	var rows := ceili(hearts / float(HEARTS_PER_ROW))
	var width := per_row * (HudIcons.HEART_SIZE.x + 1.0) * ICON_SCALE
	_hearts.size = Vector2(width, rows * (HudIcons.HEART_SIZE.y + 1.0) * ICON_SCALE)
	_hearts.position = Vector2(RIGHT_EDGE - width, 14)
	_life_caption.position = Vector2(RIGHT_EDGE - width * 0.5 - 60.0, 3)
	_gauge.position = Vector2(RIGHT_EDGE - _gauge.size.x, _hearts.position.y + _hearts.size.y + 2.0)
	_objective.position.y = _gauge.position.y + 12.0
	_hearts.queue_redraw()


## Rewrites the key hint at the bottom from the current bindings.
func refresh_hint() -> void:
	if _hint == null:
		return
	var k := func(action: String) -> String: return Controls.key_label(Controls.key_of(action))
	var walk := "/".join([k.call("move_up"), k.call("move_left"), k.call("move_down"), k.call("move_right")])
	if walk == "W/A/S/D":
		walk = "WASD"
	# Only what the player already has (jogabilidade-classica.md §3.6).
	var has: Dictionary = hint_state.call()
	var parts := PackedStringArray(["%s andar" % walk])
	if has.get("sword", false):
		parts.append("%s espada (segure: giro)" % k.call("attack"))
	parts.append("%s examinar" % k.call("interact"))
	if has.get("tools", false):
		parts.append("%s item · %s troca" % [k.call("item"), k.call("quick_swap")])
	else:
		parts.append("%s frasco" % k.call("item"))
	parts.append("%s inventário" % k.call("map"))
	parts.append("%s reinicia a sala" % k.call("reset_room"))
	_hint.text = " · ".join(parts)
	# Long key names must not push the hint off the screen.
	for size in [9, 8, 7]:
		_hint.add_theme_font_size_override("font_size", size)
		if _hint.get_minimum_size().x <= 628.0:
			break


## Follows [param health]'s changes.
func bind(health: Health) -> void:
	health.changed.connect(set_life)
	set_life(health.current, health.maximum)


func set_life(current: int, maximum: int) -> void:
	_current = current
	_maximum = maxi(1, maximum)
	_layout_life()


## Life shown now, as "current/maximum" (for tests and the inventory).
func life_text() -> String:
	return "%d/%d" % [_current, _maximum]


## The inventory pauses the game, so the node that opened it (main) stops
## receiving input; the HUD always runs and closes it with Tab or Esc.
func _unhandled_input(event: InputEvent) -> void:
	if not is_inventory_open():
		return
	if event.is_action_pressed("map") or event.is_action_pressed("pause"):
		_inventory.visible = false
		_inventory_status = ""
		get_tree().paused = false
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and relic_cycle.is_valid():
		_inventory_status = str(relic_cycle.call())
		_render_inventory()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _gauge_flash > 0.0:
		_gauge_flash = maxf(0.0, _gauge_flash - delta)
		_gauge.queue_redraw()
	if _saved_left > 0.0:
		_saved_left -= delta
		_saved.modulate.a = clampf(_saved_left / 0.4, 0.0, 0.8)
	if _toast_left > 0.0:
		_toast_left -= delta
		_toast.modulate.a = clampf(_toast_left / 0.4, 0.0, 1.0)


## Shows a short message above the dialogue area for [param seconds].
func toast(text: String, seconds: float = 2.5) -> void:
	_toast.text = text
	_toast_left = seconds
	_toast.modulate.a = 1.0


## A quiet "Jogo salvo" note in the corner; never blocks input.
func flash_saved() -> void:
	_saved_left = 1.2
	_saved.modulate.a = 0.8


## Follows Bronze and reserve from [param state].
func bind_state(state: GameState) -> void:
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
	_gauge.queue_redraw()


func _draw_gauge() -> void:
	var lit := fragment_gauge()
	# The full set shines only until the next fragment starts a new one.
	var full := _gauge_flash > 0.0 and lit == 0
	for i in GameState.FRAGMENTS_PER_LIFE:
		var c := Vector2(4.5 + i * 9.0, 6.0)
		var pts := PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 0), c + Vector2(0, 5), c + Vector2(-4, 0)])
		_gauge.draw_colored_polygon(pts, Color(0.05, 0.08, 0.1, 0.8))
		if full or i < lit:
			var inner := PackedVector2Array([c + Vector2(0, -4), c + Vector2(3, 0), c + Vector2(0, 4), c + Vector2(-3, 0)])
			var color := COLOR_FRAGMENT.lightened(0.5 * absf(sin(_gauge_flash * 9.0))) if full else COLOR_FRAGMENT
			_gauge.draw_colored_polygon(inner, color)
			_gauge.draw_rect(Rect2(c + Vector2(-1, -2), Vector2(1, 1)), Color.WHITE)
		pts.append(pts[0])
		_gauge.draw_polyline(pts, COLOR_FRAGMENT.darkened(0.3), 1.0)


## Rewrites the status line (Bronze, flasks, keys), e.g. after a room change.
func refresh_status(state: GameState) -> void:
	_show_bronze(state)


func _show_bronze(state: GameState) -> void:
	_counts = {
		"bronze": state.bronze,
		"reserve": state.bronze_reserve,
		"flasks": state.flasks().size(),
		"full_flasks": state.full_flask_count(),
		"bread": state.item_count("pao_porto"),
		"keys": key_view.call(),
	}
	_counters.queue_redraw()
	_item_box.queue_redraw()


## The counters line as text (for tests): "Bronze 12 · Chaves 1 ...".
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


func _draw_counters() -> void:
	var font := ThemeDB.fallback_font
	var x := 4.0
	var draw_num := func(text: String, at: float) -> float:
		_counters.draw_string_outline(font, Vector2(at, 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 3, Color.BLACK)
		_counters.draw_string(font, Vector2(at, 10), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_TEXT)
		return at + font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	HudIcons.coin(_counters, Vector2(x, 6))
	var reserve := int(_counts.get("reserve", 0))
	x = draw_num.call("%d" % int(_counts.get("bronze", 0)) + (" (+%d)" % reserve if reserve > 0 else ""), x + 7.0) + 10.0
	var keys: Dictionary = _counts.get("keys", {})
	if not keys.is_empty():
		HudIcons.key(_counters, Vector2(x, 6))
		x = draw_num.call("%d" % int(keys.get("small_keys", 0)), x + 6.0) + 6.0
		if keys.get("boss_key", false):
			HudIcons.key(_counters, Vector2(x + 2.0, 6), true)
			x += 14.0
		x += 4.0
	if int(_counts.get("flasks", 0)) > 0:
		_counters.draw_set_transform(Vector2(x, 6), 0.0, Vector2(0.6, 0.6))
		HudIcons.flask(_counters, Vector2.ZERO, int(_counts.get("full_flasks", 0)) > 0)
		_counters.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		x = draw_num.call("%d/%d" % [int(_counts.get("full_flasks", 0)), int(_counts.get("flasks", 0))], x + 6.0) + 10.0
	if int(_counts.get("bread", 0)) > 0:
		draw_num.call("Pão %d" % int(_counts.get("bread", 0)), x)


func _draw_item_box() -> void:
	var r := Rect2(Vector2.ZERO, _item_box.size)
	_item_box.draw_rect(r.grow(1), Color.BLACK)
	_item_box.draw_rect(r, Color(0.08, 0.07, 0.1, 0.85))
	_item_box.draw_rect(r, COLOR_LIFE, false, 1.0)
	_item_box.draw_rect(r.grow(-2), Color(COLOR_LIFE, 0.45), false, 1.0)
	# The drawing at 1.5×, centred in the box.
	_item_box.draw_set_transform(r.get_center(), 0.0, Vector2(1.5, 1.5))
	if _item_tool == "frasco":
		HudIcons.flask(_item_box, Vector2(0, 1), int(_counts.get("full_flasks", 0)) > 0)
	else:
		HudIcons.tool(_item_box, _item_tool, Vector2.ZERO)
	_item_box.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func is_inventory_open() -> bool:
	return _inventory.visible


## Opens or closes the inventory listing for [param state].
func toggle_inventory(state: GameState, config: GameConfig) -> void:
	_inventory.visible = not _inventory.visible
	_inventory_status = ""
	if not _inventory.visible:
		return
	_inv_state = state
	_inv_config = config
	_render_inventory()


## Rebuilds the inventory text from the state it was opened with.
func _render_inventory() -> void:
	var state := _inv_state
	var config := _inv_config
	# Compact: the relic slot and the mysteries below must fit the panel.
	var lines := PackedStringArray(["INVENTÁRIO"])
	var ids := state.items.keys()
	ids.sort()
	var names := PackedStringArray()
	for id in ids:
		names.append("%s x%d" % [config.item_name(id), state.items[id]])
	lines.append("Itens: " + (", ".join(names) if not names.is_empty() else "(vazio)"))
	lines.append("Bronze %d/%d (reserva %d) · Frascos %d cheios de %d (espaços %d)" % [state.bronze, state.wallet_capacity, state.bronze_reserve,
		state.full_flask_count(), state.flasks().size(), state.flask_capacity])
	var clues := 0
	for f in state.flags:
		if str(f).begins_with("clue.") and state.flags[f]:
			clues += 1
	lines.append("Fragmentos de Âncora %d (%d/4 para a próxima vida) · Pistas registradas %d" % [state.fragments.size(), state.fragments.size() % 4, clues])
	lines.append_array(inventory_extra.call())
	lines.append("")
	if not _inventory_status.is_empty():
		lines.append(_inventory_status)
	lines.append("%s fecha" % DialogueBox._key("map") + ("  ·  %s troca a relíquia" % DialogueBox._key("interact") if state.has_flag(GameState.RELIC_SLOT_FLAG) else ""))
	_inventory_text.text = "\n".join(lines)
	var map_view: Dictionary = dungeon_view.call()
	_dungeon_map.show_view(map_view)
	_inventory_text.custom_minimum_size.x = 464.0 - (_dungeon_map.custom_minimum_size.x + 10.0 if not map_view.is_empty() else 0.0)
	# The narrower text beside the map must still fit the panel: smaller
	# letters until it does (masmorras §3).
	for font_size in [10, 9, 8]:
		_inventory_text.add_theme_font_size_override("font_size", font_size)
		_inventory_text.reset_size()
		if _inventory_text.get_minimum_size().y <= 310.0:
			break
	_inventory.reset_size()


## Shows a centred message, or hides it with an empty string.
## Shows the current goal in the top-right corner; empty hides it.
func set_objective(text: String) -> void:
	_objective.text = "► " + text if not text.is_empty() else ""


## Shows the item on the item button: [param label] ("Arco 12") beside the
## box with the drawing of [param tool_id].
func set_item(label: String, can_swap: bool = false, tool_id: String = "frasco") -> void:
	_item.text = label + ("  ·  %s troca" % DialogueBox._key("quick_swap") if can_swap else "")
	_item_tool = tool_id
	_item_box.queue_redraw()


## The objective text on screen (for tests).
func objective_text() -> String:
	return _objective.text


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = not text.is_empty()


func _draw_hearts() -> void:
	var fills := HudIcons.heart_fills(_current, _maximum)
	var step := HudIcons.HEART_SIZE + Vector2.ONE
	_hearts.draw_set_transform(Vector2.ZERO, 0.0, Vector2(ICON_SCALE, ICON_SCALE))
	for i in fills.size():
		var col := i % HEARTS_PER_ROW
		var row := i / HEARTS_PER_ROW
		HudIcons.heart(_hearts, Vector2(col * step.x, row * step.y), fills[i])
	_hearts.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
