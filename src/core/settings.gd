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
	return self


func save_file() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "last_slot", last_slot)
	cfg.set_value("game", "pause_on_focus_loss", pause_on_focus_loss)
	cfg.set_value("game", "playtest_log", playtest_log)
	return cfg.save(_path)
