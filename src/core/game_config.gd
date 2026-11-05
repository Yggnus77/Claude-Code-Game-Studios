class_name GameConfig
extends RefCounted
## Read-only access to the gameplay numbers in assets/data/combate.json.
##
## Every tunable value used by movement and combat comes from that file
## (design/kit/mecanicas-e-dificuldade.md is the source of each number).
## Pass a GameConfig into the systems that need it instead of reading the
## file from inside them, so tests can build one from a plain Dictionary.

const DEFAULT_PATH := "res://assets/data/combate.json"

## The parsed JSON document.
var data: Dictionary


func _init(source: Dictionary = {}) -> void:
	data = source


## Loads the combat config from [param path]. Returns an empty config and
## pushes an error when the file is missing or is not a JSON object.
static func load_from(path: String = DEFAULT_PATH) -> GameConfig:
	var text := FileAccess.get_file_as_string(path)
	if text.is_empty():
		push_error("GameConfig: cannot read %s" % path)
		return GameConfig.new()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameConfig: %s is not a JSON object" % path)
		return GameConfig.new()
	return GameConfig.new(parsed)


## Player movement parameters (speed, acceleration, deceleration, ...).
func player() -> Dictionary:
	return data.get("player", {})


## Size in pixels of one map tile.
func tile_size() -> int:
	return int(data.get("tile_size", 16))
