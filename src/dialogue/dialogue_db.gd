class_name DialogueDB
extends RefCounted
## The scenes of assets/data/dialogos.pt-BR.json, looked up by trigger
## (design/kit/integracao-e-salvamento.md §3–4). Flags are plain strings;
## nothing in the data is ever executed as code.

const DEFAULT_PATH := "res://assets/data/dialogos.pt-BR.json"
## Minimum seconds between two plays of the same bark.
const BARK_COOLDOWN := 12.0

var scenes: Dictionary = {}
var _by_trigger: Dictionary = {}
var _last_played: Dictionary = {}


func _init(scene_list: Array = []) -> void:
	for s in scene_list:
		scenes[str(s["id"])] = s
		var t := str(s.get("trigger_id", ""))
		if not _by_trigger.has(t):
			_by_trigger[t] = []
		_by_trigger[t].append(s)


static func load_from(path: String = DEFAULT_PATH) -> DialogueDB:
	return DialogueDB.new(GameConfig.read_json(path).get("scenes", []))


## True when [param scene] may play now for [param state].
func is_eligible(scene: Dictionary, state: GameState, now: float) -> bool:
	for f in scene.get("requires_all", []):
		if not state.has_flag(f):
			return false
	for f in scene.get("requires_none", []):
		if state.has_flag(f):
			return false
	var need: Dictionary = scene.get("requires_items", {})
	for id in need:
		if state.item_count(id) < int(need[id]):
			return false
	if not bool(scene.get("repeatable", false)) and state.has_flag("seen.%s" % scene["id"]):
		return false
	var cooldown := float(scene.get("cooldown_seconds", 0))
	if scene.get("delivery", "") == "bark":
		cooldown = maxf(cooldown, BARK_COOLDOWN)
	var id := str(scene["id"])
	if _last_played.has(id) and now - float(_last_played[id]) < cooldown:
		return false
	return true


## The highest-priority eligible scene for [param trigger], or {}.
func scene_for(trigger: String, state: GameState, now: float) -> Dictionary:
	var best: Dictionary = {}
	for s in _by_trigger.get(trigger, []):
		if is_eligible(s, state, now) and (best.is_empty() or int(s.get("priority", 0)) > int(best.get("priority", 0))):
			best = s
	return best


## Records that [param scene_id] started at [param now] (for cooldowns).
func mark_played(scene_id: String, now: float) -> void:
	_last_played[scene_id] = now
