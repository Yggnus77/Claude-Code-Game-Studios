class_name SettingsScreen
extends CanvasLayer
## The settings menu, opened from the pause menu and the title screen:
## window mode, pause on focus loss, the playtest record and a controls page
## where each action gets a new key or gamepad button. Every change is saved
## at once in [Settings]. The pause key goes back one page.

## The player left the settings menu.
signal closed
## A setting or a binding changed (already saved).
signal changed

enum Page { MAIN, CONTROLS, CAPTURE }

## Presses sooner than this after waiting for a new key are ignored, so the
## press that chose the action is not taken as the new key.
const CAPTURE_GUARD := 0.15
const YES_NO := ["Não", "Sim"]
## Actions shown at once on the controls page; the list scrolls.
const CONTROL_ROWS := 9

var settings: Settings
var menu: MenuPanel
var page := Page.MAIN
## Action waiting for a new key on the capture page.
var capturing := ""
var _shade: ColorRect
var _capture_at := -1.0


func _init(player_settings: Settings) -> void:
	settings = player_settings


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.7)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	menu = MenuPanel.new()
	menu.chosen.connect(_on_chosen)
	add_child(menu)
	_set_visible(false)


func is_open() -> bool:
	return _shade.visible


## Opens the first page.
func open() -> void:
	_set_visible(true)
	show_main()


func close() -> void:
	capturing = ""
	_set_visible(false)
	closed.emit()


func show_main(start: int = 0) -> void:
	page = Page.MAIN
	capturing = ""
	# The player may have left full screen through the system.
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.window_get_mode()
		settings.fullscreen = mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	menu.show_menu("Configurações", "", [
		"Controles",
		"Tela cheia: %s" % YES_NO[int(settings.fullscreen)],
		"Pausar ao sair da janela: %s" % YES_NO[int(settings.pause_on_focus_loss)],
		"Gravar registro do playtest: %s" % YES_NO[int(settings.playtest_log)],
		"Voltar",
	], start, "volta")


## The list of actions; [param message] tells what the last change did.
func show_controls(start: int = 0, message: String = "") -> void:
	page = Page.CONTROLS
	capturing = ""
	var rows := PackedStringArray()
	for action: String in Controls.REBINDABLE:
		rows.append("%s: %s" % [Controls.NAMES[action], Controls.label(action)])
	rows.append("Restaurar os controles padrão")
	rows.append("Voltar")
	if message.is_empty():
		message = "Escolha uma ação e pressione a nova tecla ou botão do controle."
	menu.show_menu("Controles", message, rows, start, "volta", CONTROL_ROWS)


## Waits for the next key or button for [param action].
func start_capture(action: String) -> void:
	page = Page.CAPTURE
	capturing = action
	_capture_at = Time.get_ticks_msec() / 1000.0
	menu.show_menu("Nova tecla: %s" % Controls.NAMES[action],
		"Agora: %s\nPressione a tecla ou o botão do controle.\nOs gatilhos LT e RT não podem ser usados. Esc ou Start cancela." % Controls.label(action), [])


## Gives [param event] (a key or a gamepad button) to the action being
## captured. Returns false when the event is not one that can be bound.
func capture(event: InputEvent) -> bool:
	if capturing.is_empty():
		return false
	var action := capturing
	var back := Controls.REBINDABLE.find(action)
	var result := ""
	if event is InputEventKey:
		var key := event as InputEventKey
		var code := key.physical_keycode
		if code == KEY_NONE:
			return false
		if code == KEY_ESCAPE:
			show_controls(back)
			return true
		result = Controls.set_key(action, code)
	elif event is InputEventJoypadButton:
		var button := (event as InputEventJoypadButton).button_index
		if button == JOY_BUTTON_START:
			show_controls(back)
			return true
		result = Controls.set_button(action, button)
	else:
		return false
	_save_controls()
	show_controls(back, _result_text(action, result))
	return true


func _result_text(action: String, displaced: String) -> String:
	var now := "%s: %s." % [Controls.NAMES[action], Controls.label(action)]
	if displaced == "!":
		return "Essa tecla ou botão é reservado (Esc e Start abrem o menu; 1 a 4 são de teste)."
	if displaced.begins_with("-"):
		var other := displaced.substr(1)
		return "%s Saiu de %s, que continua com %s." % [now, Controls.NAMES[other], Controls.label(other)]
	if Controls.NAMES.has(displaced):
		return "%s Trocado com %s, que agora usa %s." % [now, Controls.NAMES[displaced], Controls.label(displaced)]
	return now


func _input(event: InputEvent) -> void:
	if page != Page.CAPTURE or not is_open() or not event.is_pressed() or event.is_echo():
		return
	if Time.get_ticks_msec() / 1000.0 - _capture_at < CAPTURE_GUARD:
		return
	if capture(event):
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# B on a controller (ui_cancel) also goes back, as in most games.
	if not is_open() or page == Page.CAPTURE or not (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		return
	if page == Page.CONTROLS:
		show_main(0)
	else:
		close()
	get_viewport().set_input_as_handled()


func _on_chosen(index: int) -> void:
	if page == Page.MAIN:
		match index:
			0:
				show_controls()
			1:
				settings.fullscreen = not settings.fullscreen
				settings.apply_window()
				_saved(index)
			2:
				settings.pause_on_focus_loss = not settings.pause_on_focus_loss
				_saved(index)
			3:
				settings.playtest_log = not settings.playtest_log
				_saved(index)
			_:
				close()
	elif page == Page.CONTROLS:
		var count := Controls.REBINDABLE.size()
		if index < count:
			start_capture(Controls.REBINDABLE[index])
		elif index == count:
			Controls.reset_defaults()
			_save_controls()
			show_controls(index, "Controles de volta ao padrão.")
		else:
			show_main(0)


func _saved(index: int) -> void:
	settings.save_file()
	changed.emit()
	show_main(index)


func _save_controls() -> void:
	settings.controls = Controls.to_dict()
	settings.save_file()
	changed.emit()


func _set_visible(value: bool) -> void:
	_shade.visible = value
	menu.visible = value
