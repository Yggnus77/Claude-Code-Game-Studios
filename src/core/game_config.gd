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
const ITEMS_PATH := "res://assets/data/itens.json"
const REWARDS_PATH := "res://assets/data/recompensas-mundo.json"
const ENCOUNTERS_PATH := "res://assets/data/chefes.json"
const MYSTERIES_PATH := "res://assets/data/misterios.json"
const TOWER_PATH := "res://assets/data/torre-akurame.json"
const RELIC_BASE_PATH := "res://assets/data/base-modificadores-reliquias.json"
const MYSTERY_WIRING_PATH := "res://assets/data/misterios-ligacao.json"

## The parsed combat document (combate.json).
var data: Dictionary
## Enemy definitions from inimigos.json, keyed by id.
var enemies: Dictionary = {}
## economia-progressao.json (starting life, currency, prices...).
var progression: Dictionary = {}
## Item definitions from itens.json, keyed by id.
var items: Dictionary = {}
## World rewards from recompensas-mundo.json, keyed by reward id.
var rewards: Dictionary = {}
## Prototype fragments from recompensas-mundo.json, keyed by fragment id.
var fragments: Dictionary = {}
## Boss and story encounters from chefes.json, keyed by id.
var encounters: Dictionary = {}
## Optional mysteries from misterios.json, keyed by id.
var mysteries: Dictionary = {}
## Torre Akurame wiring (torre-akurame.json): room triggers, clear flags,
## hook, counterweight and bell puzzle.
var tower: Dictionary = {}
## Base numbers that relics modify (base-modificadores-reliquias.json).
var relic_base: Dictionary = {}
## Where each mystery lives in the world (misterios-ligacao.json).
var mystery_wiring: Dictionary = {}


func _init(source: Dictionary = {}, enemy_list: Array = [], progression_data: Dictionary = {}) -> void:
	data = source
	for e in enemy_list:
		enemies[str(e.get("id", ""))] = e
	progression = progression_data


## Loads combate.json, inimigos.json and economia-progressao.json.
static func load_all() -> GameConfig:
	var combat := read_json(DEFAULT_PATH)
	var enemy_doc := read_json(ENEMIES_PATH)
	var cfg := GameConfig.new(combat, enemy_doc.get("enemies", []), read_json(PROGRESSION_PATH))
	for item in read_json(ITEMS_PATH).get("items", []):
		cfg.items[str(item["id"])] = item
	var world := read_json(REWARDS_PATH)
	for r in world.get("rewards", []):
		cfg.rewards[str(r["id"])] = r
	for f in world.get("fragments", []):
		cfg.fragments[str(f["id"])] = f
	for e in read_json(ENCOUNTERS_PATH).get("encounters", []):
		cfg.encounters[str(e["id"])] = e
	for m in read_json(MYSTERIES_PATH).get("mysteries", []):
		cfg.mysteries[str(m["id"])] = m
	cfg.tower = read_json(TOWER_PATH)
	cfg.relic_base = read_json(RELIC_BASE_PATH)
	cfg.mystery_wiring = read_json(MYSTERY_WIRING_PATH)
	return cfg


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


## Flags a clue setting [param clue_flag] waits for before it can be noted:
## the owning mystery's "requires_flags" (m01 opens after Igris's record,
## seen.t11). Empty when the clue belongs to no mystery.
func clue_requirements(clue_flag: String) -> Array:
	for m in mysteries.values():
		for c in m.get("clues", []):
			if str(c.get("id", "")) == clue_flag:
				return m.get("requires_flags", [])
	return []


## Mysteries wired into the prototype world, as [MysteryQuest]s keyed by id.
func mystery_quests() -> Dictionary:
	var out := {}
	var wired: Dictionary = mystery_wiring.get("mysteries", {})
	for id: String in wired:
		if mysteries.has(id):
			out[id] = MysteryQuest.new(mysteries[id], wired[id])
	return out


## The relic slot rules built from the base file and every mystery reward.
func relic_loadout() -> RelicLoadout:
	return RelicLoadout.new(relic_base, mysteries.values())


## Encounter [param id] from chefes.json, or {}.
func encounter(id: String) -> Dictionary:
	return encounters.get(id, {})


## Starting life (economia-progressao.json vida.inicial).
func starting_life() -> int:
	return int(progression.get("vida", {}).get("inicial", 6))


## Display name of [param item_id] (falls back to the id).
func item_name(item_id: String) -> String:
	return str(items.get(item_id, {}).get("name", item_id))


## The GameState effects that hand out world reward [param reward_id]
## (an item or Bronze, guarded by the reward's receipt). Empty if unknown.
func reward_effects(reward_id: String) -> Array:
	var r: Dictionary = rewards.get(reward_id, {})
	if r.is_empty():
		return []
	var receipt := str(r.get("receipt", "reward.%s" % reward_id))
	if r.has("bronze"):
		return [{"op": "grant_bronze_unique", "amount": int(r["bronze"]), "receipt_id": receipt}]
	return [{"op": "grant_unique", "item_id": str(r["item"]), "quantity": int(r.get("quantity", 1)), "receipt_id": receipt}]


## Receipt id of world reward [param reward_id], or "".
func reward_receipt(reward_id: String) -> String:
	var r: Dictionary = rewards.get(reward_id, {})
	return "" if r.is_empty() else str(r.get("receipt", "reward.%s" % reward_id))
