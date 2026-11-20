# InputState.gd — Holds current and previous input frame (Phase 2).
# Handles persistence and rising-edge detection for jump/interact/pulse/dash/pause.
class_name InputState
extends RefCounted

# Movement: [x, z] components, each in [-1, 1]. Applied with yaw rotation.
var move: Vector2 = Vector2.ZERO
var cam_yaw_deg: float = 0.0

# Level-triggered (persist until changed)
var sprint: bool = false

# Edge-detected buttons (activation on false->true transition)
var jump: bool = false
var interact: bool = false
var pulse: bool = false
var dash: bool = false     # Phase 2 new
var pause: bool = false    # Phase 2 new

# Previous frame state for edge detection
var _prev_jump: bool = false
var _prev_interact: bool = false
var _prev_pulse: bool = false
var _prev_dash: bool = false
var _prev_pause: bool = false

func jump_edge() -> bool:
	return jump and not _prev_jump

func interact_edge() -> bool:
	return interact and not _prev_interact

func pulse_edge() -> bool:
	return pulse and not _prev_pulse

func dash_edge() -> bool:
	return dash and not _prev_dash

func pause_edge() -> bool:
	return pause and not _prev_pause

func advance_prev() -> void:
	_prev_jump    = jump
	_prev_interact = interact
	_prev_pulse   = pulse
	_prev_dash    = dash
	_prev_pause   = pause

func apply_frame(frame: Dictionary) -> void:
	if frame.has("move"):
		var m: Array = frame["move"]
		move = Vector2(float(m[0]), float(m[1]))
	if frame.has("cam_yaw_deg"):
		cam_yaw_deg = float(frame["cam_yaw_deg"])
	if frame.has("sprint"):
		sprint = bool(frame["sprint"])
	if frame.has("jump"):
		jump = bool(frame["jump"])
	if frame.has("interact"):
		interact = bool(frame["interact"])
	if frame.has("pulse"):
		pulse = bool(frame["pulse"])
	if frame.has("dash"):
		dash = bool(frame["dash"])
	if frame.has("pause"):
		pause = bool(frame["pause"])

# World-space direction from move vector and yaw. Returns Vector2(x', z').
# If length > 1, normalized to 1.
func world_move() -> Vector2:
	if move.is_zero_approx():
		return Vector2.ZERO
	var theta := deg_to_rad(cam_yaw_deg)
	var cos_t := cos(theta)
	var sin_t := sin(theta)
	var wx: float = move.x * cos_t + move.y * sin_t
	var wz: float = -move.x * sin_t + move.y * cos_t
	var v := Vector2(wx, wz)
	if v.length_squared() > 1.0:
		v = v.normalized()
	return v

