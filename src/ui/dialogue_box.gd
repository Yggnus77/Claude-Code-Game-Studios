class_name DialogueBox
extends CanvasLayer
## Speech box for blocking scenes: speaker, up to two visible lines (longer
## text pages on), choices, and a history panel with every line in full.
## Shows the configured key names, never letters baked into the data.

signal closed

const COLOR_PANEL := Color(0.06, 0.07, 0.09, 0.92)
const COLOR_EDGE := Color("e0a030")
## Presses that arrive sooner than this after opening are ignored, so the
## press that opened the scene does not also advance it.
const OPEN_GUARD := 0.15

var runner: DialogueRunner
var _panel: PanelContainer
var _speaker: Label
var _text: Label
var _hint: Label
var _choices: VBoxContainer
var _history: Label
var _history_panel: PanelContainer
var _selected := 0
var _opened_at := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_PANEL
	style.border_color = COLOR_EDGE
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", style)
	# Anchored to the bottom edge: long choices grow the box upward, so the
	# last option and the key hint stay on screen.
	_panel.anchor_left = 0.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = 16
	_panel.offset_right = -16
	_panel.offset_top = -98
	_panel.offset_bottom = -18
	_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(_panel)
	var box := VBoxContainer.new()
	_panel.add_child(box)
	_speaker = Label.new()
	_speaker.add_theme_font_size_override("font_size", 10)
	_speaker.add_theme_color_override("font_color", COLOR_EDGE)
	box.add_child(_speaker)
	_text = Label.new()
	_text.add_theme_font_size_override("font_size", 12)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(594, 0)
	_text.max_lines_visible = 2
	box.add_child(_text)
	_choices = VBoxContainer.new()
	box.add_child(_choices)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size", 8)
	_hint.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_hint)
	_history_panel = PanelContainer.new()
	_history_panel.add_theme_stylebox_override("panel", style)
	_history_panel.position = Vector2(16, 16)
	_history_panel.size = Vector2(608, 244)
	_history = Label.new()
	_history.add_theme_font_size_override("font_size", 9)
	_history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_history.custom_minimum_size = Vector2(594, 0)
	_history.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_history.clip_text = true
	_history_panel.add_child(_history)
	add_child(_history_panel)
	_set_open(false)


## Shows [param scene_runner] until it finishes.
func open(scene_runner: DialogueRunner) -> void:
	runner = scene_runner
	_selected = 0
	_opened_at = Time.get_ticks_msec() / 1000.0
	_history_panel.visible = false
	_set_open(true)
	_refresh()


func is_open() -> bool:
	return runner != null


func _set_open(value: bool) -> void:
	_panel.visible = value
	if not value:
		_history_panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if runner == null or event.is_echo():
		return
	if Time.get_ticks_msec() / 1000.0 - _opened_at < OPEN_GUARD:
		return
	if event.is_action_pressed("history"):
		_history_panel.visible = not _history_panel.visible
		_refresh_history()
	elif event.is_action_pressed("skip_scene"):
		runner.skip()
		_after_step()
	elif runner.is_choice() and event.is_action_pressed("move_up"):
		_selected = posmod(_selected - 1, runner.node().get("options", []).size())
		_refresh()
	elif runner.is_choice() and event.is_action_pressed("move_down"):
		_selected = posmod(_selected + 1, runner.node().get("options", []).size())
		_refresh()
	elif event.is_action_pressed("interact") or event.is_action_pressed("attack"):
		next_step()
	else:
		return
	get_viewport().set_input_as_handled()


## Advances one page, line or confirms the highlighted choice.
func next_step() -> void:
	if runner == null:
		return
	if runner.is_choice():
		runner.choose(_selected)
		_selected = 0
	elif _text.lines_skipped + _text.max_lines_visible < _text.get_line_count():
		_text.lines_skipped += _text.max_lines_visible
		return
	else:
		runner.advance()
	_after_step()


func _after_step() -> void:
	if runner.is_finished:
		runner = null
		_set_open(false)
		closed.emit()
		return
	_refresh()


func _refresh() -> void:
	var n := runner.node()
	_text.lines_skipped = 0
	for c in _choices.get_children():
		c.queue_free()
	if runner.is_choice():
		_speaker.text = ""
		_text.text = str(n.get("text", ""))
		var options: Array = n.get("options", [])
		for i in options.size():
			var l := Label.new()
			l.add_theme_font_size_override("font_size", 11)
			l.text = ("> " if i == _selected else "   ") + str(options[i].get("text", ""))
			l.modulate = Color.WHITE if i == _selected else Color(1, 1, 1, 0.6)
			_choices.add_child(l)
	else:
		var speaker := str(n.get("speaker", ""))
		_speaker.text = "" if speaker == "SISTEMA" else display_name(speaker)
		_text.text = str(n.get("text", ""))
		_text.modulate = Color(0.75, 0.85, 1.0) if n.get("type", "") == "direction" else Color.WHITE
	_hint.text = "%s continuar · %s pular cena · %s histórico" % [_key("interact"), _key("skip_scene"), _key("history")]


func _refresh_history() -> void:
	var lines := PackedStringArray()
	for h in runner.history:
		var who := str(h["speaker"])
		lines.append(("%s: %s" % [display_name(who), h["text"]]) if who != "SISTEMA" and not who.is_empty() else "(%s)" % h["text"])
	_history.text = "\n".join(lines)


## "MECÂNICA DO CAIS" → "Mecânica do Cais": title case, but Portuguese
## particles (de, do, da, dos, das, e) stay lower case after the first word.
static func display_name(speaker: String) -> String:
	var words := speaker.to_lower().split(" ")
	for i in words.size():
		if i == 0 or not ["de", "do", "da", "dos", "das", "e"].has(words[i]):
			words[i] = words[i].left(1).to_upper() + words[i].substr(1)
	return " ".join(words)


## Name of the first key bound to [param action] (reflects remapping).
static func _key(action: String) -> String:
	return Controls.key_label(Controls.key_of(action))
