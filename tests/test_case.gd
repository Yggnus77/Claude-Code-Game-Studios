class_name TestCase
extends RefCounted
## Minimal base class for the project's GDScript tests (run by tests/run_tests.gd).
## Each method whose name starts with `test_` is one test; it may use await.

## The running SceneTree, for integration tests that need nodes and frames.
var tree: SceneTree
## Failure messages of the current test.
var failures: PackedStringArray = PackedStringArray()


func assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [message, expected, actual])


func assert_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s (expected %.4f ± %.4f, got %.4f)" % [message, expected, tolerance, actual])
