class_name DialogueService
extends Node
## Turns semantic world events ("examinar_relogio", "obter_gancho"...) into
## scenes. Blocking scenes pause the world and never start while the player
## is attacking, dodging or stunned — they wait until the player is free.
## Barks are non-modal: their text shows briefly and their effects apply at once.

signal scene_started(scene_id: String)
signal scene_finished(scene_id: String, applied: bool)
signal bark(text: String)

var db: DialogueDB
var state: GameState
var box: DialogueBox
## Callable returning true while the player is busy (attack, dodge, hit stun).
var player_busy: Callable = func() -> bool: return false

var _pending: Array[String] = []
var _active_id := ""
## Pause state found when the scene opened; restored when it closes, so a
## scene never unpauses a shop, the inventory or a door fade.
var _paused_before := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func setup(scene_db: DialogueDB, game_state: GameState, dialogue_box: DialogueBox) -> void:
	db = scene_db
	state = game_state
	box = dialogue_box
	box.closed.connect(_on_box_closed)


func is_open() -> bool:
	return not _active_id.is_empty()


## Id of the blocking scene [param trigger] would play now, or "" when it
## resolves to nothing or to a bark (barks never report scene_finished).
func blocking_scene_id(trigger: String) -> String:
	var scene := db.scene_for(trigger, state, _now())
	if scene.is_empty() or scene.get("delivery", "") == "bark":
		return ""
	return str(scene["id"])


## Raises [param trigger]. Returns true if a scene played or was queued.
func request(trigger: String) -> bool:
	var scene := db.scene_for(trigger, state, _now())
	if scene.is_empty():
		return false
	if scene.get("delivery", "") == "bark":
		_play_bark(scene)
		return true
	if is_open() or player_busy.call():
		if not _pending.has(trigger):
			_pending.append(trigger)
		return true
	_start(scene)
	return true


func _physics_process(_delta: float) -> void:
	if _pending.is_empty() or is_open() or player_busy.call() or get_tree().paused:
		return
	var trigger: String = _pending.pop_front()
	var scene := db.scene_for(trigger, state, _now())
	if not scene.is_empty():
		_start(scene)


func _start(scene: Dictionary) -> void:
	_active_id = str(scene["id"])
	db.mark_played(_active_id, _now())
	var runner := DialogueRunner.new(scene, state)
	runner.finished.connect(func(ok: bool) -> void: scene_finished.emit(scene["id"], ok))
	_paused_before = get_tree().paused
	get_tree().paused = true
	scene_started.emit(_active_id)
	box.open(runner)


func _play_bark(scene: Dictionary) -> void:
	db.mark_played(str(scene["id"]), _now())
	# Every line of the bark, with its speaker (t09's hint is its second line).
	var nodes := {}
	for n: Dictionary in scene.get("nodes", []):
		nodes[str(n.get("id", ""))] = n
	var lines := PackedStringArray()
	var id := str(scene.get("entry_node", ""))
	while nodes.has(id) and lines.size() < 8:
		var n: Dictionary = nodes[id]
		if ["line", "direction"].has(str(n.get("type", ""))):
			var who := str(n.get("speaker", ""))
			var said := str(n.get("text", ""))
			lines.append(said if who.is_empty() or who == "SISTEMA" else "%s: %s" % [DialogueBox.display_name(who), said])
		id = str(n.get("next", ""))
	DialogueRunner.new(scene, state).skip()
	bark.emit("\n".join(lines))


func _on_box_closed() -> void:
	_active_id = ""
	get_tree().paused = _paused_before
	_paused_before = false


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
