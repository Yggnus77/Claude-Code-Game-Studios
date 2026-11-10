class_name Dungeons
extends RefCounted
## Key dungeons (design/gdd/masmorras.md), read from assets/data/masmorras.json:
## which rooms make each dungeon, its map, compass, small keys and big key,
## and where each room sits on the dungeon map. Pure rules: the HUD draws
## what [method map_view] returns.

const PATH := "res://assets/data/masmorras.json"
const MAPS_DIR := "res://assets/data/maps"
## Door sides and the step they make on the map grid.
const STEPS := {"north": Vector2i(0, -1), "south": Vector2i(0, 1), "east": Vector2i(1, 0), "west": Vector2i(-1, 0)}
const OPPOSITE := {"north": "south", "south": "north", "east": "west", "west": "east"}
## Flag set the first time a room is entered.
const VISITED_PREFIX := "visited."

## dungeon id -> definition.
var defs: Dictionary = {}
## dungeon id -> {room id: Vector2i} (made on first use).
var _layouts: Dictionary = {}
## Loads rooms by id; tests may inject their own.
var room_loader: Callable = func(id: String) -> RoomData: return RoomData.load_room(id, MAPS_DIR)
var _rooms: Dictionary = {}


static func load_from(path: String = PATH) -> Dungeons:
	var d := Dungeons.new()
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if parsed is Dictionary and (parsed as Dictionary).get("dungeons") is Dictionary:
		d.defs = (parsed as Dictionary)["dungeons"]
	return d


## The dungeon that holds [param room_id], or "".
func dungeon_of(room_id: String) -> String:
	for id: String in defs:
		var prefix := str((defs[id] as Dictionary).get("room_prefix", ""))
		if not prefix.is_empty() and room_id.begins_with(prefix) and layout(id).has(room_id):
			return id
	return ""


func def_of(dungeon: String) -> Dictionary:
	return defs.get(dungeon, {})


## Grid cell of every room reachable from the start through side doors whose
## other end is on the opposite side (rooms that sit edge to edge).
func layout(dungeon: String) -> Dictionary:
	if _layouts.has(dungeon):
		return _layouts[dungeon]
	var def := def_of(dungeon)
	var out := {}
	var prefix := str(def.get("room_prefix", ""))
	var start := str(def.get("start", ""))
	if start.is_empty() or _room(start) == null:
		_layouts[dungeon] = out
		return out
	out[start] = Vector2i.ZERO
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		var data: RoomData = _room(id)
		if data == null:
			continue
		for door: Dictionary in data.doors:
			var side := str(door.get("side", ""))
			var to := str(door.get("target_room", ""))
			if not STEPS.has(side) or not to.begins_with(prefix) or out.has(to):
				continue
			var next: RoomData = _room(to)
			if next == null or not _has_door_back(next, id, OPPOSITE[side]):
				continue
			var cell: Vector2i = out[id] + STEPS[side]
			if out.values().has(cell):
				continue
			out[to] = cell
			queue.append(to)
	_layouts[dungeon] = out
	return out


## Room [param id], loaded once.
func _room(id: String) -> RoomData:
	if not _rooms.has(id):
		_rooms[id] = room_loader.call(id)
	return _rooms[id]


static func _has_door_back(data: RoomData, to: String, side: String) -> bool:
	for d: Dictionary in data.doors:
		if str(d.get("target_room", "")) == to and str(d.get("side", "")) == side:
			return true
	return false


## What the dungeon map shows for [param state] with the player in
## [param here]: {"rooms": [{"id", "cell", "visited", "shown", "here",
## "chest", "boss"}], "links": [[cell, cell]], "has_map", "has_compass",
## "small_keys", "boss_key"}. A room is shown once visited, or always with
## the map; the compass marks rooms with unopened chests and the boss room.
func map_view(dungeon: String, state: GameState, here: String) -> Dictionary:
	var def := def_of(dungeon)
	var cells := layout(dungeon)
	var has_map := state.item_count(str(def.get("map_item", ""))) > 0
	var has_compass := state.item_count(str(def.get("compass_item", ""))) > 0
	var rooms: Array = []
	var links: Array = []
	for id: String in cells:
		var visited := state.has_flag(VISITED_PREFIX + id) or id == here
		var chest := false
		var data: RoomData = _room(id)
		if has_compass and data:
			for e: Dictionary in data.entities:
				var receipt := str(e.get("persistent_receipt", ""))
				if str(e.get("kind", "")) == "chest" and not receipt.is_empty() and receipt != "<null>" and not state.has_receipt(receipt):
					chest = true
		var boss := has_compass and id == str(def.get("boss_room", "")) and not state.has_flag(str(def.get("boss_done_flag", "")))
		rooms.append({"id": id, "cell": cells[id], "visited": visited, "shown": visited or has_map, "here": id == here, "chest": chest, "boss": boss})
		if data:
			for door: Dictionary in data.doors:
				var to := str(door.get("target_room", ""))
				if cells.has(to) and id < to and (cells[to] - cells[id]).length_squared() == 1:
					links.append([cells[id], cells[to]])
	var keys := 0
	for k: Variant in def.get("small_keys", []):
		keys += state.item_count(str(k))
	return {"rooms": rooms, "links": links, "has_map": has_map, "has_compass": has_compass,
		"small_keys": keys, "boss_key": state.item_count(str(def.get("boss_key", ""))) > 0}


## Whether the big-key door gate "boss_key:<item>" is open: the key is held,
## the boss is already beaten, or the boss room was already reached (saves
## from before the big key existed must never lock the player in or out).
func boss_gate_open(item: String, state: GameState) -> bool:
	if state.item_count(item) > 0:
		return true
	for id: String in defs:
		var def: Dictionary = defs[id]
		if str(def.get("boss_key", "")) != item:
			continue
		if state.has_flag(str(def.get("boss_done_flag", "-"))) or state.has_flag(VISITED_PREFIX + str(def.get("boss_room", "-"))):
			return true
	return false
