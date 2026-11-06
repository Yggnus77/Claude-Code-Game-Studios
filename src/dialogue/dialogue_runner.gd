class_name DialogueRunner
extends RefCounted
## Walks one scene node by node. Finishing and skipping both end in
## [method _finish], which applies the scene's completion effects once, in a
## single [method GameState.apply] transaction (skip_policy
## "complete_same_transaction").

signal finished(applied: bool)

var scene: Dictionary
var state: GameState
var node_id := ""
var is_finished := false
## Every line shown so far: [{speaker, text}], kept whole for the history.
var history: Array = []
var _nodes: Dictionary = {}


func _init(scene_data: Dictionary, game_state: GameState) -> void:
	scene = scene_data
	state = game_state
	for n in scene.get("nodes", []):
		_nodes[str(n["id"])] = n
	_go(str(scene.get("entry_node", "")))


## The node being shown.
func node() -> Dictionary:
	return _nodes.get(node_id, {})


func is_choice() -> bool:
	return node().get("type", "") == "choice"


## Moves past a line or direction. Ignored on a choice (use [method choose]).
func advance() -> void:
	if is_finished or is_choice():
		return
	_go(str(node().get("next", "")))


## Picks option [param index] of the current choice.
func choose(index: int) -> void:
	if is_finished or not is_choice():
		return
	var options: Array = node().get("options", [])
	if index < 0 or index >= options.size():
		return
	history.append({"speaker": "YGGNUS", "text": str(options[index].get("text", ""))})
	_go(str(options[index].get("next", "")))


## Ends the scene now with exactly the same effects as reading it through.
func skip() -> void:
	_finish()


func _go(id: String) -> void:
	node_id = id
	var n := node()
	var kind := str(n.get("type", "end"))
	if n.is_empty() or kind == "end":
		_finish()
		return
	if kind == "line" or kind == "direction":
		history.append({"speaker": str(n.get("speaker", "")), "text": str(n.get("text", ""))})


func _finish() -> void:
	if is_finished:
		return
	is_finished = true
	var ok := state.apply(scene.get("completion_effects", []))
	finished.emit(ok)
