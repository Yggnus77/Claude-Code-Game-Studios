extends SceneTree
## Runs every tests/**/test_*.gd file. Exit code 0 when all pass, 1 otherwise.
## Usage: godot --headless --path . -s res://tests/run_tests.gd
## A test that raises an engine or script error fails, even if its own
## assertions passed (a runtime error aborts the test function silently).


class ErrorCounter extends Logger:
	var count := 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			count += 1

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Autoloads are not started for -s scripts; register input actions here.
	load("res://src/core/input_setup.gd").register_defaults()
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var files := _collect("res://tests")
	files.sort()
	var passed := 0
	var failed := 0
	for path in files:
		var script: GDScript = load(path)
		if script == null or not script.can_instantiate():
			# A file that does not parse would otherwise just run zero tests.
			failed += 1
			print("FAIL %s (script does not load)" % path.get_file())
			continue
		for method in script.get_script_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			var errors_before := errors.count
			await test.call(name)
			if errors.count > errors_before:
				test.failures.append("%d engine/script error(s) during the test (see log above)" % (errors.count - errors_before))
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
