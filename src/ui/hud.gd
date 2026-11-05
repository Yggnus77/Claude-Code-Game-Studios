class_name Hud
extends CanvasLayer
## Life display: amber bar plus the number, which is the rule's source of truth
## (design/kit/auditoria-e-decisoes.md item 5). Placeholder art.

const COLOR_BACK := Color("1a1c22")
const COLOR_LIFE := Color("e0a030")
const COLOR_EMPTY := Color("4a3a24")

var _bar: Control
var _label: Label
var _banner: Label
var _current := 0
var _maximum := 1


func _ready() -> void:
	layer = 5
	_bar = Control.new()
	_bar.position = Vector2(8, 8)
	_bar.size = Vector2(120, 10)
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	_label = Label.new()
	_label.position = Vector2(134, 2)
	_label.add_theme_font_size_override("font_size", 12)
	add_child(_label)
	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position.y = 40
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.visible = false
	add_child(_banner)
	var hint := Label.new()
	hint.text = "WASD andar · J espada · Espaço esquiva · Shift defesa · R reinicia a sala · Esc pausa"
	hint.add_theme_font_size_override("font_size", 9)
	hint.modulate = Color(1, 1, 1, 0.7)
	hint.position = Vector2(6, 342)
	add_child(hint)


## Follows [param health]'s changes.
func bind(health: Health) -> void:
	health.changed.connect(set_life)
	set_life(health.current, health.maximum)


func set_life(current: int, maximum: int) -> void:
	_current = current
	_maximum = maxi(1, maximum)
	_label.text = "%d/%d" % [current, maximum]
	_bar.queue_redraw()


## Shows a centred message, or hides it with an empty string.
func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = not text.is_empty()


func _draw_bar() -> void:
	var size := _bar.size
	_bar.draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), COLOR_BACK)
	_bar.draw_rect(Rect2(Vector2.ZERO, size), COLOR_EMPTY)
	_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * _current / _maximum, size.y)), COLOR_LIFE)
	for i in range(1, _maximum):
		var x := size.x * i / _maximum
		_bar.draw_line(Vector2(x, 0), Vector2(x, size.y), COLOR_BACK, 1.0)
