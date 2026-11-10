class_name ToolRules
extends RefCounted
## Rules of the item button's tools (design/gdd/ferramentas.md), read from
## assets/data/ferramentas.json: which tools exist, in what order the quick
## swap visits them, which item owns each one, its ammunition and numbers.
## Pure: everything takes the [GameState] it reads.
##
## Example:
##   var tools := ToolRules.load_from()
##   var next := tools.next_tool("frasco", state)   # "gancho" when owned
##   tools.label("arco", state)                      # "Arco 12"

const PATH := "res://assets/data/ferramentas.json"
## The flask (and bread) is always on the button; it owns no item.
const FLASK := "frasco"

## Quick-swap order of the tool ids.
var order: Array[String] = [FLASK, "gancho"]
## tool id -> definition (see ferramentas.json "tools").
var defs: Dictionary = {}
## Needles a refill container tops up to.
var refill_amount := 10
## Ambient colour of a dark room.
var dark_ambient := Color("2a2638")


## Loads [param path]; a missing or broken file keeps the flask and hook.
static func load_from(path: String = PATH) -> ToolRules:
	var t := ToolRules.new()
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if not parsed is Dictionary:
		t.defs = {"gancho": {"name": "Gancho", "item": "gancho_retorno"}}
		return t
	var d: Dictionary = parsed
	var raw_order: Variant = d.get("order", [])
	if raw_order is Array and not (raw_order as Array).is_empty():
		t.order.clear()
		for id: Variant in raw_order:
			t.order.append(str(id))
		if not t.order.has(FLASK):
			t.order.push_front(FLASK)
	var raw_defs: Variant = d.get("tools", {})
	if raw_defs is Dictionary:
		t.defs = raw_defs
	t.refill_amount = maxi(1, int(d.get("refill_amount", t.refill_amount)))
	t.dark_ambient = Color.from_string(str(d.get("dark_ambient", "#2a2638")), t.dark_ambient)
	return t


## The definition of [param tool] ({} when unknown or the flask).
func def_of(tool: String) -> Dictionary:
	return defs.get(tool, {})


## Number [param key] of [param tool], or [param fallback].
func num(tool: String, key: String, fallback: float) -> float:
	var v: Variant = def_of(tool).get(key, fallback)
	return float(v) if v is float or v is int else fallback


## Text [param key] of [param tool] ("" when missing).
func text(tool: String, key: String) -> String:
	return str(def_of(tool).get(key, ""))


## The item that gives [param tool] ("" for the flask).
func item_of(tool: String) -> String:
	return str(def_of(tool).get("item", ""))


## The ammunition item [param tool] spends ("" for none).
func ammo_of(tool: String) -> String:
	return str(def_of(tool).get("ammo", ""))


## Ammunition left for [param tool] (-1 when it uses none).
func ammo_count(tool: String, state: GameState) -> int:
	var ammo := ammo_of(tool)
	return -1 if ammo.is_empty() else state.item_count(ammo)


## Most ammunition [param tool] can carry.
func ammo_cap(tool: String) -> int:
	return int(num(tool, "ammo_cap", 99))


## Whether the player has [param tool]. The flask is always there; a tool
## spent down to nothing (the charges) stays once its known flag is set.
func owns(tool: String, state: GameState) -> bool:
	if tool == FLASK:
		return true
	if not defs.has(tool):
		return false
	var item := item_of(tool)
	if not item.is_empty() and state.item_count(item) > 0:
		return true
	var known := str(def_of(tool).get("known_flag", ""))
	return not known.is_empty() and state.has_flag(known)


## Tools the player has, in quick-swap order.
func owned(state: GameState) -> Array[String]:
	var out: Array[String] = []
	for tool in order:
		if owns(tool, state):
			out.append(tool)
	return out


## The tool after [param current] in the quick swap (the flask when
## [param current] is no longer owned).
func next_tool(current: String, state: GameState) -> String:
	var list := owned(state)
	var at := list.find(current)
	return list[(at + 1) % list.size()] if at >= 0 else FLASK


## "Arco 12", "Gancho", "Frasco" for the HUD.
func label(tool: String, state: GameState) -> String:
	var name := "Frasco" if tool == FLASK else str(def_of(tool).get("name", tool))
	var n := ammo_count(tool, state)
	return name if n < 0 else "%s %d" % [name, n]


## Tools owned now that were not owned in [param before] (newest last).
func new_tools(before: Array[String], state: GameState) -> Array[String]:
	var out: Array[String] = []
	for tool in owned(state):
		if not before.has(tool):
			out.append(tool)
	return out


## The effects that top [param item] up to [param amount] (at most its
## cap), or [] when it is already there.
func top_up_effects(tool: String, amount: int, state: GameState) -> Array:
	var item := ammo_of(tool)
	if item.is_empty():
		return []
	var have := state.item_count(item)
	var want := mini(amount, ammo_cap(tool))
	if have >= want:
		return []
	return [{"op": "add_item", "item_id": item, "quantity": want - have, "stack_limit": ammo_cap(tool)}]


## Whether a blast at [param blast] with [param radius] reaches the arch
## at [param arch] of a cracked wall ([code]crack_reach[/code] px of slack).
func blast_reaches_wall(blast: Vector2, arch: Vector2, radius: float) -> bool:
	return blast.distance_to(arch) <= radius + num("cargas", "crack_reach", 8.0)


## Tool whose ammunition is [param item] ("" when none).
func tool_for_ammo(item: String) -> String:
	for tool: String in defs:
		if ammo_of(tool) == item:
			return tool
	return ""
