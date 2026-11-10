class_name SwordSwing
extends RefCounted
## The classic sword (design/gdd/jogabilidade-classica.md §3.1–3.2, numbers
## in combate.json "sword"): one wide swing per press; holding the button
## after the swing charges the blade, which pokes whatever touches it;
## releasing a full charge spins the blade all the way round.
## Pure: the player feeds it presses, the button state and time, and asks
## where the blade is. Angles are radians relative to the facing, growing
## clockwise on screen.
##
## Example:
##   var s := SwordSwing.new(config.sword(), 1)
##   s.press()
##   s.set_held(true)
##   s.tick(1.0 / 60.0)            # "swing" on the step the swing starts
##   s.sweep()                     # Vector2(from, to) the blade covered

enum Phase { IDLE, SWING, CHARGE, SPIN }

static var _next_attack_id := 1

var swing_startup := 0.03
var swing_active := 0.12
var swing_recovery := 0.08
var arc_from := deg_to_rad(-100.0)
var arc_to := deg_to_rad(75.0)
## Distance from the pivot to the tip, and to where the blade starts.
var reach := 27.0
var blade_inner := 5.0
## Hit pivot relative to the feet.
var hit_pivot := Vector2(0, -6)
var charge_time := 0.75
var charge_speed_factor := 0.55
var spin_time := 0.36
var spin_sweep := deg_to_rad(380.0)
var spin_reach := 31.0
var spin_damage_factor := 2
var poke_damage := 1
var poke_interval := 0.35
var input_buffer := 0.12
## Damage of one swing (combate.json "weapons").
var damage_base := 1

var phase: Phase = Phase.IDLE
## Unique id of the current cut (a new one per swing, spin and poke window).
var attack_id := 0
## Seconds the blade has been held charging.
var charge := 0.0
var _t := 0.0
var _held := false
var _buffer := 0.0
var _poke_left := 0.0
var _angle := 0.0
var _prev_angle := 0.0


## [param params] is combate.json "sword"; [param damage] the weapon's.
func _init(params: Dictionary = {}, damage: int = 1, buffer: float = 0.12) -> void:
	swing_startup = float(params.get("swing_startup", swing_startup))
	swing_active = maxf(0.01, float(params.get("swing_active", swing_active)))
	swing_recovery = float(params.get("swing_recovery", swing_recovery))
	arc_from = deg_to_rad(float(params.get("arc_from", -100.0)))
	arc_to = deg_to_rad(float(params.get("arc_to", 75.0)))
	reach = float(params.get("reach", reach))
	blade_inner = float(params.get("blade_inner", blade_inner))
	var pv: Variant = params.get("hit_pivot", [hit_pivot.x, hit_pivot.y])
	if pv is Array and (pv as Array).size() == 2:
		hit_pivot = Vector2(float(pv[0]), float(pv[1]))
	charge_time = float(params.get("charge_time", charge_time))
	charge_speed_factor = float(params.get("charge_speed_factor", charge_speed_factor))
	spin_time = maxf(0.01, float(params.get("spin_time", spin_time)))
	spin_sweep = deg_to_rad(float(params.get("spin_degrees", 380.0)))
	spin_reach = float(params.get("spin_reach", spin_reach))
	spin_damage_factor = int(params.get("spin_damage_factor", spin_damage_factor))
	poke_damage = int(params.get("poke_damage", poke_damage))
	poke_interval = maxf(0.05, float(params.get("poke_interval", poke_interval)))
	damage_base = maxi(1, damage)
	input_buffer = buffer


## Registers a press of the sword button.
func press() -> void:
	_buffer = input_buffer


## Feeds the button state every step (held after a swing = charge).
func set_held(value: bool) -> void:
	_held = value


func is_busy() -> bool:
	return phase != Phase.IDLE


## True while the swing or the spin keeps Yggnus standing.
func is_swinging() -> bool:
	return phase == Phase.SWING or phase == Phase.SPIN


func is_charging() -> bool:
	return phase == Phase.CHARGE


func is_charged() -> bool:
	return phase == Phase.CHARGE and charge >= charge_time


## True while the swing's start can still be aimed.
func in_startup() -> bool:
	return phase == Phase.SWING and _t < swing_startup


## True while the blade cuts: the swing's active part, the spin, and the
## held blade (which pokes).
func is_cutting() -> bool:
	match phase:
		Phase.SWING:
			return _t >= swing_startup and _t <= swing_startup + swing_active + 0.0001
		Phase.SPIN, Phase.CHARGE:
			return true
	return false


## Where the blade points now, relative to the facing.
func angle() -> float:
	return _angle


## The blade's sweep since the last step: Vector2(from, to), relative angles.
func sweep() -> Vector2:
	return Vector2(_prev_angle, _angle)


## Reach of the blade now (the spin reaches further).
func current_reach() -> float:
	return spin_reach if phase == Phase.SPIN else reach


## Damage of the cut in progress.
func damage() -> int:
	match phase:
		Phase.SPIN:
			return damage_base * spin_damage_factor
		Phase.CHARGE:
			return poke_damage
	return damage_base


## Advances [param delta] seconds. Returns "swing" or "spin" on the step
## one starts, "charged" on the step the charge fills, "" otherwise.
func tick(delta: float) -> String:
	_buffer = maxf(0.0, _buffer - delta)
	_prev_angle = _angle
	var event := ""
	match phase:
		Phase.SWING:
			_t += delta
			_angle = _swing_angle(_t)
			if _t >= swing_startup + swing_active + swing_recovery:
				if _held:
					phase = Phase.CHARGE
					charge = 0.0
					_t = 0.0
					_angle = 0.0
					_prev_angle = 0.0
					_new_id()
					_poke_left = poke_interval
				else:
					_finish()
		Phase.CHARGE:
			if not _held:
				if charge >= charge_time:
					phase = Phase.SPIN
					_t = 0.0
					_angle = 0.0
					_prev_angle = 0.0
					_new_id()
					return "spin"
				_finish()
			else:
				var was_full := charge >= charge_time
				charge += delta
				if not was_full and charge >= charge_time:
					event = "charged"
				_poke_left -= delta
				if _poke_left <= 0.0:
					_poke_left += poke_interval
					_new_id()
		Phase.SPIN:
			_t += delta
			_angle = spin_sweep * minf(1.0, _t / spin_time)
			if _t >= spin_time:
				_finish()
	if phase == Phase.IDLE and _buffer > 0.0:
		_buffer = 0.0
		phase = Phase.SWING
		_t = 0.0
		_angle = arc_from
		_prev_angle = arc_from
		_new_id()
		return "swing"
	return event


## Ages the press buffer while Yggnus cannot swing (hooking, drinking...).
func tick_idle(delta: float) -> void:
	if phase == Phase.IDLE:
		_buffer = maxf(0.0, _buffer - delta)


## Stops the swing, the charge or the spin (hit stun, a tool).
func cancel() -> void:
	_finish()


## Forgets everything, the press buffer too (death, room change).
func reset() -> void:
	_finish()
	_buffer = 0.0


func _finish() -> void:
	phase = Phase.IDLE
	attack_id = 0
	charge = 0.0
	_t = 0.0
	_angle = 0.0
	_prev_angle = 0.0


func _new_id() -> void:
	attack_id = _next_attack_id
	_next_attack_id += 1


## The blade angle [param t] seconds into a swing: fast at first, braking
## at the end (jogabilidade-classica.md §4).
func _swing_angle(t: float) -> float:
	var u := clampf((t - swing_startup) / swing_active, 0.0, 1.0)
	var e := 1.0 - (1.0 - u) * (1.0 - u)
	return arc_from + (arc_to - arc_from) * e


## Whether a blade turning around [param pivot] (facing angle
## [param facing_angle]) from [param from] to [param to] (relative angles),
## from [param inner] to [param outer] px, touches a target of radius
## [param radius] at [param point] (jogabilidade-classica.md §4).
static func sweep_hits(pivot: Vector2, facing_angle: float, from: float, to: float, inner: float, outer: float, point: Vector2, radius: float) -> bool:
	var d := point - pivot
	var dist := d.length()
	if dist > outer + radius:
		return false
	if dist <= inner + radius:
		return true
	var lo := minf(from, to)
	var hi := maxf(from, to)
	if hi - lo >= TAU:
		return true
	var pad := asin(minf(1.0, radius / dist))
	var a := wrapf(d.angle() - facing_angle - lo, -pad, TAU - pad)
	return a <= hi - lo + pad
