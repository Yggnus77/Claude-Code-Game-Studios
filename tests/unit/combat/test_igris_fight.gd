extends TestCase
## Igris liberation rules (mecanicas-e-dificuldade.md "Igris").

const ENCOUNTER := {"cycles": 2, "damage_hits_per_cycle": 2, "hook_window": 2.0, "exposure": 2.4, "telegraphs": [1.0, 0.85, 0.75]}
const WIRING := {
	"later_cycle_waves": [[0, 2, 0]],
	"wave_gap": 0.45,
	"bell_sequences": [["a", "b"], ["b", "a", "b"]],
	"bell_show_step": 0.55,
}


func _until(f: IgrisFight, phase: IgrisFight.Phase, max_seconds := 20.0) -> Array:
	var events := []
	var t := 0.0
	while f.phase != phase and t < max_seconds:
		events.append_array(f.tick(0.05))
		t += 0.05
	return events


func _clear_cycle(f: IgrisFight) -> void:
	_until(f, IgrisFight.Phase.MUFFLER)
	f.hook_muffler()
	_until(f, IgrisFight.Phase.BELLS)
	for id in f.sequence():
		f.ring(id)
	f.hit_regulator()
	f.hit_regulator()


func test_three_announced_waves_then_muffler() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	var events := _until(f, IgrisFight.Phase.MUFFLER)
	assert_eq(events.count("wave_announce"), 3, "three waves announced")
	assert_eq(events.count("wave_strike"), 3, "three strikes")
	assert_eq(events.find("wave_announce") < events.find("wave_strike"), true, "always announced first")


func test_two_cycles_free_igris() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	_clear_cycle(f)
	assert_eq(f.cycle, 1, "first cycle done")
	assert_eq(f.sequence(), ["b", "a", "b"], "second cycle has its own order")
	_clear_cycle(f)
	assert_true(f.is_done(), "control broken after two cycles")


func test_missed_muffler_window_repeats_waves() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	_until(f, IgrisFight.Phase.MUFFLER)
	var events := f.tick(2.01)
	assert_true(events.has("muffler_closed"), "window closes after 2.0 s")
	assert_eq(f.phase, IgrisFight.Phase.WAVES, "back to the waves")
	assert_true(not f.hook_muffler(), "the hook does nothing outside the window")


func test_wrong_bell_shows_the_order_again() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	_until(f, IgrisFight.Phase.MUFFLER)
	f.hook_muffler()
	_until(f, IgrisFight.Phase.BELLS)
	assert_true(not f.ring("b"), "wrong first bell")
	assert_eq(f.phase, IgrisFight.Phase.BELLS_SHOW, "the order is shown again")


func test_regulator_only_takes_hits_while_open_and_keeps_them() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	assert_true(not f.hit_regulator(), "ordinary hit does nothing")
	_until(f, IgrisFight.Phase.MUFFLER)
	f.hook_muffler()
	_until(f, IgrisFight.Phase.BELLS)
	for id in f.sequence():
		f.ring(id)
	assert_true(f.hit_regulator(), "first hit counts")
	f.tick(2.41)
	assert_eq(f.phase, IgrisFight.Phase.WAVES, "regulator closes after 2.4 s")
	assert_eq(f.hits, 1, "the landed hit is kept for the cycle")
	assert_eq(f.cycle, 0, "same cycle")


func test_reset_restarts_the_attempt() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	_clear_cycle(f)
	f.reset()
	assert_eq(f.cycle, 0, "first cycle again")
	assert_eq(f.phase, IgrisFight.Phase.WAVES, "from the waves")


func test_wrong_second_bell_restarts_the_order() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	_clear_cycle(f)
	_until(f, IgrisFight.Phase.MUFFLER)
	f.hook_muffler()
	_until(f, IgrisFight.Phase.BELLS)
	assert_true(not f.ring("b"), "right first bell (b-a-b)")
	assert_true(not f.ring("b"), "wrong second bell")
	assert_eq(f.phase, IgrisFight.Phase.BELLS_SHOW, "the order is shown again")
	assert_eq(f.bell_progress, 0, "from the first bell")


func test_ordinary_hits_never_advance_the_fight() -> void:
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	for phase in [IgrisFight.Phase.WAVES, IgrisFight.Phase.MUFFLER]:
		_until(f, phase)
		for i in 10:
			assert_true(not f.hit_regulator(), "no hit counts outside the regulator")
	f.hook_muffler()
	_until(f, IgrisFight.Phase.BELLS)
	for i in 10:
		f.hit_regulator()
	assert_eq(f.hits, 0, "no hits stored")
	assert_eq(f.cycle, 0, "same cycle")
	assert_true(not f.is_done(), "still bound")


func test_missing_bell_sequences_do_not_break_ringing() -> void:
	var f := IgrisFight.new(ENCOUNTER, {"wave_gap": 0.45})
	_until(f, IgrisFight.Phase.MUFFLER)
	f.hook_muffler()
	_until(f, IgrisFight.Phase.BELLS)
	assert_true(not f.ring("a"), "nothing to ring, no crash")


func test_later_cycles_only_use_taught_telegraphs() -> void:
	# mecanicas: the second cycle mixes a slow and a fast wave, both taught.
	var f := IgrisFight.new(ENCOUNTER, WIRING)
	assert_eq(f.wave_telegraphs[0], [1.0, 0.85, 0.75], "cycle one teaches the kit's telegraphs in order")
	assert_eq(f.wave_telegraphs[1], [1.0, 0.75, 1.0], "cycle two picks slow, fast, slow")


func test_tower_data_mixes_slow_and_fast_in_cycle_two() -> void:
	var tower: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/torre-akurame.json"))
	var rows: Array = tower["igris"]["later_cycle_waves"]
	assert_true(not rows.is_empty(), "a second cycle is defined")
	var row: Array = rows[0]
	assert_true(row.has(0.0) and row.has(2.0), "slowest and fastest taught wave both appear")
