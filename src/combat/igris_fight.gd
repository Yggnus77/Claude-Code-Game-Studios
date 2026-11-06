class_name IgrisFight
extends RefCounted
## Igris liberation (mecanicas-e-dificuldade.md "Igris"; chefes.json "igris";
## bell sequences and later-cycle wave order in torre-akurame.json "igris").
## Cycle one teaches the telegraphs of chefes.json in order (slow to fast);
## later cycles pick from those same telegraphs by index, so every wave they
## throw was already taught.
##
## Two cycles. Each: three announced waves → the chest muffler can be hooked
## for 2.0 s → bells rung in the order shown → regulator open for 2.4 s.
## Two confirmed sword hits on the regulator close a cycle; a missed window
## sends the cycle back to its waves (hits already landed are kept). There
## is no life bar: ordinary damage never ends the fight, and nothing here
## costs energy. Pure rules: the node shows what [method tick] reports.

enum Phase { WAVES, MUFFLER, BELLS_SHOW, BELLS, REGULATOR, DONE }

var cycles: int
var hits_needed: int
var hook_window: float
var exposure: float
## One row of telegraph seconds per cycle.
var wave_telegraphs: Array[Array] = []
var wave_gap: float
var bell_sequences: Array[Array] = []
var bell_show_step: float

var phase := Phase.WAVES
var cycle := 0
var hits := 0
## Wave being announced (0..2) and whether its circle is showing.
var wave := 0
var wave_announced := false
## Bells already rung right in this cycle's sequence.
var bell_progress := 0
## Index of the bell lit during the show, or -1.
var showing := -1

var _left := 0.0


func _init(encounter: Dictionary, wiring: Dictionary) -> void:
	cycles = int(encounter.get("cycles", 2))
	hits_needed = int(encounter.get("damage_hits_per_cycle", 2))
	hook_window = float(encounter.get("hook_window", 2.0))
	exposure = float(encounter.get("exposure", 2.4))
	var taught: Array = encounter.get("telegraphs", [1.0, 0.85, 0.75])
	wave_telegraphs.append(taught)
	for row: Array in wiring.get("later_cycle_waves", []):
		var picked := []
		for i in row:
			picked.append(float(taught[clampi(int(i), 0, taught.size() - 1)]))
		wave_telegraphs.append(picked)
	wave_gap = float(wiring.get("wave_gap", 0.45))
	for seq: Array in wiring.get("bell_sequences", []):
		bell_sequences.append(seq)
	bell_show_step = float(wiring.get("bell_show_step", 0.55))
	reset()


## Back to the first wave of the first cycle (death or a new attempt).
func reset() -> void:
	cycle = 0
	hits = 0
	_start_waves()


## Telegraph of the current wave in seconds.
func telegraph() -> float:
	var row: Array = wave_telegraphs[mini(cycle, wave_telegraphs.size() - 1)]
	return float(row[mini(wave, row.size() - 1)])


## Bell order of the current cycle.
func sequence() -> Array:
	return bell_sequences[mini(cycle, bell_sequences.size() - 1)] if not bell_sequences.is_empty() else []


## Advances the fight. Returns events for the node, in order:
## "wave_announce", "wave_strike", "muffler_open", "muffler_closed",
## "bells_ready", "regulator_closed". The show of the bells and the opening
## of the regulator start inside [method hook_muffler] and [method ring].
func tick(delta: float) -> Array[String]:
	var events: Array[String] = []
	if phase == Phase.DONE:
		return events
	_left -= delta
	if _left > 0.0:
		return events
	match phase:
		Phase.WAVES:
			if not wave_announced:
				wave_announced = true
				_left = telegraph()
				events.append("wave_announce")
			else:
				events.append("wave_strike")
				wave_announced = false
				wave += 1
				if wave >= 3:
					phase = Phase.MUFFLER
					_left = hook_window
					events.append("muffler_open")
				else:
					_left = wave_gap
		Phase.MUFFLER:
			events.append("muffler_closed")
			_start_waves()
		Phase.BELLS_SHOW:
			showing += 1
			if showing >= sequence().size():
				showing = -1
				phase = Phase.BELLS
				events.append("bells_ready")
			else:
				_left = bell_show_step
		Phase.BELLS:
			pass
		Phase.REGULATOR:
			events.append("regulator_closed")
			_start_waves()
	return events


## The hook reached the muffler. True when it was open and is now released.
func hook_muffler() -> bool:
	if phase != Phase.MUFFLER:
		return false
	_show_bells()
	return true


## A bell was struck. Returns true when the sequence is complete.
func ring(bell_id: String) -> bool:
	if phase != Phase.BELLS:
		return false
	var order := sequence()
	if order.is_empty():
		return false
	if str(order[bell_progress]) != bell_id:
		_show_bells()
		return false
	bell_progress += 1
	if bell_progress >= order.size():
		phase = Phase.REGULATOR
		_left = exposure
		return true
	return false


## A sword hit on Igris. Counts only on the open regulator; returns true
## when it counted. Ordinary hits never hurt Igris.
func hit_regulator() -> bool:
	if phase != Phase.REGULATOR:
		return false
	hits += 1
	if hits >= hits_needed:
		hits = 0
		cycle += 1
		if cycle >= cycles:
			phase = Phase.DONE
		else:
			_start_waves()
	return true


func is_done() -> bool:
	return phase == Phase.DONE


func _start_waves() -> void:
	phase = Phase.WAVES
	wave = 0
	wave_announced = false
	_left = wave_gap


func _show_bells() -> void:
	phase = Phase.BELLS_SHOW
	bell_progress = 0
	showing = -1
	_left = bell_show_step
