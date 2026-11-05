class_name PauseOverlay
extends CanvasLayer
## Pauses the game on the pause action, on loss of window focus and when a
## gamepad disconnects (design/kit/plano-implementacao.md, step 1).

var _label: Label
var _shade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0.55)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	_label = Label.new()
	_label.text = "Pausado"
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	_set_visible(false)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree():
		set_paused(true)


## Pauses or resumes the whole tree and shows the overlay.
func set_paused(value: bool, reason: String = "Pausado") -> void:
	get_tree().paused = value
	_label.text = reason
	_set_visible(value)


func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected:
		set_paused(true, "Controle desconectado")


func _set_visible(value: bool) -> void:
	_shade.visible = value
	_label.visible = value
