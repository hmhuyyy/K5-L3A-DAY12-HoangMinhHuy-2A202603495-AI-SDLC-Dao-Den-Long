# GameScene.gd — 3D main scene (Phase 2). Drives GameSim at fixed 60 tick/s.
# Passive view: reads GameSim state, owns ZERO game logic.
extends Node3D

const TICK_RATE := 60.0
var _cfg: Config
var _sim: GameSim
var _input_state: InputState
var _accumulator: float = 0.0
var _cam_yaw: float = 0.0
var _night: int = 1

@onready var _player_node: Node3D = $Player3D
@onready var _camera: Camera3D = $Camera3D
@onready var _mote_parent: Node3D = $Motes
@onready var _shade_parent: Node3D = $Shades
@onready var _lantern_parent: Node3D = $Lanterns
@onready var _hud: CanvasLayer = $HUD

var _mote_nodes: Dictionary = {}
var _shade_nodes: Dictionary = {}
var _lantern_nodes: Dictionary = {}

func _ready() -> void:
	_cfg = Config.load_from_file("res://game.contract.json")
	_sim = GameSim.new()
	# Use a reproducible seed for play mode; override via autostart arg if needed
	var seed_val := randi() % 100000 + 1
	_sim.init(_cfg, seed_val, _night, {})
	_input_state = InputState.new()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_visuals()
	_sync_visuals()

func _process(delta: float) -> void:
	_accumulator += delta
	var step := 1.0 / TICK_RATE
	while _accumulator >= step:
		_accumulator -= step
		_read_input()
		if _sim.state == "won" or _sim.state == "lost":
			break
		_sim.tick(_input_state)
	_sync_visuals()
	_update_hud()

func _read_input() -> void:
	_input_state.advance_prev()
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    move.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  move.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
	_input_state.move = move
	_input_state.cam_yaw_deg = _cam_yaw
	_input_state.jump     = Input.is_key_pressed(KEY_SPACE)
	_input_state.interact = Input.is_key_pressed(KEY_E)
	_input_state.pulse    = Input.is_key_pressed(KEY_Q)
	_input_state.dash     = Input.is_key_pressed(KEY_SHIFT)
	_input_state.pause    = false  # mapped via ui_cancel below

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam_yaw -= event.relative.x * 0.25
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_visuals() -> void:
	for ld: Entities.LanternData in _sim.lanterns:
		var post := MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.2)
		var cyl := CylinderMesh.new()
		cyl.height = 3.0; cyl.top_radius = 0.2; cyl.bottom_radius = 0.3
		post.mesh = cyl; post.material_override = mat; post.position = ld.pos
		var lamp := OmniLight3D.new()
		lamp.position = ld.pos + Vector3(0, 3, 0)
		lamp.light_color = Color(1.0, 0.7, 0.3)
		lamp.light_energy = 0.0; lamp.omni_range = 10.0
		_lantern_parent.add_child(post); _lantern_parent.add_child(lamp)
		_lantern_nodes[ld.id] = {"post": post, "lamp": lamp}
	# Island ground disc
	var ground := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 40.0; gm.bottom_radius = 40.0; gm.height = 0.5
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.15, 0.25, 0.35)
	ground.material_override = gmat; ground.position = Vector3(0, -0.25, 0)
	add_child(ground)

func _sync_visuals() -> void:
	_player_node.position = _sim.player.pos
	# Third-person camera follows player
	var cam_offset := Vector3(sin(deg_to_rad(_cam_yaw)) * 6.0, 4.0, cos(deg_to_rad(_cam_yaw)) * 6.0)
	_camera.position = _sim.player.pos + cam_offset
	_camera.look_at(_sim.player.pos + Vector3(0, 1, 0))
	# Lanterns
	for ld: Entities.LanternData in _sim.lanterns:
		if _lantern_nodes.has(ld.id):
			var lamp: OmniLight3D = _lantern_nodes[ld.id]["lamp"]
			lamp.light_energy = 2.0 if ld.lit else 0.0
	# Shades
	for sd: Entities.ShadeData in _sim.shades:
		if not _shade_nodes.has(sd.id):
			var m := MeshInstance3D.new()
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.07, 0.04, 0.1)
			mat.emission = Color(0.48, 0.24, 1.0)  # #7A3CFF
			mat.emission_energy_multiplier = 0.6
			var spher := SphereMesh.new(); spher.radius = 0.6
			m.mesh = spher; m.material_override = mat
			_shade_parent.add_child(m); _shade_nodes[sd.id] = m
		var sn: MeshInstance3D = _shade_nodes[sd.id]
		sn.position = sd.pos + Vector3(0, 0.6, 0)
		sn.visible = sd.state != Entities.SHADE_STUNNED or (Time.get_ticks_msec() / 150) % 2 == 0
	# Motes
	for md: Entities.MoteData in _sim.motes:
		if md.active and not _mote_nodes.has(md.id):
			var m := MeshInstance3D.new()
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.85, 0.4)
			mat.emission = Color(1.0, 0.9, 0.5)
			mat.emission_energy_multiplier = 1.2
			var spher := SphereMesh.new(); spher.radius = 0.15
			m.mesh = spher; m.material_override = mat
			_mote_parent.add_child(m); _mote_nodes[md.id] = m
		if _mote_nodes.has(md.id):
			var mn: MeshInstance3D = _mote_nodes[md.id]
			mn.position = md.pos + Vector3(0, 0.5, 0)
			mn.visible = md.active

func _update_hud() -> void:
	if _hud and _hud.get_child_count() > 0:
		var label: Label = _hud.get_child(0)
		var state_str := ""
		if _sim.state == "paused":
			state_str = "  [PAUSED]"
		elif _sim.state == "won":
			state_str = "  VICTORY!"
		elif _sim.state == "lost":
			state_str = "  GAME OVER"
		label.text = "Night %d  Carried: %d/%d  Flames: %d  Score: %d  Time: %.0fs%s" % [
			_sim.night, _sim.player.carried, _sim.player.capacity,
			_sim.player.flames, _sim.score, _sim.time_left_s(), state_str
		]
