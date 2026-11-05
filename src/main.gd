extends Node2D
## Entry scene: loads one prototype room, places Yggnus at its entry and spawns
## the enemies the room lists (only the Rastejo exists so far).
## Command-line user args (after `--`):
##   --room=<id>              open another prototype room;
##   --autowalk=<x>,<y>       hold that movement input (for recorded evidence runs);
##   --spawn=<enemy>@<col>,<row>  add an enemy on that tile;
##   --autoattack             press attack every 0.4 s (for recorded evidence runs).

const PLAYER_SCENE := preload("res://src/scenes/player.tscn")
const DEFAULT_ROOM := "r00_estrada"
## Seconds between death and returning to the room entry.
const RESPAWN_DELAY := 1.2
## Enemy kinds that have an implementation, by inimigos.json id.
const ENEMY_SCRIPTS := {
	"rastejo_tinta": preload("res://src/enemies/rastejo.gd"),
}

var config: GameConfig
var room: Room
var room_id := ""
var player: Player
var enemies: Array[Node] = []
var _autoattack := false
var _autoattack_timer := 0.0

@onready var hud: Hud = $Hud


func _ready() -> void:
	config = GameConfig.load_all()
	load_room(_arg("--room=", DEFAULT_ROOM))
	var walk := _arg("--autowalk=", "")
	if not walk.is_empty() and player:
		var parts := walk.split(",")
		player.read_input = false
		player.input_override = Vector2(float(parts[0]), float(parts[1]))
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--spawn="):
			var spec := arg.trim_prefix("--spawn=").split("@")
			var tile := spec[1].split(",")
			spawn_enemy(spec[0], Vector2i(int(tile[0]), int(tile[1])))
	_autoattack = "--autoattack" in OS.get_cmdline_user_args()


## Builds [param id], (re)places the player and spawns the room's enemies.
func load_room(id: String) -> void:
	var data := RoomData.load_room(id)
	if data == null:
		return
	room_id = id
	if room == null:
		room = Room.new()
		add_child(room)
		move_child(room, 0)
	room.build(data)
	if player == null:
		player = PLAYER_SCENE.instantiate()
		player.configure(config)
		add_child(player)
		player.died.connect(_on_player_died)
		if hud:
			hud.bind(player.health)
	player.respawn_at(data.tile_center(data.entry_default))
	player.set_camera_limits(data.pixel_size())
	clear_enemies()
	for entity in data.entities:
		var kind := str(entity.get("kind", ""))
		if ENEMY_SCRIPTS.has(kind):
			var t: Array = entity.get("tile", [0, 0])
			spawn_enemy(kind, Vector2i(int(t[0]), int(t[1])))


## Adds enemy [param kind] on [param tile]. Returns it, or null if unknown.
func spawn_enemy(kind: String, tile: Vector2i) -> Node:
	if not ENEMY_SCRIPTS.has(kind) or room == null:
		return null
	var enemy: Node2D = ENEMY_SCRIPTS[kind].new()
	enemy.setup(config.enemy(kind), player)
	enemy.position = room.data.tile_center(tile)
	add_child(enemy)
	enemies.append(enemy)
	return enemy


func clear_enemies() -> void:
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	enemies.clear()


func _physics_process(delta: float) -> void:
	if _autoattack and player and not player.is_dead():
		_autoattack_timer -= delta
		if _autoattack_timer <= 0.0:
			_autoattack_timer = 0.4
			player.request_attack()


func _on_player_died() -> void:
	if hud:
		hud.show_banner("Yggnus caiu")
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	if hud:
		hud.show_banner("")
	# Death keeps progress; the room's common enemies reset (mecanicas §9).
	load_room(room_id)


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
