extends SceneTree
## Runs every tests/**/test_*.gd file. Exit code 0 when all pass, 1 otherwise.
## Usage: godot --headless --path . -s res://tests/run_tests.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Autoloads are not started for -s scripts; register input actions here.
	load("res://src/core/input_setup.gd").register_defaults()
	var files := _collect("res://tests")
	files.sort()
	var passed := 0
	var failed := 0
	for path in files:
		var script: GDScript = load(path)
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			await test.call(name)
			if test.failures.is_empty():
				passed += 1
				print("PASS %s::%s" % [path.get_file(), name])
			else:
				failed += 1
				print("FAIL %s::%s" % [path.get_file(), name])
				for f in test.failures:
					print("     - %s" % f)
			if test.has_method("teardown"):
				await test.teardown()
	print("\n%d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)


func _collect(dir_path: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub in dir.get_directories():
		out.append_array(_collect(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.begins_with("test_") and file.ends_with(".gd") and file != "test_case.gd":
			out.append(dir_path.path_join(file))
	return out
