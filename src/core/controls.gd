class_name Controls
extends RefCounted
## Remappable controls: which key and which gamepad button each action uses,
## changed from the settings menu and saved in [Settings]. Works on the
## project's InputMap (defaults in input_setup.gd). Each action has one main
## key and one main button the player can change; other default keys (the
## arrows next to WASD) stay unless the new key takes them.

const Defaults := preload("res://src/core/input_setup.gd")

## Actions the player can remap, in menu order. Pause stays on Esc/Start so
## the menu itself can always be reached.
## Guard and dodge are not here: the shield is passive and the dash waits for
## an item (design/gdd/jogabilidade-classica.md §1).
const REBINDABLE := ["move_up", "move_down", "move_left", "move_right", "attack",
	"interact", "item", "quick_swap", "map", "history", "skip_scene", "reset_room"]

## Names shown in the menu.
const NAMES := {
	"move_up": "Andar para cima", "move_down": "Andar para baixo", "move_left": "Andar para a esquerda",
	"move_right": "Andar para a direita", "attack": "Espada", "dodge": "Esquiva",
	"interact": "Examinar / confirmar", "item": "Usar item", "quick_swap": "Trocar item", "map": "Inventário",
	"history": "Histórico de falas", "skip_scene": "Pular cena", "reset_room": "Reiniciar sala",
}

## Keys that can never be taken by an action (they open/close the menu).
## The test keys 1-4 (spawn_*) are kept too: see [method is_key_allowed].
const RESERVED_KEYS := [KEY_ESCAPE]
const RESERVED_BUTTONS := [JOY_BUTTON_START]

## Highest keycode a saved file may name (Godot's key codes stay below it).
const KEY_MAX_VALUE := 0x7FFFFF

const KEY_NAMES := {
	KEY_SPACE: "Espaço", KEY_SHIFT: "Shift", KEY_CTRL: "Ctrl", KEY_ALT: "Alt", KEY_TAB: "Tab",
	KEY_ENTER: "Enter", KEY_BACKSPACE: "Apagar", KEY_ESCAPE: "Esc", KEY_UP: "↑", KEY_DOWN: "↓",
	KEY_LEFT: "←", KEY_RIGHT: "→", KEY_NONE: "—", KEY_DELETE: "Delete", KEY_INSERT: "Insert",
	KEY_HOME: "Home", KEY_END: "End", KEY_PAGEUP: "Page Up", KEY_PAGEDOWN: "Page Down",
	KEY_CAPSLOCK: "Caps Lock", KEY_SEMICOLON: ";", KEY_APOSTROPHE: "'", KEY_COMMA: ",",
	KEY_PERIOD: ".", KEY_SLASH: "/", KEY_BACKSLASH: "\\", KEY_BRACKETLEFT: "[", KEY_BRACKETRIGHT: "]",
	KEY_MINUS: "-", KEY_EQUAL: "=", KEY_QUOTELEFT: "`", KEY_KP_ENTER: "Enter (num)",
}
const BUTTON_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB", JOY_BUTTON_BACK: "Back",
	JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "Direcional ↑", JOY_BUTTON_DPAD_DOWN: "Direcional ↓", JOY_BUTTON_DPAD_LEFT: "Direcional ←",
	JOY_BUTTON_DPAD_RIGHT: "Direcional →", JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_MISC1: "Share",
}


## The main key of [param action] (physical keycode), or KEY_NONE.
static func key_of(action: String) -> int:
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				return (ev as InputEventKey).physical_keycode
	return KEY_NONE


## The main gamepad button of [param action], or -1.
static func button_of(action: String) -> int:
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton:
				return (ev as InputEventJoypadButton).button_index
	return -1


## The name of the key at [param keycode] (a physical position) as printed
## on the player's keyboard: on AZERTY the W position shows "Z".
static func key_label(keycode: int) -> String:
	if keycode == KEY_NONE:
		return KEY_NAMES[KEY_NONE]
	var shown := keycode
	# Only printable keys move with the layout; special keys (numpad, arrows)
	# keep their own name, which the layout or Num Lock would otherwise change.
	if keycode < KEY_SPECIAL and DisplayServer.get_name() != "headless":
		var mapped := DisplayServer.keyboard_get_label_from_physical(keycode as Key)
		if mapped != KEY_NONE:
			shown = mapped
	if KEY_NAMES.has(shown):
		return KEY_NAMES[shown]
	var text := OS.get_keycode_string(shown)
	return text.replace("Kp ", "Num ") if not text.is_empty() else "?"


static func button_label(button: int) -> String:
	return BUTTON_NAMES.get(button, "—" if button < 0 else "Botão %d" % button)


## "J / X": the key and the button of [param action].
static func label(action: String) -> String:
	return "%s / %s" % [key_label(key_of(action)), button_label(button_of(action))]


## Whether [param keycode] can be bound: a real key, not one kept for the
## menu (Esc) or for an action the player cannot remap (the test keys 1-4).
static func is_key_allowed(keycode: int) -> bool:
	if keycode <= KEY_NONE or keycode > KEY_MAX_VALUE or RESERVED_KEYS.has(keycode):
		return false
	for other: String in Defaults.KEYS:
		if not REBINDABLE.has(other) and _has_key(other, keycode):
			return false
	return true


static func is_button_allowed(button: int) -> bool:
	if button < 0 or button >= JOY_BUTTON_SDL_MAX or RESERVED_BUTTONS.has(button):
		return false
	for other: String in Defaults.KEYS:
		if not REBINDABLE.has(other) and _has_button(other, button):
			return false
	return true


## Makes [param keycode] the main key of [param action]. If it was another
## action's main key, that action gets [param action]'s old key in exchange,
## so no action is left without a key. If it was only another action's spare
## key (an arrow next to WASD), that action just loses it. If [param action]
## already had it as a spare key, the two trade places.
## Returns the action that took the old key in a swap, "-" plus the action
## that only lost a spare key, "" when nobody else changed, or "!" when the
## key cannot be bound.
static func set_key(action: String, keycode: int) -> String:
	if not is_key_allowed(keycode):
		return "!"
	var old := key_of(action)
	if old == keycode:
		return ""
	var result := ""
	for other: String in REBINDABLE:
		if other == action or not _has_key(other, keycode):
			continue
		var was_main := key_of(other) == keycode
		_erase_key(other, keycode)
		if was_main and old != KEY_NONE:
			_put_main(other, _key_event(old))
			result = other
		else:
			result = "-" + other
	_put_main(action, _key_event(keycode), not _has_key(action, keycode))
	return result


## Makes [param button] the main gamepad button of [param action], swapping
## like [method set_key], with the same results.
static func set_button(action: String, button: int) -> String:
	if not is_button_allowed(button):
		return "!"
	var old := button_of(action)
	if old == button:
		return ""
	var result := ""
	for other: String in REBINDABLE:
		if other == action or not _has_button(other, button):
			continue
		var was_main := button_of(other) == button
		for ev in InputMap.action_get_events(other):
			if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).button_index == button:
				InputMap.action_erase_event(other, ev)
		if was_main and old >= 0:
			_put_main(other, _button_event(old))
			result = other
		else:
			result = "-" + other
	_put_main(action, _button_event(button), not _has_button(action, button))
	return result


## Puts every action back on its default keys and buttons.
static func reset_defaults() -> void:
	for action: String in Defaults.KEYS:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
	Defaults.register_defaults()


## The player's choices, for [Settings]: {action: {"keys": [int], "buttons":
## [int]}}, main one first. Every key is kept, so a spare key that was taken
## away stays away after a restart.
static func to_dict() -> Dictionary:
	var out := {}
	for action: String in REBINDABLE:
		var keys: Array[int] = []
		var buttons: Array[int] = []
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				keys.append((ev as InputEventKey).physical_keycode)
			elif ev is InputEventJoypadButton:
				buttons.append((ev as InputEventJoypadButton).button_index)
		out[action] = {"keys": keys, "buttons": buttons}
	return out


## Applies a dictionary saved by [method to_dict] on top of the defaults.
## Unknown actions, values of the wrong type and keys that cannot be bound
## are ignored; an action with no valid key keeps its default ones.
static func apply_dict(d: Dictionary) -> void:
	reset_defaults()
	var keys_of := {}
	var buttons_of := {}
	for action: Variant in d:
		if not REBINDABLE.has(action) or not d[action] is Dictionary:
			continue
		var entry: Dictionary = d[action]
		var keys := _valid_list(entry.get("keys"), is_key_allowed)
		if not keys.is_empty():
			keys_of[action] = keys
		var buttons := _valid_list(entry.get("buttons"), is_button_allowed)
		if not buttons.is_empty():
			buttons_of[action] = buttons
	# Free every saved key first, so an action's saved key never lands on
	# another action that still has it by default.
	for action: String in keys_of:
		for code: int in keys_of[action]:
			for other: String in REBINDABLE:
				_erase_key(other, code)
	for action: String in buttons_of:
		for button: int in buttons_of[action]:
			for other: String in REBINDABLE:
				for ev in InputMap.action_get_events(other):
					if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).button_index == button:
						InputMap.action_erase_event(other, ev)
	for action: String in REBINDABLE:
		var events := InputMap.action_get_events(action)
		var keep_keys := not keys_of.has(action)
		var keep_buttons := not buttons_of.has(action)
		InputMap.action_erase_events(action)
		if not keep_keys:
			for code: int in keys_of[action]:
				InputMap.action_add_event(action, _key_event(code))
		if not keep_buttons:
			for button: int in buttons_of[action]:
				InputMap.action_add_event(action, _button_event(button))
		for ev in events:
			var is_key := ev is InputEventKey
			var is_button := ev is InputEventJoypadButton
			if (is_key and keep_keys) or (is_button and keep_buttons) or not (is_key or is_button):
				InputMap.action_add_event(action, ev)


## The distinct whole numbers of [param list] that [param allowed] accepts.
static func _valid_list(list: Variant, allowed: Callable) -> Array[int]:
	var out: Array[int] = []
	if not list is Array:
		return out
	for v: Variant in list:
		if (v is int or v is float) and allowed.call(int(v)) and not out.has(int(v)):
			out.append(int(v))
	return out


static func _has_key(action: String, keycode: int) -> bool:
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
				return true
	return false


static func _has_button(action: String, button: int) -> bool:
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).button_index == button:
				return true
	return false


static func _erase_key(action: String, keycode: int) -> void:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
			InputMap.action_erase_event(action, ev)


static func _key_event(keycode: int) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode as Key
	return ev


static func _button_event(button: int) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	# Any controller, not only the first one connected.
	ev.device = -1
	ev.button_index = button as JoyButton
	return ev


## Adds [param ev] as the first event of its kind in [param action]; with
## [param replace] the previous first one of that kind is dropped.
static func _put_main(action: String, ev: InputEvent, replace: bool = false) -> void:
	var events := InputMap.action_get_events(action)
	# Drop a copy of [param ev] (a secondary key made main), so it is not listed twice.
	var same_kind := events.filter(func(e: InputEvent) -> bool: return e.get_class() == ev.get_class() and not _same_input(e, ev))
	var others := events.filter(func(e: InputEvent) -> bool: return e.get_class() != ev.get_class())
	if replace and not same_kind.is_empty():
		same_kind.remove_at(0)
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, ev)
	for e: InputEvent in same_kind + others:
		InputMap.action_add_event(action, e)


static func _same_input(a: InputEvent, b: InputEvent) -> bool:
	if a is InputEventKey and b is InputEventKey:
		return (a as InputEventKey).physical_keycode == (b as InputEventKey).physical_keycode
	if a is InputEventJoypadButton and b is InputEventJoypadButton:
		return (a as InputEventJoypadButton).button_index == (b as InputEventJoypadButton).button_index
	return false
