class_name Settings
extends RefCounted
## Player preferences, kept apart from the save slots so starting a new game
## never loses them (design/kit/integracao-e-salvamento.md §7).

const PATH := "user://settings.cfg"

## Slot chosen last on the title screen (1–3).
var last_slot := 1
## Losing window focus pauses the game (integracao-e-salvamento.md §8).
var pause_on_focus_loss := true
## Writes the playtest record (Etapa 10) to user://playtest/.
var playtest_log := true
## Full-screen window instead of a window.
var fullscreen := false
## Remapped controls, as [method Controls.to_dict] writes them (empty: defaults).
var controls: Dictionary = {}

var _path: String


func _init(path: String = PATH) -> void:
	_path = path


## Reads the file; missing or unreadable values keep their defaults.
func load_file() -> Settings:
	var cfg := ConfigFile.new()
	if cfg.load(_path) != OK:
		return self
	# A hand-edited value of the wrong type keeps the default instead of
	# stopping the game at launch.
	var slot: Variant = cfg.get_value("game", "last_slot", last_slot)
	if slot is int:
		last_slot = clampi(slot, 1, SaveStore.SLOT_COUNT)
	var focus: Variant = cfg.get_value("game", "pause_on_focus_loss", pause_on_focus_loss)
	if focus is bool:
		pause_on_focus_loss = focus
	var log_on: Variant = cfg.get_value("game", "playtest_log", playtest_log)
	if log_on is bool:
		playtest_log = log_on
	var full: Variant = cfg.get_value("display", "fullscreen", fullscreen)
	if full is bool:
		fullscreen = full
	var binds: Variant = cfg.get_value("input", "controls", controls)
	if binds is Dictionary:
		controls = binds
	return self


func save_file() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "last_slot", last_slot)
	cfg.set_value("game", "pause_on_focus_loss", pause_on_focus_loss)
	cfg.set_value("game", "playtest_log", playtest_log)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("input", "controls", controls)
	return cfg.save(_path)


## Puts the saved controls and window mode into effect.
func apply() -> void:
	if controls.is_empty():
		Controls.reset_defaults()
	else:
		Controls.apply_dict(controls)
	apply_window()


## Full screen or windowed, as [member fullscreen] says (no-op headless).
func apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode:
		DisplayServer.window_set_mode(mode)
