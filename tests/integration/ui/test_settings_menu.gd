extends TestCase
## The settings menu (SettingsScreen) from the pause menu and the title
## screen: toggles saved at once, new keys captured, back with the pause key.

const PATH := "user://test_settings_menu.cfg"

var _nodes: Array[Node] = []


func teardown() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
	tree.paused = false
	Controls.reset_defaults()
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)


func _screen() -> SettingsScreen:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	Controls.reset_defaults()
	var s := SettingsScreen.new(Settings.new(PATH))
	tree.root.add_child(s)
	_nodes.append(s)
	s.open()
	return s


func _key(code: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.pressed = true
	return ev


func test_toggles_are_saved_at_once() -> void:
	var s := _screen()
	s.menu.selected = 2
	s.menu.confirm()
	assert_true(not s.settings.pause_on_focus_loss, "pause on focus loss off")
	assert_true(s.menu.options[2].ends_with("Não"), "the row says so: %s" % s.menu.options[2])
	assert_eq(s.menu.selected, 2, "the same row stays highlighted")
	var again := Settings.new(PATH).load_file()
	assert_true(not again.pause_on_focus_loss, "saved to the file")


func test_choosing_an_action_takes_the_next_key() -> void:
	var s := _screen()
	s.menu.confirm()  # Controles
	assert_eq(s.page, SettingsScreen.Page.CONTROLS, "controls page")
	assert_eq(s.menu.options.size(), Controls.REBINDABLE.size() + 2, "every action, reset and back")
	s.menu.selected = Controls.REBINDABLE.find("attack")
	s.menu.confirm()
	assert_eq(s.capturing, "attack", "waiting for the sword's key")
	assert_true(s.capture(_key(KEY_K)), "K taken")
	assert_eq(Controls.key_of("attack"), KEY_K, "sword on K")
	assert_eq(Controls.key_of("interact"), KEY_J, "swapped")
	assert_true(s.menu._message.text.contains("Trocado"), "the swap is told: %s" % s.menu._message.text)
	var again := Settings.new(PATH).load_file()
	assert_eq(int(again.controls["attack"]["keys"][0]), KEY_K, "saved")
	again.apply()
	assert_eq(Controls.key_of("attack"), KEY_K, "loads back")


func test_escape_cancels_a_capture_and_buttons_bind() -> void:
	var s := _screen()
	s.show_controls()
	s.start_capture("interact")
	assert_true(s.capture(_key(KEY_ESCAPE)), "Esc handled")
	assert_eq(s.page, SettingsScreen.Page.CONTROLS, "back to the list")
	assert_eq(Controls.key_of("interact"), KEY_K, "unchanged")
	s.start_capture("interact")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_RIGHT_SHOULDER
	pad.pressed = true
	assert_true(s.capture(pad), "a button binds")
	assert_eq(Controls.button_of("interact"), JOY_BUTTON_RIGHT_SHOULDER, "examine on RB")
	assert_eq(Controls.button_of("quick_swap"), JOY_BUTTON_A, "swap got A")


func test_restore_defaults() -> void:
	var s := _screen()
	s.show_controls()
	s.start_capture("item")
	s.capture(_key(KEY_U))
	s.menu.selected = Controls.REBINDABLE.size()
	s.menu.confirm()
	assert_eq(Controls.key_of("item"), KEY_L, "back to L")
	assert_eq(int(Settings.new(PATH).load_file().controls["item"]["keys"][0]), KEY_L, "saved")


func test_pause_menu_opens_and_returns() -> void:
	var p := PauseOverlay.new()
	p.settings = Settings.new(PATH)
	tree.root.add_child(p)
	_nodes.append(p)
	p.set_paused(true)
	assert_eq(p.menu.options[1], "Configurações", "second option")
	p.menu.selected = 1
	p.menu.confirm()
	assert_true(p.is_settings_open(), "settings open")
	assert_true(not p.menu.visible, "pause menu hidden under it")
	p.settings_screen.close()
	assert_true(p.menu.visible, "pause menu back")
	assert_eq(p.menu.selected, 1, "on Configurações")
	assert_true(tree.paused, "still paused")
	p.set_paused(false)


func test_title_screen_lists_settings() -> void:
	var dir := "user://test_settings_menu_saves"
	var t := TitleScreen.new(SaveStore.new(dir, func(_d: Dictionary) -> Array: return []))
	t.settings = Settings.new(PATH)
	tree.root.add_child(t)
	_nodes.append(t)
	assert_eq(t.menu.options[SaveStore.SLOT_COUNT], "Configurações", "after the slots")
	t.menu.selected = SaveStore.SLOT_COUNT
	t.menu.confirm()
	assert_true(t.settings_screen.is_open(), "opens")
	t.settings_screen.close()
	assert_true(t.menu.visible, "slot list back")
	assert_eq(t.menu.selected, SaveStore.SLOT_COUNT, "on Configurações")


func test_focus_option_changed_on_the_title_reaches_the_pause_menu() -> void:
	var p := PauseOverlay.new()
	p.settings = Settings.new(PATH)
	tree.root.add_child(p)
	_nodes.append(p)
	p.settings.pause_on_focus_loss = false
	p._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_true(not p.is_paused(), "the shared setting is read, not a stale copy")
