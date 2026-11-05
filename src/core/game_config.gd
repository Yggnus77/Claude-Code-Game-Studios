class_name GameConfig
extends RefCounted
## Read-only access to the gameplay numbers in assets/data/combate.json.
##
## Every tunable value used by movement and combat comes from that file
## (design/kit/mecanicas-e-dificuldade.md is the source of each number).
## Pass a GameConfig into the systems that need it instead of reading the
## file from inside them, so tests can build one from a plain Dictionary.

const DEFAULT_PATH := "res://assets/data/combate.json"
const ENEMIES_PATH := "res://assets/data/inimigos.json"
const PROGRESSION_PATH := "res://assets/data/economia-progressao.json"

## The parsed combat document (combate.json).
var data: Dictionary
## Enemy definitions from inimigos.json, keyed by id.
var enemies: Dictionary = {}
## economia-progressao.json (starting life, currency, prices...).
var progression: Dictionary = {}


func _init(source: Dictionary = {}, enemy_list: Array = [], progression_data: Dictionary = {}) -> void:
	data = source
	for e in enemy_list:
		enemies[str(e.get("id", ""))] = e
	progression = progression_data


## Loads combate.json, inimigos.json and economia-progressao.json.
static func load_all() -> GameConfig:
	var combat := read_json(DEFAULT_PATH)
	var enemy_doc := read_json(ENEMIES_PATH)
	return GameConfig.new(combat, enemy_doc.get("enemies", []), read_json(PROGRESSION_PATH))


## Reads a JSON object from [param path]; empty Dictionary (and an error) on failure.
static func read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GameConfig: cannot read JSON object from %s" % path)
		return {}
	return parsed


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


## Three-hit combo timings (combate.json "combo").
func combo() -> Array:
	return data.get("combo", [])


## Per-hit damage for [param weapon_id] (combate.json "weapons").
func weapon_damage(weapon_id: String) -> Array:
	return data.get("weapons", {}).get(weapon_id, [])


func dodge() -> Dictionary:
	return data.get("dodge", {})


func guard() -> Dictionary:
	return data.get("guard", {})


## Definition of enemy [param id], or an empty Dictionary.
func enemy(id: String) -> Dictionary:
	return enemies.get(id, {})


## Starting life (economia-progressao.json vida.inicial).
func starting_life() -> int:
	return int(progression.get("vida", {}).get("inicial", 6))
