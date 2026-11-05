class_name Player
extends CharacterBody2D
## Yggnus, step 1: walking, wall sliding and a following camera.
## Movement maths lives in [PlayerMotor]; this node feeds it input and
## applies the result with move_and_slide() in the physics step only, so
## the distance walked does not depend on the render frame rate.

const COLOR_BODY := Color("e8d9b5")
const COLOR_CLOAK := Color("3d6fa8")
const COLOR_FACING := Color("f2c14e")

var motor: PlayerMotor
## Size of the drawn placeholder sprite (combate.json player.sprite_frame).
var sprite_frame := Vector2(32, 48)
## When false the node ignores the input map (tests drive [member input_override]).
var read_input := true
## Movement input used when [member read_input] is false.
var input_override := Vector2.ZERO

@onready var camera: Camera2D = $Camera2D
@onready var feet: CollisionShape2D = $Feet


## Applies the movement parameters from [param config]. Call before adding
## the player to the tree.
func configure(config: GameConfig) -> void:
	var p := config.player()
	motor = PlayerMotor.new(p)
	var frame: Array = p.get("sprite_frame", [32, 48])
	sprite_frame = Vector2(frame[0], frame[1])
	var foot: Array = p.get("foot_collision", [12, 10])
	_pending_foot = Vector2(foot[0], foot[1])


var _pending_foot := Vector2(12, 10)


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = _pending_foot
	feet.shape = rect
	# Feet sit at the bottom of the sprite; the node origin is the feet centre.
	feet.position = Vector2.ZERO
	queue_redraw()


## Clamps the camera to the room so it never shows outside the map.
func set_camera_limits(size_px: Vector2i) -> void:
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = size_px.x
	camera.limit_bottom = size_px.y
	camera.reset_smoothing()
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if motor == null:
		return
	var input := input_override
	if read_input:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = motor.step(velocity, input, delta)
	move_and_slide()
	queue_redraw()


func _draw() -> void:
	var w := sprite_frame.x
	var h := sprite_frame.y
	# Placeholder: cloak block, head, and a mark showing the facing direction.
	draw_rect(Rect2(Vector2(-w * 0.3, -h * 0.75), Vector2(w * 0.6, h * 0.7)), COLOR_CLOAK)
	draw_circle(Vector2(0, -h * 0.8), w * 0.22, COLOR_BODY)
	var f := motor.facing if motor else Vector2.DOWN
	draw_circle(Vector2(0, -h * 0.4) + f * w * 0.35, 3.0, COLOR_FACING)
