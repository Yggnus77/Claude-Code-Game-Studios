class_name ShopPanel
extends CanvasLayer
## Merchant menu: up/down choose, K buys, Esc or J closes. Pauses the world
## while open. Placeholder look matching the inventory panel.

signal closed

var shop: Shop
var state: GameState
var _index := 0
var _panel: PanelContainer
var _text: Label
var _message := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 6
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.94)
	style.border_color = Color("e0a030")
	style.set_border_width_all(1)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.position = Vector2(150, 70)
	_panel.size = Vector2(340, 150)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 11)
	_panel.add_child(_text)
	add_child(_panel)
	_panel.visible = false


func is_open() -> bool:
	return _panel.visible


## Shows the offers of [param merchant] for [param game_state].
func open(merchant: Shop, game_state: GameState) -> void:
	shop = merchant
	state = game_state
	_index = 0
	_message = ""
	_panel.visible = true
	get_tree().paused = true
	_refresh()


func close() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	get_tree().paused = false
	closed.emit()


## Buys the highlighted offer. Returns true when it was delivered.
func buy_selected() -> bool:
	var offer: Dictionary = shop.offers[_index]
	var why := shop.refusal(state, offer)
	var ok := why.is_empty() and shop.buy(state, offer)
	_message = "Comprado." if ok else why
	_refresh()
	return ok


func _unhandled_input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event.is_action_pressed("move_up"):
		_index = posmod(_index - 1, shop.offers.size())
	elif event.is_action_pressed("move_down"):
		_index = posmod(_index + 1, shop.offers.size())
	elif event.is_action_pressed("interact"):
		buy_selected()
	elif event.is_action_pressed("pause") or event.is_action_pressed("attack") or event.is_action_pressed("map"):
		close()
	else:
		return
	_refresh()
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	var lines := PackedStringArray(["COMERCIANTE", ""])
	for i in shop.offers.size():
		var o: Dictionary = shop.offers[i]
		lines.append("%s %s — %d Bronze" % ["►" if i == _index else "  ", o["label"], o["price"]])
	lines.append("")
	lines.append("Bronze %d · frascos cheios %d/%d · pão %d" % [state.bronze, state.full_flask_count(), state.flasks().size(), state.item_count("pao_porto")])
	lines.append(_message)
	lines.append("K compra · J ou Esc sai")
	_text.text = "\n".join(lines)
