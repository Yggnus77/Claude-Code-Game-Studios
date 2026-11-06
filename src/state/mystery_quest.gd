class_name MysteryQuest
extends RefCounted
## One optional mystery (design/kit/misterios-e-reliquias.md; misterios.json).
## Pure rules over a [GameState]: what the host (an NPC or an object) should
## do next, and whether an answer counts.
##
## Order: start scene → clues → comparison scene → answer by option id →
## reward scene. A right answer without every clue does not count; a wrong
## one costs nothing and unlocks the next hint (ajuda gradual).

enum Step { LOCKED, START, COLLECT, COMPARE, ANSWER, REWARD, DONE }
enum Result { NOT_READY, CORRECT, WRONG, ALREADY_SOLVED }

## The mystery entry from misterios.json.
var def: Dictionary
## Its wiring (misterios-ligacao.json): start scene, host, question.
var wiring: Dictionary


func _init(mystery: Dictionary, mystery_wiring: Dictionary = {}) -> void:
	def = mystery
	wiring = mystery_wiring


## Mystery id ("m01").
func id() -> String:
	return str(def.get("id", ""))


## Scene id of a stage ("start", "comparison", "reward", "wrong").
func scene(stage: String) -> String:
	match stage:
		"start":
			return str(wiring.get("start_scene", ""))
		"comparison":
			return str(def.get("comparison_scene", ""))
		"reward":
			return str(def.get("reward_scene", ""))
		"wrong":
			return str(def.get("wrong_answer_scene", ""))
	return ""


## Clue flags of this mystery.
func clue_flags() -> Array[String]:
	var out: Array[String] = []
	for c: Dictionary in def.get("clues", []):
		out.append(str(c.get("id", "")))
	return out


## How many clues the player has noted.
func clues_found(state: GameState) -> int:
	var n := 0
	for f in clue_flags():
		if state.has_flag(f):
			n += 1
	return n


## True once the right answer was given (on_correct_set_flag).
func is_solved(state: GameState) -> bool:
	return state.has_flag(str(def.get("on_correct_set_flag", "")))


## Where the mystery stands for [param state].
func step(state: GameState) -> Step:
	for f in def.get("requires_flags", []):
		if not state.has_flag(str(f)):
			return Step.LOCKED
	if not state.has_flag("seen.%s" % scene("start")):
		return Step.START
	if is_solved(state):
		return Step.DONE if state.has_flag("seen.%s" % scene("reward")) else Step.REWARD
	if clues_found(state) < clue_flags().size():
		return Step.COLLECT
	if not state.has_flag("seen.%s" % scene("comparison")):
		return Step.COMPARE
	return Step.ANSWER


## True when an answer can count: every flag submit_requires_all_flags lists.
func can_submit(state: GameState) -> bool:
	for f in def.get("submit_requires_all_flags", []):
		if not state.has_flag(str(f)):
			return false
	return true


## Checks [param answer_id]. A right answer sets the solved flag; a wrong one
## only raises the hint level. Money is never touched here.
func submit(state: GameState, answer_id: String) -> Result:
	if is_solved(state):
		return Result.ALREADY_SOLVED
	if not can_submit(state):
		return Result.NOT_READY
	if answer_id == str(def.get("correct_answer_id", "")):
		state.apply([{"op": "set_flag", "flag": str(def["on_correct_set_flag"]), "value": true}])
		return Result.CORRECT
	var level := hint_level(state)
	if level < def.get("hints", []).size():
		state.apply([{"op": "set_flag", "flag": _hint_flag(level + 1), "value": true}])
	return Result.WRONG


## Hints unlocked so far by wrong answers (0..hints).
func hint_level(state: GameState) -> int:
	var n := 0
	while n < def.get("hints", []).size() and state.has_flag(_hint_flag(n + 1)):
		n += 1
	return n


## The latest unlocked hint, or "".
func hint(state: GameState) -> String:
	var level := hint_level(state)
	return str(def["hints"][level - 1]) if level > 0 else ""


## Answer options as [{id, text}].
func options() -> Array:
	return def.get("answer_options", [])


func _hint_flag(level: int) -> String:
	return "mystery.%s.hint%d" % [id(), level]
