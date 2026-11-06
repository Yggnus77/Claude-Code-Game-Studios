class_name RelicLoadout
extends RefCounted
## The relic slot (misterios-e-reliquias.md "Regras de vantagens raras";
## base-modificadores-reliquias.json). Current numbers are always rebuilt
## from the base, then exactly one equipped relic is applied: equipping and
## unequipping any number of times can never stack a bonus.

## Base numbers, flattened: {"healing.startup": 0.65, ...}.
var base: Dictionary = {}
## Relic id → its modifiers ({"healing.startup": 0.55, ...}).
var relics: Dictionary = {}


## [param base_doc] is base-modificadores-reliquias.json; [param mysteries]
## the misterios.json entries (rewards.relic_id and relic_modifiers).
func _init(base_doc: Dictionary, mysteries: Array) -> void:
	_flatten(base_doc.get("base", {}), "", base)
	for m: Dictionary in mysteries:
		var relic := str(m.get("rewards", {}).get("relic_id", ""))
		if not relic.is_empty():
			relics[relic] = m.get("relic_modifiers", {})


## Current numbers with [param equipped] (or none, for "") applied.
func params(equipped: String) -> Dictionary:
	var out := base.duplicate(true)
	for key: String in relics.get(equipped, {}):
		out[key] = relics[equipped][key]
	return out


## The keys [param relic_id] changes, with base and new value:
## [{key, from, to}]. Shown before equipping.
func effects(relic_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key: String in relics.get(relic_id, {}):
		out.append({"key": key, "from": base.get(key, null), "to": relics[relic_id][key]})
	return out


func _flatten(d: Dictionary, prefix: String, into: Dictionary) -> void:
	for k: String in d:
		var key := prefix + k
		if d[k] is Dictionary:
			_flatten(d[k], key + ".", into)
		else:
			into[key] = d[k]
