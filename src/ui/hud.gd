class_name Hud
extends CanvasLayer
## Life display: amber bar plus the number, which is the rule's source of truth
## (design/kit/auditoria-e-decisoes.md item 5). Placeholder art.

const COLOR_BACK := Color("1a1c22")
const COLOR_LIFE := Color("e0a030")
const COLOR_EMPTY := Color("4a3a24")

var _bar: Control
var _label: Label
var _banner: Label
var _bronze: Label
var _toast: Label
var _toast_left := 0.0
var _saved: Label
var _saved_left := 0.0
var _objective: Label
var _item: Label
var _inventory: PanelContainer
var _inventory_text: Label
var _inventory_status := ""
var _inv_state: GameState
var _inv_config: GameConfig
## Extra inventory lines from the game (relic slot, mysteries).
var inventory_extra: Callable = func() -> PackedStringArray: return PackedStringArray()
## Called by K while the inventory is open; returns a status line.
var relic_cycle: Callable = Callable()
var _current := 0
var _maximum := 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_bar = Control.new()
	_bar.position = Vector2(8, 8)
	_bar.size = Vector2(120, 10)
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	_label = Label.new()
	_label.position = Vector2(134, 2)
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position.y = 40
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.visible = false
	add_child(_banner)
	_bronze = Label.new()
	_bronze.position = Vector2(8, 18)
	_bronze.add_theme_font_size_override("font_size", 10)
	_bronze.add_theme_color_override("font_color", Color("d9a441"))
	add_child(_bronze)
	_objective = Label.new()
	_objective.position = Vector2(232, 4)
	_objective.size = Vector2(400, 16)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective.add_theme_font_size_override("font_size", 10)
	_objective.add_theme_color_override("font_color", Color("f2e6c4"))
	_objective.add_theme_color_override("font_outline_color", Color.BLACK)
	_objective.add_theme_constant_override("outline_size", 4)
	add_child(_objective)
	_item = Label.new()
	_item.position = Vector2(8, 30)
	_item.add_theme_font_size_override("font_size", 9)
	_item.add_theme_color_override("font_color", Color("cfd6e0"))
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
	_inventory.add_child(_inventory_text)
	_inventory.visible = false
	add_child(_inventory)
	var hint := Label.new()
	hint.text = "WASD andar · J espada · K examinar · L item · Q troca · Espaço esquiva · Shift defesa · Tab inventário · 1-4 inimigo · R reinicia"
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(1, 1, 1, 0.7)
	hint.position = Vector2(6, 342)
	add_child(hint)


## Follows [param health]'s changes.
func bind(health: Health) -> void:
	health.changed.connect(set_life)
	set_life(health.current, health.maximum)


func set_life(current: int, maximum: int) -> void:
	_current = current
	_maximum = maxi(1, maximum)
	_label.text = "%d/%d" % [current, maximum]
	_bar.queue_redraw()


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
	state.changed.connect(func() -> void: _show_bronze(state))
	_show_bronze(state)


func _show_bronze(state: GameState) -> void:
	_bronze.text = "Bronze %d/%d" % [state.bronze, state.wallet_capacity] + ("  (reserva %d)" % state.bronze_reserve if state.bronze_reserve > 0 else "")
	if not state.flasks().is_empty():
		_bronze.text += "   Frascos %d/%d" % [state.full_flask_count(), state.flasks().size()]
	if state.item_count("pao_porto") > 0:
		_bronze.text += "   Pão %d" % state.item_count("pao_porto")


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


## Shows a centred message, or hides it with an empty string.
## Shows the current goal in the top-right corner; empty hides it.
func set_objective(text: String) -> void:
	_objective.text = "► " + text if not text.is_empty() else ""


## Shows the item on the item button.
func set_item(item_name: String, can_swap: bool = false) -> void:
	_item.text = "Item (L): %s" % item_name + (" · Q troca" if can_swap else "")


## The objective text on screen (for tests).
func objective_text() -> String:
	return _objective.text


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = not text.is_empty()


func _draw_bar() -> void:
	var size := _bar.size
	_bar.draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), COLOR_BACK)
	_bar.draw_rect(Rect2(Vector2.ZERO, size), COLOR_EMPTY)
	_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _current / _maximum, size.y)), COLOR_LIFE)
	for i in range(1, _maximum):
		var x := size.x * i / _maximum
		_bar.draw_line(Vector2(x, 0), Vector2(x, size.y), COLOR_BACK, 1.0)
