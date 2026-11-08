class_name PauseOverlay
extends CanvasLayer
## Pauses the game on the pause action, on loss of window focus and when a
## gamepad disconnects (design/kit/plano-implementacao.md, step 1;
## integracao-e-salvamento.md §8), with a menu to continue, go back to the
## title screen or quit. Progress is saved before leaving.

## The settings menu changed something (already saved).
signal settings_screen_changed

## Returns true while something else (a scene, the inventory) holds the pause.
var is_blocked: Callable = func() -> bool: return false
## Leaves for the title screen; unset hides that option.
var on_title: Callable = Callable()
## Saves and closes the game.
var on_quit: Callable = func() -> void: get_tree().quit()
## Opens the folder of the playtest records; unset hides that option.
var on_open_logs: Callable = Callable()
## Whether losing window focus pauses (Settings.pause_on_focus_loss).
var pause_on_focus_loss := true
## Player settings; set, the menu offers "Configurações".
var settings: Settings
## The settings menu, made the first time it opens.
var settings_screen: SettingsScreen
var menu: MenuPanel
var _shade: ColorRect
var _paused_by_me := false
var _actions: Array[Callable] = []
var _reason := "Pausado"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.55)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	menu = MenuPanel.new()
	menu.chosen.connect(func(i: int) -> void: _actions[i].call())
	add_child(menu)
	_set_visible(false)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func is_paused() -> bool:
	return _paused_by_me


func is_settings_open() -> bool:
	return settings_screen != null and settings_screen.is_open()


## Opens the settings menu over the pause menu (pausing first if needed).
func open_settings() -> void:
	if settings == null:
		return
	if not _paused_by_me:
		set_paused(true)
	if settings_screen == null:
		settings_screen = SettingsScreen.new(settings)
		add_child(settings_screen)
		settings_screen.closed.connect(_on_settings_closed)
		settings_screen.changed.connect(_on_settings_changed)
	menu.visible = false
	settings_screen.open()


func _on_settings_changed() -> void:
	pause_on_focus_loss = settings.pause_on_focus_loss
	settings_screen_changed.emit()


func _on_settings_closed() -> void:
	if _paused_by_me:
		set_paused(true, _reason, _actions.find(open_settings))


func _unhandled_input(event: InputEvent) -> void:
	if is_settings_open():
		return
	if event.is_action_pressed("pause") and (_paused_by_me or not is_blocked.call()):
		set_paused(not _paused_by_me)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	var on_focus_loss := settings.pause_on_focus_loss if settings != null else pause_on_focus_loss
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and on_focus_loss and is_inside_tree() and not _paused_by_me and not is_blocked.call():
		set_paused(true)


## Pauses or resumes the whole tree and shows the menu.
func set_paused(value: bool, reason: String = "Pausado", start: int = 0) -> void:
	_paused_by_me = value
	_reason = reason
	get_tree().paused = value
	if not value and settings_screen != null and settings_screen.is_open():
		settings_screen.close()
	if value:
		var labels := PackedStringArray(["Continuar"])
		_actions = [func() -> void: set_paused(false)]
		if settings != null:
			labels.append("Configurações")
			_actions.append(open_settings)
		if on_title.is_valid():
			labels.append("Salvar e voltar ao título")
			_actions.append(on_title)
		labels.append("Salvar e sair do jogo")
		_actions.append(on_quit)
		if on_open_logs.is_valid():
			labels.append("Abrir a pasta dos registros de teste")
			_actions.append(on_open_logs)
		menu.show_menu(reason, "", labels, maxi(0, start), "continua")
	_set_visible(value)


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and not is_blocked.call():
		set_paused(true, "Controle desconectado")


func _set_visible(value: bool) -> void:
	_shade.visible = value
	menu.visible = value and not is_settings_open()
