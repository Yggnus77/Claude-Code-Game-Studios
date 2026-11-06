class_name GameState
extends RefCounted
## Persistent progress: flags, items, receipts, Bronze, capacities, skins and
## fragments (design/kit/integracao-e-salvamento.md §3, §5).
##
## Every change goes through [method apply], which runs a list of effects on a
## copy and keeps the copy only if every effect succeeded: all or nothing.
## Unique grants carry a receipt id; a receipt already present makes the
## grant a no-op, so replaying a scene, skipping it or reopening a chest never
## duplicates anything.

signal changed

const BASE_LIFE := 6
const MAX_LIFE := 14
const FRAGMENTS_PER_LIFE := 4

var flags: Dictionary = {}
var items: Dictionary = {}
var receipts: Dictionary = {}
var bronze := 0
var bronze_reserve := 0
var wallet_capacity := 200
var flask_capacity := 2
var resonance_max := 60
var skins: Array = ["restaurador"]
var fragments: Array = []
## Last checkpoint: {"room": id, "entity_id": id}.
var checkpoint: Dictionary = {}
## Ids of the flasks that hold a Restorative charge. Flasks are items whose
## id starts with [constant FLASK_PREFIX]; a new one arrives empty.
var full_flasks: Array = []

const FLASK_PREFIX := "frasco_"


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func has_receipt(receipt_id: String) -> bool:
	return receipts.has(receipt_id)


func item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))


## Flask ids owned, in order, limited by the flask capacity.
func flasks() -> Array:
	var ids := []
	for id in items.keys():
		if str(id).begins_with(FLASK_PREFIX) and item_count(id) > 0:
			ids.append(str(id))
	ids.sort()
	return ids.slice(0, flask_capacity)


## How many owned flasks are full.
func full_flask_count() -> int:
	var n := 0
	for id in flasks():
		if full_flasks.has(id):
			n += 1
	return n


## Max life from unique fragments: 6 + floor(fragments / 4), capped at 14.
func life_max() -> int:
	return mini(MAX_LIFE, BASE_LIFE + fragments.size() / FRAGMENTS_PER_LIFE)


## Applies [param effects] atomically. Returns false (and changes nothing)
## when any effect is unknown or cannot be applied.
func apply(effects: Array) -> bool:
	var next := GameState.from_dict(to_dict())
	for effect in effects:
		if not next._apply_one(effect):
			return false
	_load(next.to_dict())
	changed.emit()
	return true


func _apply_one(e: Dictionary) -> bool:
	var receipt := str(e.get("receipt_id", ""))
	match str(e.get("op", "")):
		"set_flag":
			flags[str(e["flag"])] = bool(e.get("value", true))
		"grant_unique":
			if receipt.is_empty() or has_receipt(receipt):
				return not receipt.is_empty()
			var id := str(e["item_id"])
			items[id] = item_count(id) + int(e.get("quantity", 1))
			receipts[receipt] = true
		"grant_bronze_unique":
			if receipt.is_empty() or has_receipt(receipt):
				return not receipt.is_empty()
			_add_bronze(int(e["amount"]))
			receipts[receipt] = true
		"consume_quest_items_once":
			if receipt.is_empty():
				return false
			if has_receipt(receipt):
				return true
			var need: Dictionary = e.get("items", {})
			for id in need:
				if item_count(id) < int(need[id]):
					return false
			for id in need:
				items[id] = item_count(id) - int(need[id])
				if items[id] <= 0:
					items.erase(id)
			receipts[receipt] = true
		"unlock_skin":
			if not skins.has(e["skin_id"]):
				skins.append(e["skin_id"])
		"set_resonance_max_min":
			resonance_max = maxi(resonance_max, int(e["value"]))
		"set_wallet_capacity_min":
			wallet_capacity = maxi(wallet_capacity, int(e["value"]))
		"set_flask_capacity_min":
			flask_capacity = maxi(flask_capacity, int(e["value"]))
		"collect_fragment":
			if receipt.is_empty() or has_receipt(receipt):
				return not receipt.is_empty()
			if not fragments.has(e["fragment_id"]):
				fragments.append(e["fragment_id"])
			receipts[receipt] = true
		"add_receipt":
			if receipt.is_empty():
				return false
			receipts[receipt] = true
		"add_bronze":
			# Repeatable pickups (enemy drops); the overflow goes to the reserve.
			_add_bronze(maxi(0, int(e["amount"])))
		"spend_bronze":
			var price := int(e["amount"])
			if price < 0 or bronze < price:
				return false
			bronze -= price
		"add_item":
			# Non-unique stackable item (shop goods). Fails above the stack limit.
			var id := str(e["item_id"])
			var total := item_count(id) + int(e.get("quantity", 1))
			if total > int(e.get("stack_limit", 99)):
				return false
			items[id] = total
		"use_item":
			var id := str(e["item_id"])
			if item_count(id) <= 0:
				return false
			items[id] = item_count(id) - 1
			if items[id] <= 0:
				items.erase(id)
		"drink_flask":
			for id in flasks():
				if full_flasks.has(id):
					full_flasks.erase(id)
					return true
			return false
		"refill_flask":
			for id in flasks():
				if not full_flasks.has(id):
					full_flasks.append(id)
					return true
			return false
		"restore_supplies":
			# Boss attempt snapshot (mecanicas §9): flasks and bread go back to
			# what they were when the attempt started.
			full_flasks = e.get("full_flasks", []).duplicate()
			var bread := int(e.get("bread", 0))
			if bread > 0:
				items["pao_porto"] = bread
			else:
				items.erase("pao_porto")
		"set_checkpoint":
			checkpoint = {"room": str(e["room"]), "entity_id": str(e["entity_id"])}
		_:
			push_warning("GameState: unknown effect %s" % e)
			return false
	return true


## Bronze goes to the purse up to its capacity; the rest to the reserve.
func _add_bronze(amount: int) -> void:
	var take := clampi(wallet_capacity - bronze, 0, amount)
	bronze += take
	bronze_reserve += amount - take


func to_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(true), "items": items.duplicate(true), "receipts": receipts.duplicate(true),
		"bronze": bronze, "bronze_reserve": bronze_reserve, "wallet_capacity": wallet_capacity,
		"flask_capacity": flask_capacity, "resonance_max": resonance_max,
		"skins": skins.duplicate(), "fragments": fragments.duplicate(), "checkpoint": checkpoint.duplicate(),
		"full_flasks": full_flasks.duplicate(),
	}


static func from_dict(d: Dictionary) -> GameState:
	var s := GameState.new()
	s._load(d)
	return s


func _load(d: Dictionary) -> void:
	flags = d.get("flags", {}).duplicate(true)
	items = d.get("items", {}).duplicate(true)
	receipts = d.get("receipts", {}).duplicate(true)
	bronze = int(d.get("bronze", 0))
	bronze_reserve = int(d.get("bronze_reserve", 0))
	wallet_capacity = int(d.get("wallet_capacity", 200))
	flask_capacity = int(d.get("flask_capacity", 2))
	resonance_max = int(d.get("resonance_max", 60))
	skins = d.get("skins", ["restaurador"]).duplicate()
	fragments = d.get("fragments", []).duplicate()
	checkpoint = d.get("checkpoint", {}).duplicate()
	full_flasks = d.get("full_flasks", []).duplicate()
