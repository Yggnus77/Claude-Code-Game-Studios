class_name SaveGame
extends RefCounted
## Turns progress into the save document and back, and checks a document
## read from disk against the game's own catalogs
## (design/kit/integracao-e-salvamento.md §7; layout follows
## assets/data/salvamento-exemplo.json).
##
## Saved: room and safe entry tile, marco, life, inventory, flask contents,
## Bronze and reserve, capacities, skins, flags (story, missions, doors),
## receipts (chests, pickups, bindings), fragments, the relic and the item
## button. Not saved: hitbox timers, enemy targets or positions, projectiles
## or the middle of a boss fight. Missions, doors and chests have no fields
## of their own: their state lives in the flags and receipts.

const MAX_STACK := 999
const MAX_RESERVE := 9999999
const MAX_FRAGMENTS := 64

## Room ids a save may name (mapas-prototipo.json "rooms").
var rooms: Array = []
## Item ids a save may hold (itens.json). Empty accepts any id.
var item_ids: Array = []
## Fragment ids a save may hold (recompensas-mundo.json). Empty accepts any.
var fragment_ids: Array = []
## Tool ids the item button may hold (ferramentas.json "order").
var tools: Array = ToolRules.load_from().order
## Loads a room by id, to check the entry tile. Never given a path from
## the save: the id must be in [member rooms] first.
var room_loader: Callable = func(id: String) -> RoomData: return RoomData.load_room(id)


func _init(room_ids: Array = [], items: Array = [], fragments: Array = []) -> void:
	rooms = room_ids
	item_ids = items
	fragment_ids = fragments


## The save document for [param state]. [param at] carries what lives
## outside [GameState]: {"room", "entry": Vector2i, "life", "tool",
## "playtime", "slot"}.
static func capture(state: GameState, at: Dictionary) -> Dictionary:
	var entry: Vector2i = at.get("entry", Vector2i.ZERO)
	var flasks := []
	var owned := []
	for id in state.items.keys():
		if str(id).begins_with(GameState.FLASK_PREFIX):
			owned.append(str(id))
	owned.sort()
	for id in owned:
		flasks.append({"id": id, "content": "full" if state.full_flasks.has(id) else "empty"})
	var receipts: Array = state.receipts.keys()
	receipts.sort()
	var cp: Variant = null
	if not state.checkpoint.is_empty():
		cp = state.checkpoint.duplicate()
	return {
		"schema_version": SaveStore.SCHEMA_VERSION,
		"slot_id": int(at.get("slot", 1)),
		"playtime_seconds": int(at.get("playtime", 0)),
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"current_room": str(at.get("room", "")),
		"safe_entry": [entry.x, entry.y],
		"checkpoint": cp,
		"player": {
			"life": int(at.get("life", state.life_max())),
			"life_max": state.life_max(),
			"resonance_max": state.resonance_max,
			"bronze": state.bronze,
			"bronze_reserve": state.bronze_reserve,
			"wallet_capacity": state.wallet_capacity,
			"flask_capacity": state.flask_capacity,
			"equipped_tool": str(at.get("tool", "frasco")),
			"equipped_relic": state.equipped_relic,
			"unlocked_skins": state.skins.duplicate(),
			"active_skin": "restaurador",
		},
		"inventory": state.items.duplicate(true),
		"flasks": flasks,
		"flags": state.flags.duplicate(true),
		"receipts": receipts,
		"fragments": state.fragments.duplicate(),
	}


## Progress and position from a document that passed [method validate]:
## {"state": GameState, "room", "entry": Vector2i, "life", "tool", "playtime"}.
static func restore(doc: Dictionary) -> Dictionary:
	var p: Dictionary = doc["player"]
	var full := []
	for f in doc.get("flasks", []):
		if str(f["content"]) == "full":
			full.append(str(f["id"]))
	var receipts := {}
	for r in doc.get("receipts", []):
		receipts[str(r)] = true
	var cp: Variant = doc.get("checkpoint")
	var state := GameState.from_dict({
		"flags": doc["flags"], "items": doc["inventory"], "receipts": receipts,
		"bronze": p["bronze"], "bronze_reserve": p["bronze_reserve"],
		"wallet_capacity": p["wallet_capacity"], "flask_capacity": p["flask_capacity"],
		"resonance_max": p["resonance_max"], "skins": p["unlocked_skins"],
		"fragments": doc["fragments"], "checkpoint": cp if cp is Dictionary else {},
		"full_flasks": full, "equipped_relic": str(p.get("equipped_relic", "")),
	})
	var e: Array = doc["safe_entry"]
	return {
		"state": state, "room": str(doc["current_room"]), "entry": Vector2i(int(e[0]), int(e[1])),
		"life": mini(int(p["life"]), state.life_max()), "tool": str(p["equipped_tool"]),
		"playtime": int(doc["playtime_seconds"]),
	}


## Problems in [param doc] (empty when it can be loaded). Checks types,
## limits and that every id is one the game knows.
func validate(doc: Dictionary) -> Array:
	var bad := []
	var room := str(doc.get("current_room", ""))
	if not rooms.has(room):
		bad.append("sala desconhecida")
	elif not _entry_ok(room, doc.get("safe_entry")):
		bad.append("entrada fora da sala")
	if not _int_in(doc.get("playtime_seconds"), 0, 2147483647):
		bad.append("tempo de jogo inválido")
	var cp: Variant = doc.get("checkpoint")
	if cp != null and not (cp is Dictionary and _is_marco(str(cp.get("room", "")), cp.get("entity_id"))):
		bad.append("marco inválido")
	var p: Variant = doc.get("player")
	if not p is Dictionary:
		bad.append("dados do jogador ausentes")
		return bad
	if not _int_in(p.get("life_max"), GameState.BASE_LIFE, GameState.MAX_LIFE):
		bad.append("vida máxima inválida")
	elif not _int_in(p.get("life"), 1, int(p["life_max"])):
		bad.append("vida inválida")
	if not _int_in(p.get("wallet_capacity"), 1, MAX_RESERVE):
		bad.append("capacidade da bolsa inválida")
	elif not _int_in(p.get("bronze"), 0, int(p["wallet_capacity"])):
		bad.append("Bronze acima da bolsa")
	if not _int_in(p.get("bronze_reserve"), 0, MAX_RESERVE):
		bad.append("reserva inválida")
	if not _int_in(p.get("flask_capacity"), 1, 9):
		bad.append("espaços de frasco inválidos")
	if not _int_in(p.get("resonance_max"), 1, 9999):
		bad.append("ressonância inválida")
	if not tools.has(p.get("equipped_tool")):
		bad.append("item do botão desconhecido")
	if not p.get("equipped_relic", "") is String:
		bad.append("relíquia inválida")
	if not _strings(p.get("unlocked_skins")):
		bad.append("skins inválidas")
	var inv: Variant = doc.get("inventory")
	if not inv is Dictionary:
		bad.append("inventário ausente")
	else:
		for id in inv:
			if (not item_ids.is_empty() and not item_ids.has(id)) or not _int_in(inv[id], 1, MAX_STACK):
				bad.append("item inválido: %s" % id)
				break
	var flasks: Variant = doc.get("flasks")
	if not flasks is Array:
		bad.append("frascos ausentes")
	else:
		for f in flasks:
			if not (f is Dictionary and inv is Dictionary and inv.has(str(f.get("id", ""))) and ["full", "empty"].has(f.get("content"))):
				bad.append("frasco inválido")
				break
	var flags: Variant = doc.get("flags")
	if not flags is Dictionary or flags.values().any(func(v: Variant) -> bool: return not v is bool):
		bad.append("flags inválidos")
	if not _strings(doc.get("receipts")):
		bad.append("recibos inválidos")
	var frags: Variant = doc.get("fragments")
	if not _strings(frags) or frags.size() > MAX_FRAGMENTS:
		bad.append("fragmentos inválidos")
	elif not fragment_ids.is_empty() and frags.any(func(f: String) -> bool: return not fragment_ids.has(f)):
		bad.append("fragmento desconhecido")
	return bad


func _entry_ok(room: String, entry: Variant) -> bool:
	if not (entry is Array and entry.size() == 2 and entry[0] is int and entry[1] is int):
		return false
	var data: RoomData = room_loader.call(room)
	return data != null and data.is_walkable(Vector2i(entry[0], entry[1]))


## True when [param entity] is a marco (checkpoint) of a known [param room].
func _is_marco(room: String, entity: Variant) -> bool:
	if not rooms.has(room) or not entity is String:
		return false
	var data: RoomData = room_loader.call(room)
	if data == null:
		return false
	for e in data.entities:
		if str(e.get("id", "")) == entity:
			return str(e.get("kind", "")) == "checkpoint"
	return false


static func _int_in(v: Variant, lo: int, hi: int) -> bool:
	return v is int and v >= lo and v <= hi


static func _strings(v: Variant) -> bool:
	return v is Array and v.all(func(s: Variant) -> bool: return s is String)
