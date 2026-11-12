class_name InventoryScreen
extends Control
## The inventory as an open backpack (design/gdd/telas-e-mochila.md §3.3):
## every item the player carries sits drawn in a pocket of the backpack;
## the cursor picks one and the framed panel beside it shows its name,
## kind, description and count. Interact uses the picked item (equips a
## tool or a relic) through [member item_action]; the screen never changes
## the game state itself. Below the description: Bronze, flasks, anchor
## fragments and the game's own lines (ammo, relic, mysteries), and the
## dungeon map when there is one.
##
## Example:
##   var bag := InventoryScreen.new()
##   hud.add_child(bag)
##   bag.open(state, config)      # shows it with the first pocket picked
##   bag.move(Vector2i.RIGHT)     # next pocket
##   bag.selected_item()          # "escudo_bronze"

const TEXTS_PATH := "res://assets/data/inventario.json"
const BAG_AT := Vector2(14, 44)
const TABS_AT := Vector2(256, 40)
const TAB_SIZE := Vector2(51, 15)
const PANEL_AT := Vector2(256, 60)
const PANEL_SIZE := Vector2(370, 250)
## Most lines under the description (more are cut, the panel stays put).
const STATS_LINES := 8
const COLOR_GOLD := UiArt.CREAM
const COLOR_TEXT := UiArt.TEXT
const COLOR_DIM := UiArt.DIM
const COLOR_SELECT := UiArt.ACCENT

## The game's own lines (ammo, relic slot, mysteries).
var extra_lines: Callable = func() -> PackedStringArray: return PackedStringArray()
## Uses [param item_id] (equip a tool or relic); returns a status line.
var item_action: Callable = Callable()
## True if [param item_id] is the equipped tool or relic.
var is_equipped: Callable = func(_id: String) -> bool: return false
## A line added under the description (a relic's effect), or "".
var item_detail: Callable = func(_id: String) -> String: return ""
## Dungeon map view (Dungeons.map_view), empty outside a dungeon.
var dungeon_view: Callable = func() -> Dictionary: return {}
## Pockets shown, in order: item ids.
var pockets: Array[String] = []
## Index of the picked pocket in [member pockets].
var selected := 0
## First row shown (more items than pockets scroll by rows).
var first_row := 0
var status := ""
## The tab shown (inventario.json "tabs"; 0 = all).
var tab := 0

var _state: GameState
var _config: GameConfig
var _texts: Dictionary = {}
var _grid_origin := Vector2(32, 60)
var _cell := 28.0
var _slot := 26.0
var _cols := 6
var _rows := 4
var _time := 0.0
var _panel: PanelContainer
var _icon: TextureRect
var _name: Label
var _kind: Label
var _desc: Label
var _count: Label
var _stats: Label
var _map: DungeonMapView
var _hint: Label
var _status: Label
var _footer: Label
var _tabs: Control


func _init() -> void:
	_texts = GameConfig.read_json(TEXTS_PATH)
	var grid: Dictionary = UiArt.meta().get("mochila", {})
	if not grid.is_empty():
		var o: Array = grid.get("grid_origin", [32, 60])
		_grid_origin = Vector2(float(o[0]), float(o[1]))
		_cell = float(grid.get("cell", 28))
		_slot = float(grid.get("slot", 26))
		_cols = int(grid.get("cols", 6))
		_rows = int(grid.get("rows", 4))


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _label("A LENDA DE YGGNUS", 13, COLOR_GOLD)
	title.position = Vector2(16, 6)
	add_child(title)
	var sub := _label("INVENTÁRIO · MOCHILA", 8, UiArt.ACCENT)
	sub.position = Vector2(17, 24)
	add_child(sub)
	_tabs = Control.new()
	_tabs.position = TABS_AT
	_tabs.size = Vector2(PANEL_SIZE.x, TAB_SIZE.y)
	_tabs.draw.connect(_draw_tabs)
	add_child(_tabs)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiArt.panel_style(10.0))
	_panel.position = PANEL_AT
	_panel.custom_minimum_size = PANEL_SIZE
	_panel.size = PANEL_SIZE
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	_panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(48, 48)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	head.add_child(_icon)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	_name = _label("", 14, COLOR_GOLD)
	names.add_child(_name)
	_kind = _label("", 9, COLOR_DIM)
	names.add_child(_kind)
	_count = _label("", 9, COLOR_TEXT)
	names.add_child(_count)
	_desc = _label("", 10, COLOR_TEXT)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(PANEL_SIZE.x - 30, 40)
	box.add_child(_desc)
	_status = _label("", 9, COLOR_SELECT)
	box.add_child(_status)
	var rule := ColorRect.new()
	rule.color = UiArt.EDGE
	rule.custom_minimum_size = Vector2(0, 1)
	box.add_child(rule)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(bottom)
	_stats = _label("", 9, COLOR_TEXT)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats.custom_minimum_size = Vector2(160, 0)
	# A fixed number of lines: the panel never grows past the screen.
	_stats.max_lines_visible = STATS_LINES
	bottom.add_child(_stats)
	_map = DungeonMapView.new()
	_map.custom_minimum_size = Vector2(150, 112)
	_map.visible = false
	bottom.add_child(_map)
	_footer = _label("", 9, COLOR_DIM)
	_footer.position = Vector2(258, 316)
	add_child(_footer)
	_hint = _label("", 8, UiArt.ACCENT)
	_hint.position = Vector2(258, 334)
	add_child(_hint)
	visible = false


func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("120c14"))
	l.add_theme_constant_override("outline_size", 3)
	return l


func is_open() -> bool:
	return visible


## Opens the backpack on [param state], keeping the picked item if it is
## still there.
func open(state: GameState, config: GameConfig) -> void:
	_state = state
	_config = config
	var keep := selected_item()
	status = ""
	if not tab_open(tab):
		tab = 0
	visible = true
	refresh()
	if pockets.has(keep):
		select(pockets.find(keep))


func close() -> void:
	visible = false
	status = ""


## Rebuilds the pockets and the panel from the state (after using an item).
func refresh() -> void:
	if _state == null:
		return
	pockets = sorted_items(_state, _config, _texts.get("order", []), _tab())
	selected = clampi(selected, 0, maxi(0, pockets.size() - 1))
	_keep_in_view()
	_render_panel()
	queue_redraw()


## The ids of the items in [param state] (count > 0), grouped by kind in
## [param order] (inventario.json), then in itens.json order.
static func sorted_items(state: GameState, config: GameConfig, order: Array, tab_def: Dictionary = {}) -> Array[String]:
	var data_order := config.items.keys()
	var ids: Array[String] = []
	for id: String in state.items:
		if state.item_count(id) > 0 and in_tab(id, str(config.items.get(id, {}).get("type", "")), tab_def):
			ids.append(id)
	var rank := func(id: String) -> int:
		var kind := str(config.items.get(id, {}).get("type", ""))
		var k := order.find(kind)
		return (k if k >= 0 else order.size()) * 1000 + maxi(0, data_order.find(id))
	ids.sort_custom(func(a: String, b: String) -> bool: return rank.call(a) < rank.call(b))
	return ids


## Whether item [param id] of kind [param kind] goes in [param tab_def]
## (inventario.json "tabs": "types", plus "items" added and "exclude"d;
## no types and no items = every item).
static func in_tab(id: String, kind: String, tab_def: Dictionary) -> bool:
	var types: Array = tab_def.get("types", [])
	var items: Array = tab_def.get("items", [])
	if types.is_empty() and items.is_empty():
		return true
	if (tab_def.get("exclude", []) as Array).has(id):
		return false
	return types.has(kind) or items.has(id)


## Whether tab [param i] shows yet ("needs": the player owns an item of
## its kinds, or has the relic slot).
func tab_open(i: int) -> bool:
	var tabs: Array = _texts.get("tabs", [])
	if i < 0 or i >= tabs.size() or _state == null:
		return i == 0
	var def: Dictionary = tabs[i]
	match str(def.get("needs", "")):
		"relic_slot":
			return _state.has_flag(GameState.RELIC_SLOT_FLAG)
		"owns_type":
			return not sorted_items(_state, _config, [], def).is_empty()
	return true


func _tab() -> Dictionary:
	var tabs: Array = _texts.get("tabs", [])
	return tabs[tab] if tab < tabs.size() else {}


## Shows the next tab (or the previous with [param step] -1).
func next_tab(step: int = 1) -> void:
	var count := maxi(1, (_texts.get("tabs", []) as Array).size())
	for i in count:
		tab = posmod(tab + step, count)
		if tab_open(tab):
			break
	selected = 0
	first_row = 0
	status = ""
	refresh()


## The item in the picked pocket, or "".
func selected_item() -> String:
	return pockets[selected] if selected >= 0 and selected < pockets.size() else ""


## Picks pocket [param index].
func select(index: int) -> void:
	if pockets.is_empty():
		return
	selected = clampi(index, 0, pockets.size() - 1)
	status = ""
	_keep_in_view()
	_render_panel()
	queue_redraw()


## Moves the cursor one pocket in [param dir] (wraps around the rows).
func move(dir: Vector2i) -> void:
	if pockets.is_empty():
		return
	var n := pockets.size()
	if dir.x != 0:
		select(posmod(selected + dir.x, n))
	elif dir.y != 0:
		var next := selected + dir.y * _cols
		var last_row := (n - 1) / _cols
		if next >= n:
			# From a row above the last, a short last row still takes the
			# cursor; from the last row it wraps to the top.
			next = n - 1 if selected / _cols < last_row else selected % _cols
		elif next < 0:
			next = mini(last_row * _cols + selected % _cols, n - 1)
		select(next)


## Uses the picked item through [member item_action].
func use_selected() -> void:
	var id := selected_item()
	if id.is_empty() or not item_action.is_valid():
		return
	status = str(item_action.call(id))
	refresh()


func _keep_in_view() -> void:
	var row := selected / _cols
	if row < first_row:
		first_row = row
	elif row >= first_row + _rows:
		first_row = row - _rows + 1


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _kind_text(id: String) -> String:
	var kind := str(_config.items.get(id, {}).get("type", ""))
	return str(_texts.get("categories", {}).get(kind, kind.capitalize()))


func _render_panel() -> void:
	var id := selected_item()
	if id.is_empty():
		_icon.texture = null
		_name.text = "Mochila vazia" if tab == 0 else "Nada aqui ainda"
		_kind.text = ""
		_count.text = ""
		_desc.text = "Ainda não há nada guardado." if tab == 0 else "Os itens deste tipo aparecem aqui quando Yggnus os encontra."
	else:
		_icon.texture = UiArt.icon(_icon_id(id))
		_name.text = _config.item_name(id)
		_kind.text = _kind_text(id) + ("  ·  equipado" if is_equipped.call(id) else "")
		var n := _state.item_count(id)
		var cap := int(_config.items.get(id, {}).get("stack_limit", 1))
		_count.text = ("Quantidade: %d/%d" % [n, cap]) if cap > 1 else ""
		if id.begins_with(GameState.FLASK_PREFIX):
			_count.text = "Cheio" if _state.full_flasks.has(id) else "Vazio"
		var detail := str(item_detail.call(id))
		_desc.text = str(_texts.get("descriptions", {}).get(id, "")) + ("\n" + detail if not detail.is_empty() else "")
	_status.text = status
	_status.visible = not status.is_empty()
	_stats.text = "\n".join(stats_lines())
	var view: Dictionary = dungeon_view.call()
	_map.show_view(view)
	var s := _state
	_footer.text = "Bronze %d / %d     Reserva %d     Fragmentos %d / %d" % [s.bronze, s.wallet_capacity, s.bronze_reserve,
		s.fragments.size() % GameState.FRAGMENTS_PER_LIFE, GameState.FRAGMENTS_PER_LIFE]
	_hint.text = "%s selecionar    %s usar / equipar    %s aba    %s voltar" % [
		"/".join([DialogueBox._key("move_left"), DialogueBox._key("move_right"), DialogueBox._key("move_up"), DialogueBox._key("move_down")]),
		DialogueBox._key("interact"), DialogueBox._key("quick_swap"), DialogueBox._key("map")]
	_tabs.queue_redraw()


## The lines under the description: flasks, clues and the game's own lines
## (Bronze and fragments are in the footer).
func stats_lines() -> PackedStringArray:
	var s := _state
	var lines := PackedStringArray()
	lines.append("Frascos: %d cheios de %d" % [s.full_flask_count(), s.flasks().size()])
	var clues := 0
	for f in s.flags:
		if str(f).begins_with("clue.") and s.flags[f]:
			clues += 1
	lines.append("Fragmentos de Âncora: %d (4 formam mais um ponto de vida)" % s.fragments.size())
	if clues > 0:
		lines.append("Pistas registradas: %d" % clues)
	for line: String in extra_lines.call():
		if not line.is_empty():
			lines.append(line)
	return lines


## The icon to draw for [param id] (a full flask has its own).
func _icon_id(id: String) -> String:
	if id.begins_with(GameState.FLASK_PREFIX) and _state != null and _state.full_flasks.has(id):
		return "frasco_cheio"
	return id


func _draw_tabs() -> void:
	var tabs: Array = _texts.get("tabs", [])
	var font := get_theme_default_font()
	var shown: Array[int] = []
	for i in tabs.size():
		if tab_open(i):
			shown.append(i)
	var w := (PANEL_SIZE.x - (shown.size() - 1) * 2.0) / maxf(1.0, shown.size())
	for k in shown.size():
		var i := shown[k]
		var r := Rect2(Vector2(k * (w + 2.0), 0), Vector2(w, TAB_SIZE.y))
		var on := i == tab
		_tabs.draw_rect(r, Color(UiArt.ACCENT, 0.18) if on else UiArt.PANEL)
		_tabs.draw_rect(r, UiArt.ACCENT if on else UiArt.EDGE, false, 1.0)
		_tabs.draw_string(font, r.position + Vector2(0, 11), str((tabs[i] as Dictionary).get("name", "")), HORIZONTAL_ALIGNMENT_CENTER, w, 7, Color.WHITE if on else UiArt.DIM)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(640, 360)), Color(0.03, 0.05, 0.1, 0.96))
	var bag := UiArt.texture("mochila.png")
	if bag:
		draw_texture(bag, BAG_AT)
	else:
		draw_rect(Rect2(BAG_AT, Vector2(232, 292)), Color("7a4b30"))
	var font := get_theme_default_font()
	var start := first_row * _cols
	for i in range(start, mini(pockets.size(), start + _cols * _rows)):
		var k := i - start
		var at := BAG_AT + _grid_origin + Vector2((k % _cols) * _cell, (k / _cols) * _cell)
		var id := pockets[i]
		draw_rect(Rect2(at + Vector2(1, 1), Vector2(_slot - 2, _slot - 2)), Color(0.05, 0.08, 0.14, 0.55))
		var tex := UiArt.icon(_icon_id(id))
		if tex:
			draw_texture(tex, at + Vector2(1, 1))
		if is_equipped.call(id):
			draw_rect(Rect2(at + Vector2(1, 1), Vector2(_slot - 2, _slot - 2)), UiArt.GOLD, false, 1.0)
		var n := _state.item_count(id)
		if n > 1:
			draw_string_outline(font, at + Vector2(0, _slot - 1), str(n), HORIZONTAL_ALIGNMENT_RIGHT, _slot - 1, 8, 3, Color("120c14"))
			draw_string(font, at + Vector2(0, _slot - 1), str(n), HORIZONTAL_ALIGNMENT_RIGHT, _slot - 1, 8, COLOR_TEXT)
		if i == selected:
			var pulse := 0.65 + 0.35 * sin(_time * 6.0)
			var r := Rect2(at - Vector2(2, 2), Vector2(_slot + 4, _slot + 4))
			draw_rect(r, Color(COLOR_SELECT, pulse), false, 2.0)
			for c: Vector2 in [r.position, r.position + Vector2(r.size.x - 3, 0), r.position + Vector2(0, r.size.y - 3), r.end - Vector2(3, 3)]:
				draw_rect(Rect2(c, Vector2(3, 3)), COLOR_SELECT)
	var total_rows := ceili(pockets.size() / float(_cols))
	if first_row > 0:
		draw_string(font, BAG_AT + _grid_origin + Vector2(_cols * _cell * 0.5 - 6, -2), "▲", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COLOR_SELECT)
	if first_row + _rows < total_rows:
		draw_string(font, BAG_AT + _grid_origin + Vector2(_cols * _cell * 0.5 - 6, _rows * _cell + 8), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, COLOR_SELECT)
