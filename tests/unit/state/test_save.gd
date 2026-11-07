extends TestCase
## Etapa 9 rules: save files (integracao-e-salvamento.md §7). Atomic write
## with temporary file and backup, recovery, version, validation, and
## unique progress that neither duplicates nor disappears.

const ROOT := "user://test_saves"

var config: GameConfig:
	get:
		if _config == null:
			_config = GameConfig.load_all()
		return _config
var _config: GameConfig
var _dir := ""


func _store() -> SaveStore:
	# A fresh folder per test, so tests never see each other's files.
	_dir = ROOT.path_join("t%d" % Time.get_ticks_usec())
	return SaveStore.new(_dir, SaveGame.new(config.room_ids, config.items.keys(), config.fragments.keys()).validate)


func teardown() -> void:
	if _dir.is_empty() or not DirAccess.dir_exists_absolute(_dir):
		return
	for f in DirAccess.get_files_at(_dir):
		DirAccess.remove_absolute(_dir.path_join(f))
	DirAccess.remove_absolute(_dir)


func _progress() -> GameState:
	var s := GameState.new()
	s.apply([
		{"op": "grant_unique", "item_id": "frasco_01", "quantity": 1, "receipt_id": "new_game.frasco_01"},
		{"op": "grant_unique", "item_id": "gancho_retorno", "quantity": 1, "receipt_id": "scene.t04.gancho"},
		{"op": "grant_bronze_unique", "amount": 30, "receipt_id": "chest.v01"},
		{"op": "set_flag", "flag": "seen.p05", "value": true},
		{"op": "refill_flask"},
		{"op": "collect_fragment", "fragment_id": "fragment_01", "receipt_id": "frag.a"},
		{"op": "set_checkpoint", "room": "v01_praca", "entity_id": "v01_praca.marco_v"},
	])
	return s


func _doc(s: GameState, room := "v01_praca", entry := Vector2i(2, 12), life := 5) -> Dictionary:
	return SaveGame.capture(s, {"room": room, "entry": entry, "life": life, "tool": "gancho", "playtime": 90, "slot": 1})


func _write_raw(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_round_trip_keeps_every_saved_value() -> void:
	var store := _store()
	var s := _progress()
	assert_eq(store.write(1, _doc(s)), OK, "written")
	var r := store.read(1)
	assert_eq(r["status"], SaveStore.Status.OK, "read back")
	var back := SaveGame.restore(r["data"])
	var loaded: GameState = back["state"]
	assert_eq(loaded.to_dict(), s.to_dict(), "same progress")
	assert_eq(back["room"], "v01_praca", "room")
	assert_eq(back["entry"], Vector2i(2, 12), "safe entry")
	assert_eq(back["life"], 5, "life")
	assert_eq(back["tool"], "gancho", "item button")
	assert_eq(back["playtime"], 90, "play time")
	assert_true(not FileAccess.file_exists(store.temp_path(1)), "no temporary file left")


func test_unique_progress_neither_duplicates_nor_disappears() -> void:
	var store := _store()
	store.write(1, _doc(_progress()))
	var loaded: GameState = SaveGame.restore(store.read(1)["data"])["state"]
	# Replaying the same grants after a load is a no-op: the receipts came back.
	loaded.apply([
		{"op": "grant_unique", "item_id": "gancho_retorno", "quantity": 1, "receipt_id": "scene.t04.gancho"},
		{"op": "grant_bronze_unique", "amount": 30, "receipt_id": "chest.v01"},
		{"op": "collect_fragment", "fragment_id": "fragment_01", "receipt_id": "frag.a"},
	])
	assert_eq(loaded.item_count("gancho_retorno"), 1, "hook not duplicated")
	assert_eq(loaded.bronze, 30, "chest Bronze not duplicated")
	assert_eq(loaded.fragments.size(), 1, "fragment not duplicated")
	assert_eq(loaded.full_flask_count(), 1, "flask still full")


func test_closing_during_any_step_of_a_write_keeps_a_valid_save() -> void:
	# integracao §7: test the interruption before and after each step.
	for step in [1, 2, 3]:
		var store := _store()
		var a := _progress()
		store.write(1, _doc(a))
		store.write(1, _doc(a))  # a backup exists too
		var b := _progress()
		b.apply([{"op": "add_bronze", "amount": 7}])
		store.interrupt_after = step
		store.write(1, _doc(b))
		var r := store.read(1)
		assert_true(r["status"] == SaveStore.Status.OK or r["status"] == SaveStore.Status.RECOVERED, "step %d: still loads (status %d)" % [step, r["status"]])
		var bronze: int = r["data"]["player"]["bronze"] if r["data"].has("player") else -1
		assert_true(bronze == 30 or bronze == 37, "step %d: the old or the new save, whole (Bronze %d)" % [step, bronze])
		teardown()


func test_a_damaged_main_file_recovers_from_the_backup() -> void:
	var store := _store()
	var s := _progress()
	store.write(1, _doc(s))
	s.apply([{"op": "add_bronze", "amount": 5}])
	store.write(1, _doc(s))
	var text := FileAccess.get_file_as_string(store.main_path(1))
	_write_raw(store.main_path(1), text.left(text.length() / 2))  # cut half-way
	var r := store.read(1)
	assert_eq(r["status"], SaveStore.Status.RECOVERED, "recovered")
	assert_eq(int(r["data"]["player"]["bronze"]), 30, "the previous valid save")
	assert_true(not r["problems"].is_empty(), "says what was wrong")


func test_a_damaged_file_is_never_written_over_the_backup() -> void:
	var store := _store()
	store.write(1, _doc(_progress()))
	store.write(1, _doc(_progress()))
	var backup := FileAccess.get_file_as_string(store.backup_path(1))
	_write_raw(store.main_path(1), "{ not json")
	assert_eq(store.write(1, _doc(_progress())), OK, "new save written")
	assert_eq(FileAccess.get_file_as_string(store.backup_path(1)), backup, "backup untouched")
	assert_eq(FileAccess.get_file_as_string(store.damaged_path(1)), "{ not json", "damaged file kept aside")
	assert_eq(store.read(1)["status"], SaveStore.Status.OK, "main is valid again")


func test_nothing_readable_is_reported_as_damaged() -> void:
	var store := _store()
	_write_raw(store.main_path(2), "garbage")
	var r := store.read(2)
	assert_eq(r["status"], SaveStore.Status.DAMAGED, "damaged")
	assert_eq(store.read(3)["status"], SaveStore.Status.EMPTY, "an unused slot is empty")


func test_an_edited_value_fails_the_checksum() -> void:
	var store := _store()
	store.write(1, _doc(_progress()))
	var text := FileAccess.get_file_as_string(store.main_path(1))
	_write_raw(store.main_path(1), text.replace("\"bronze\": 30", "\"bronze\": 200"))
	assert_true(text.contains("\"bronze\": 30"), "fixture found the value")
	assert_eq(store.read(1)["status"], SaveStore.Status.DAMAGED, "edited file refused")


func test_a_newer_version_is_refused_with_a_clear_status() -> void:
	var store := _store()
	var doc := _doc(_progress())
	doc["schema_version"] = SaveStore.SCHEMA_VERSION + 1
	var body: Dictionary = SaveStore.normalized(doc)
	body["checksum"] = SaveStore.checksum(body)
	_write_raw(store.main_path(1), JSON.stringify(body))
	var r := store.read(1)
	assert_eq(r["status"], SaveStore.Status.FUTURE, "future version")
	assert_true(r["data"].is_empty(), "no pretend compatibility")


func test_validation_refuses_unknown_ids_and_limits() -> void:
	var check := SaveGame.new(config.room_ids, config.items.keys(), config.fragments.keys())
	assert_true(check.validate(_doc(_progress())).is_empty(), "a real save passes")
	var cases := {
		"path instead of room": func(d: Dictionary) -> void: d["current_room"] = "../../../etc/passwd",
		"unknown room": func(d: Dictionary) -> void: d["current_room"] = "x99",
		"entry inside a wall": func(d: Dictionary) -> void: d["safe_entry"] = [0, 0],
		"Bronze above the purse": func(d: Dictionary) -> void: d["player"]["bronze"] = 9999,
		"unknown item": func(d: Dictionary) -> void: d["inventory"]["espada_lendaria"] = 1,
		"negative stack": func(d: Dictionary) -> void: d["inventory"]["frasco_01"] = -2,
		"life above the maximum": func(d: Dictionary) -> void: d["player"]["life"] = 40,
		"flag that is not a boolean": func(d: Dictionary) -> void: d["flags"]["seen.p05"] = "rm -rf",
		"flask the player does not own": func(d: Dictionary) -> void: d["flasks"].append({"id": "frasco_04", "content": "full"}),
		"marco that does not exist": func(d: Dictionary) -> void: d["checkpoint"] = {"room": "t07_igris", "entity_id": "no.such.entity"},
		"entity that is not a marco": func(d: Dictionary) -> void: d["checkpoint"] = {"room": "v01_praca", "entity_id": "v01_praca.merchant"},
		"unknown fragment": func(d: Dictionary) -> void: d["fragments"].append("fragment_999"),
	}
	for label in cases:
		var d: Dictionary = SaveStore.normalized(_doc(_progress()))
		cases[label].call(d)
		assert_true(not check.validate(d).is_empty(), "refused: %s" % label)


func test_starting_over_keeps_a_damaged_file_and_drops_old_copies() -> void:
	var store := _store()
	store.write(1, _doc(_progress()))
	store.write(1, _doc(_progress()))
	_write_raw(store.main_path(1), "broken")
	store.start_over(1)
	assert_eq(store.read(1)["status"], SaveStore.Status.EMPTY, "slot empty for the new game")
	assert_true(FileAccess.file_exists(store.damaged_path(1)), "damaged file kept aside")


func test_settings_are_kept_apart_from_the_slots() -> void:
	var store := _store()
	DirAccess.make_dir_recursive_absolute(_dir)
	var path := _dir.path_join("settings.cfg")
	var prefs := Settings.new(path)
	prefs.last_slot = 3
	prefs.pause_on_focus_loss = false
	assert_eq(prefs.save_file(), OK, "settings saved")
	store.start_over(3)
	var again := Settings.new(path).load_file()
	assert_eq(again.last_slot, 3, "last slot kept")
	assert_true(not again.pause_on_focus_loss, "preference kept after a new game")


func test_a_settings_value_of_the_wrong_type_keeps_the_default() -> void:
	_store()
	DirAccess.make_dir_recursive_absolute(_dir)
	var path := _dir.path_join("settings.cfg")
	_write_raw(path, "[game]\nlast_slot=\"dois\"\npause_on_focus_loss=\"false\"\n")
	var prefs := Settings.new(path).load_file()
	assert_true(prefs != null, "loads")
	assert_eq(prefs.last_slot, 1, "default slot")
	assert_true(prefs.pause_on_focus_loss, "default pause on focus loss")
