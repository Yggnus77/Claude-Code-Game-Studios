extends TestCase
## Remappable controls (Controls): main key and button per action, swaps
## when a key is taken, reserved keys, saving and restoring.


func teardown() -> void:
	Controls.reset_defaults()


func test_defaults_have_the_kit_keys() -> void:
	Controls.reset_defaults()
	assert_eq(Controls.key_of("attack"), KEY_J, "sword on J")
	assert_eq(Controls.button_of("attack"), JOY_BUTTON_X, "sword on X")
	assert_eq(Controls.label("attack"), "J / X", "label")
	assert_eq(Controls.key_of("dodge"), KEY_SPACE, "dodge on Space")


func test_a_free_key_replaces_the_main_one() -> void:
	Controls.reset_defaults()
	assert_eq(Controls.set_key("attack", KEY_U), "", "nobody loses a key")
	assert_eq(Controls.key_of("attack"), KEY_U, "sword on U")
	assert_true(not _has_key("attack", KEY_J), "J is no longer the sword")


func test_a_taken_key_swaps_the_two_actions() -> void:
	Controls.reset_defaults()
	assert_eq(Controls.set_key("attack", KEY_K), "interact", "interact lost K")
	assert_eq(Controls.key_of("attack"), KEY_K, "sword on K")
	assert_eq(Controls.key_of("interact"), KEY_J, "interact got the sword's J")
	assert_true(not _has_key("interact", KEY_K), "K only on one action")


func test_moving_keeps_the_arrows_unless_taken() -> void:
	Controls.reset_defaults()
	Controls.set_key("move_up", KEY_I)
	assert_eq(Controls.key_of("move_up"), KEY_I, "up on I")
	assert_true(_has_key("move_up", KEY_UP), "the up arrow still works")
	assert_true(not _has_key("move_up", KEY_W), "W left")
	# Taking a spare key is not a swap: up keeps its main key.
	assert_eq(Controls.set_key("attack", KEY_UP), "-move_up", "the arrow only left up")
	assert_eq(Controls.key_of("move_up"), KEY_I, "up still on I")
	assert_true(not _has_key("move_up", KEY_UP), "the arrow is the sword's now")


func test_a_spare_key_made_main_trades_places() -> void:
	Controls.reset_defaults()
	assert_eq(Controls.set_key("move_up", KEY_UP), "", "nobody else changes")
	assert_eq(Controls.key_of("move_up"), KEY_UP, "up on the arrow")
	assert_true(_has_key("move_up", KEY_W), "W still moves up")
	var count := 0
	for ev in InputMap.action_get_events("move_up"):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == KEY_UP:
			count += 1
	assert_eq(count, 1, "the arrow appears once")


func test_reserved_keys_and_buttons_are_refused() -> void:
	Controls.reset_defaults()
	assert_eq(Controls.set_key("attack", KEY_ESCAPE), "!", "Esc opens the menu")
	assert_eq(Controls.set_button("attack", JOY_BUTTON_START), "!", "Start opens the menu")
	assert_eq(Controls.set_key("attack", KEY_1), "!", "1-4 are the test keys")
	assert_eq(Controls.key_of("attack"), KEY_J, "unchanged")
	assert_eq(Controls.button_of("attack"), JOY_BUTTON_X, "unchanged")
	assert_eq(Controls.key_of("spawn_1"), KEY_1, "the test key stays")


func test_buttons_swap_like_keys() -> void:
	Controls.reset_defaults()
	assert_eq(Controls.set_button("attack", JOY_BUTTON_A), "interact", "interact lost A")
	assert_eq(Controls.button_of("attack"), JOY_BUTTON_A, "sword on A")
	assert_eq(Controls.button_of("interact"), JOY_BUTTON_X, "interact on X")
	var pad := InputEventJoypadButton.new()
	pad.device = 1
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	assert_true(pad.is_action("attack"), "works from a second controller too")


func test_saved_choices_come_back() -> void:
	Controls.reset_defaults()
	Controls.set_key("attack", KEY_K)
	Controls.set_key("dodge", KEY_E)
	Controls.set_button("item", JOY_BUTTON_B)
	Controls.set_key("quick_swap", KEY_LEFT)  # left loses its spare arrow
	var saved := Controls.to_dict()
	Controls.reset_defaults()
	assert_eq(Controls.key_of("attack"), KEY_J, "reset")
	Controls.apply_dict(saved)
	assert_eq(Controls.to_dict(), saved, "same bindings after loading")
	assert_eq(Controls.key_of("interact"), KEY_J, "the swap comes back too")
	assert_true(not _has_key("move_left", KEY_LEFT), "a spare key taken away stays away")


func test_bad_saved_values_are_ignored() -> void:
	Controls.apply_dict({
		"attack": {"keys": ["J", -5, 99999999], "buttons": [999, JOY_BUTTON_START]},
		"spawn_1": {"keys": [KEY_U]},
		"dodge": 3,
		"guard": {"keys": [KEY_1]},
		"item": {"keys": [float(KEY_U)]},
	})
	assert_eq(Controls.key_of("attack"), KEY_J, "no valid key: default kept")
	assert_eq(Controls.button_of("attack"), JOY_BUTTON_X, "no valid button: default kept")
	assert_eq(Controls.key_of("spawn_1"), KEY_1, "not a remappable action")
	assert_eq(Controls.key_of("dodge"), KEY_SPACE, "not a dictionary")
	assert_eq(Controls.key_of("guard"), KEY_SHIFT, "a test key cannot be loaded")
	assert_eq(Controls.key_of("item"), KEY_U, "a float still loads")


func _has_key(action: String, keycode: int) -> bool:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev as InputEventKey).physical_keycode == keycode:
			return true
	return false
