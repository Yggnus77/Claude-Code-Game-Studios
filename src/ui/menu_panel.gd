class_name MenuPanel
extends PanelContainer
## A small keyboard and gamepad menu: title, optional message, options and a
## key hint. Up/down move; interact, attack or accept confirm. The owner
## handles going back (the pause action), so each screen decides what it means.

signal chosen(index: int)

## Presses sooner than this after the menu opens are ignored, so the press
## that opened it does not also pick an option.
const OPEN_GUARD := 0.15

var selected := 0
var options: PackedStringArray = []
var _title: Label
var _message: Label
var _list: VBoxContainer
var _hint: Label
var _opened_at := -1.0


func _init() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = DialogueBox.COLOR_PANEL
	style.border_color = DialogueBox.COLOR_EDGE
	style.set_border_width_all(1)
	style.set_content_margin_all(10)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", DialogueBox.COLOR_EDGE)
	box.add_child(_title)
	_message = Label.new()
	_message.add_theme_font_size_override("font_size", 10)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.custom_minimum_size = Vector2(380, 0)
	box.add_child(_message)
	_list = VBoxContainer.new()
	box.add_child(_list)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_hint)


## Shows [param title], [param message] and [param choices], with
## [param start] highlighted. [param back] names what the pause key does
## ("" hides that part of the hint).
func show_menu(title: String, message: String, choices: PackedStringArray, start: int = 0, back: String = "") -> void:
	_title.text = title
	_message.text = message
	_message.visible = not message.is_empty()
	options = choices
	selected = clampi(start, 0, maxi(0, choices.size() - 1))
	_opened_at = Time.get_ticks_msec() / 1000.0
	_hint.text = "%s/%s escolher · %s confirmar" % [DialogueBox._key("move_up"), DialogueBox._key("move_down"), DialogueBox._key("interact")]
	if not back.is_empty():
		_hint.text += " · %s %s" % [DialogueBox._key("pause"), back]
	_render()
	visible = true
	# Shrink to the new content, then keep the panel centred on screen.
	reset_size()
	position = (Vector2(640, 360) - size) * 0.5


## Confirms the highlighted option (also used by tests).
func confirm() -> void:
	if visible and not options.is_empty():
		chosen.emit(selected)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or event.is_echo() or options.is_empty():
		return
	if Time.get_ticks_msec() / 1000.0 - _opened_at < OPEN_GUARD:
		return
	if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
		selected = posmod(selected - 1, options.size())
		_render()
	elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
		selected = posmod(selected + 1, options.size())
		_render()
	elif event.is_action_pressed("interact") or event.is_action_pressed("attack") or event.is_action_pressed("ui_accept"):
		confirm()
	else:
		return
	get_viewport().set_input_as_handled()


func _render() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for i in options.size():
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 11)
		l.text = ("> " if i == selected else "   ") + options[i]
		l.modulate = Color.WHITE if i == selected else Color(1, 1, 1, 0.6)
		_list.add_child(l)
