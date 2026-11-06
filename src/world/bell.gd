class_name Bell
extends Node2D
## A bell of the Galeria dos sinos. Strike it with the sword; each swing
## rings it once. Joins "enemies" only so the sword finds it.

signal rung(bell_id: String)

const COLOR_BRONZE := Color("c98b3a")
const COLOR_MARK := Color("1a1c22")

var bell_id := ""
## "circle", "gap" or "waves": the mark drawn on the bell's plate.
var symbol := ""
var _seen_attacks: Dictionary = {}
var _flash := 0.0
## 0 dark, 1 lit (sequence progress shown by the room).
var lit := false


func _ready() -> void:
	add_to_group("enemies")


func body_radius() -> float:
	return 8.0


func receive_sword_hit(_damage: int, attack_id: int, _from: Vector2) -> bool:
	if _seen_attacks.has(attack_id):
		return false
	_seen_attacks[attack_id] = true
	_flash = 0.25
	rung.emit(bell_id)
	queue_redraw()
	return true


func _physics_process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta)
		queue_redraw()


func _draw() -> void:
	var swing := sin(_flash * 40.0) * 2.0 if _flash > 0.0 else 0.0
	var body := PackedVector2Array([Vector2(-7 + swing, 2), Vector2(7 + swing, 2), Vector2(5 + swing, -10), Vector2(-5 + swing, -10)])
	if lit:
		# A lit bell glows, so the order reads from across the room.
		draw_circle(Vector2(swing, -4), 13.0, Color(1.0, 0.85, 0.4, 0.25))
		draw_arc(Vector2(swing, -4), 13.0, 0, TAU, 24, Color(1.0, 0.85, 0.4, 0.9), 1.5)
	draw_colored_polygon(body, COLOR_BRONZE.lightened(0.4) if _flash > 0.0 or lit else COLOR_BRONZE)
	draw_circle(Vector2(swing, 4), 2.0, COLOR_BRONZE.darkened(0.3))
	# Plate under the bell with its mark.
	var plate := Vector2(0, 14)
	draw_rect(Rect2(plate - Vector2(6, 4), Vector2(12, 8)), Color("4a3a24"))
	match symbol:
		"circle":
			draw_arc(plate, 2.5, 0, TAU, 12, COLOR_MARK.lightened(0.8), 1.0)
		"gap":
			draw_line(plate + Vector2(-3, 0), plate + Vector2(-1, 0), COLOR_MARK.lightened(0.8), 1.0)
			draw_line(plate + Vector2(1, 0), plate + Vector2(3, 0), COLOR_MARK.lightened(0.8), 1.0)
		"waves":
			for i in 3:
				draw_line(plate + Vector2(-3 + i * 2, 1), plate + Vector2(-2 + i * 2, -1), COLOR_MARK.lightened(0.8), 1.0)
