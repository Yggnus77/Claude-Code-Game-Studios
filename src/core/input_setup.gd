extends Node
## Registers the default input actions at startup so they live in one place
## and can be remapped later (design/kit/mecanicas-e-dificuldade.md, section 3).
## Keyboard and gamepad (Xbox layout names) are both bound.

## Analog stick dead zone for the four movement actions.
const STICK_DEADZONE := 0.2

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"attack": [KEY_J],
	"interact": [KEY_K],
	"dodge": [KEY_SPACE],
	"item": [KEY_L],
	"guard": [KEY_SHIFT],
	"quick_swap": [KEY_Q],
	"map": [KEY_TAB],
	"pause": [KEY_ESCAPE],
	"reset_room": [KEY_R],
	"spawn_1": [KEY_1],
	"spawn_2": [KEY_2],
	"spawn_3": [KEY_3],
	"spawn_4": [KEY_4],
}

const BUTTONS := {
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"attack": [JOY_BUTTON_X],
	"interact": [JOY_BUTTON_A],
	"dodge": [JOY_BUTTON_B],
	"item": [JOY_BUTTON_Y],
	"guard": [JOY_BUTTON_LEFT_SHOULDER],
	"quick_swap": [JOY_BUTTON_RIGHT_SHOULDER],
	"map": [JOY_BUTTON_BACK],
	"pause": [JOY_BUTTON_START],
}

const AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
}


func _ready() -> void:
	register_defaults()


## Adds every default action that is not already defined. Safe to call twice.
static func register_defaults() -> void:
	for action in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, STICK_DEADZONE if AXES.has(action) else 0.5)
		for key in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for button in BUTTONS.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = button
			InputMap.action_add_event(action, jb)
		if AXES.has(action):
			var jm := InputEventJoypadMotion.new()
			jm.axis = AXES[action][0]
			jm.axis_value = AXES[action][1]
			InputMap.action_add_event(action, jm)
