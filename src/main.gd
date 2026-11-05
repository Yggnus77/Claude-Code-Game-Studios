extends Node2D
## Entry scene for step 1: loads one prototype room and places Yggnus at its
## default entry. Command-line user args (after `--`):
##   --room=<id>        open another prototype room;
##   --autowalk=<x>,<y> hold that movement input (for recorded evidence runs).

const PLAYER_SCENE := preload("res://src/scenes/player.tscn")
const DEFAULT_ROOM := "t00_base"

var config: GameConfig
var room: Room
var player: Player


func _ready() -> void:
	config = GameConfig.load_from()
	load_room(_arg("--room=", DEFAULT_ROOM))
	var walk := _arg("--autowalk=", "")
	if not walk.is_empty() and player:
		var parts := walk.split(",")
		player.read_input = false
		player.input_override = Vector2(float(parts[0]), float(parts[1]))


## Builds [param room_id] and (re)places the player at its entry.
func load_room(room_id: String) -> void:
	var data := RoomData.load_room(room_id)
	if data == null:
		return
	if room == null:
		room = Room.new()
		add_child(room)
	room.build(data)
	if player == null:
		player = PLAYER_SCENE.instantiate()
		player.configure(config)
		add_child(player)
	player.global_position = data.tile_center(data.entry_default)
	player.velocity = Vector2.ZERO
	player.set_camera_limits(data.pixel_size())


func _arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback
