class_name SaveStore
extends RefCounted
## The save slot files on disk (design/kit/integracao-e-salvamento.md §7).
##
## A write never touches the last good file until the new one is proven:
##   1. the document goes to a temporary file in the same folder, which is
##      closed, reopened and fully checked;
##   2. the current main file, if it is valid, becomes the backup (a damaged
##      one is moved aside instead, so it never replaces a good backup);
##   3. the temporary file becomes the main file.
## Reading tries the main file, then a finished temporary file left by an
## interrupted write, then the backup. Nothing read from disk is executed:
## the document is plain data, checked by [member validator].

enum Status { EMPTY, OK, RECOVERED, DAMAGED, FUTURE }

## Version of the save layout this build writes. Older layouts need an
## explicit migration in [method _migrate]; newer ones are refused.
const SCHEMA_VERSION := 1
const SLOT_COUNT := 3

var dir: String
## Checks a parsed document; returns the problems found (empty = valid).
var validator: Callable = func(_doc: Dictionary) -> Array: return []
## Test hook: stop a write after this step (1, 2 or 3) as if the game had
## been closed there. -1 runs the whole write.
var interrupt_after := -1
## Keeps the validator's object alive (a Callable does not hold it).
var _validator_owner: Object


func _init(save_dir: String = "user://saves", check: Callable = Callable()) -> void:
	dir = save_dir
	if check.is_valid():
		validator = check
		_validator_owner = check.get_object()


func main_path(slot: int) -> String:
	return dir.path_join("slot_%d.json" % slot)


func temp_path(slot: int) -> String:
	return dir.path_join("slot_%d.tmp.json" % slot)


func backup_path(slot: int) -> String:
	return dir.path_join("slot_%d.bak.json" % slot)


## Where a damaged main file is kept when a new save replaces it.
func damaged_path(slot: int) -> String:
	return dir.path_join("slot_%d.damaged.json" % slot)


## Writes [param doc] to [param slot]. Returns OK, or an error with every
## existing file left as it was.
func write(slot: int, doc: Dictionary) -> Error:
	var made := DirAccess.make_dir_recursive_absolute(dir)
	if made != OK:
		return made
	var payload: Dictionary = normalized(doc)
	payload.erase("checksum")
	payload["schema_version"] = SCHEMA_VERSION
	payload["checksum"] = checksum(payload)
	var tmp := temp_path(slot)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(payload, "\t", true))
	f.close()
	if _read_file(tmp)["status"] != Status.OK:
		DirAccess.remove_absolute(tmp)
		return ERR_FILE_CORRUPT
	if interrupt_after == 1:
		return OK
	var main := main_path(slot)
	if FileAccess.file_exists(main):
		var keep := backup_path(slot) if _read_file(main)["status"] == Status.OK else damaged_path(slot)
		var moved := _move(main, keep)
		if moved != OK:
			return moved
	if interrupt_after == 2:
		return OK
	return _move(tmp, main)


## The best readable copy of [param slot]:
## {"status": Status, "data": Dictionary, "problems": Array}.
## RECOVERED means the main file was missing or damaged and an older copy
## (the finished temporary file or the backup) was used.
func read(slot: int) -> Dictionary:
	var main := _read_file(main_path(slot))
	if main["status"] == Status.OK or main["status"] == Status.FUTURE:
		return main
	for path in [temp_path(slot), backup_path(slot)]:
		var other := _read_file(path)
		if other["status"] == Status.OK:
			other["status"] = Status.RECOVERED
			other["problems"] = main["problems"]
			return other
	return main


## Empties [param slot] for a new game the player confirmed. A main file
## that cannot be read is moved aside (to [method damaged_path]), never
## deleted; the readable copies of the old game are removed, so the new
## game can never fall back to them.
func start_over(slot: int) -> void:
	var main := main_path(slot)
	if FileAccess.file_exists(main) and _read_file(main)["status"] != Status.OK:
		_move(main, damaged_path(slot))
	for path in [main, temp_path(slot), backup_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": Status.EMPTY, "data": {}, "problems": []}
	# A JSON instance reports a bad file through its return value, quietly;
	# a damaged save is an expected case, not an engine error.
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
	if typeof(parsed) != TYPE_DICTIONARY:
		return _damaged("o arquivo não é um documento JSON válido")
	var doc: Dictionary = normalized(parsed)
	var version: Variant = doc.get("schema_version")
	if typeof(version) != TYPE_INT:
		return _damaged("versão do arquivo ausente")
	if version > SCHEMA_VERSION:
		return {"status": Status.FUTURE, "data": {}, "problems": ["salvamento da versão %d; este jogo lê até a %d" % [version, SCHEMA_VERSION]]}
	if version < SCHEMA_VERSION:
		doc = _migrate(doc)
		if doc.is_empty():
			return _damaged("versão %d sem migração" % version)
	var stored := str(doc.get("checksum", ""))
	var body := doc.duplicate(true)
	body.erase("checksum")
	if stored != checksum(body):
		return _damaged("o conteúdo não confere com a soma de verificação")
	var problems: Array = validator.call(doc)
	if not problems.is_empty():
		return {"status": Status.DAMAGED, "data": {}, "problems": problems}
	return {"status": Status.OK, "data": doc, "problems": []}


## Older layouts would be upgraded here, one version at a time. Version 1
## is the first, so there is nothing to migrate yet.
func _migrate(_doc: Dictionary) -> Dictionary:
	return {}


func _damaged(reason: String) -> Dictionary:
	return {"status": Status.DAMAGED, "data": {}, "problems": [reason]}


## Renames [param from] over [param to]; some systems refuse to rename onto
## an existing file, so the target is removed and the rename tried again.
func _move(from: String, to: String) -> Error:
	if DirAccess.rename_absolute(from, to) == OK:
		return OK
	if FileAccess.file_exists(to):
		DirAccess.remove_absolute(to)
	return DirAccess.rename_absolute(from, to)


## Detects accidental damage only; a local file can always be edited, so
## this is not protection against cheating.
static func checksum(doc: Dictionary) -> String:
	return JSON.stringify(doc, "", true).md5_text()


## JSON reads every number as a float: whole numbers become ints again, so
## a document compares and checks the same before and after a round trip.
static func normalized(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var f: float = value
			if is_finite(f) and f == floorf(f) and absf(f) < 9.0e15:
				return int(f)
			return f
		TYPE_DICTIONARY:
			var out := {}
			for k in value:
				out[str(k)] = normalized(value[k])
			return out
		TYPE_ARRAY:
			var arr := []
			for v in value:
				arr.append(normalized(v))
			return arr
	return value
