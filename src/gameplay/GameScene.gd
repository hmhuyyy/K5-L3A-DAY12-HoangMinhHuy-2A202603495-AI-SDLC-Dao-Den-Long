# GameScene.gd — 3D main scene. Drives GameSim at fixed 60 tick/s and syncs
# visual nodes to simulation state. Owns ZERO game logic.
extends Node3D

const TICK_RATE := 60.0
var _cfg: Config
var _sim: GameSim
var _input_state: InputState
var _accumulator: float = 0.0
var _cam_yaw: float = 0.0

@onready var _player_node: Node3D = $Player3D
@onready var _camera: Camera3D = $Camera3D
@onready var _mote_parent: Node3D = $Motes
@onready var _shade_parent: Node3D = $Shades
@onready var _lantern_parent: Node3D = $Lanterns
@onready var _hud: CanvasLayer = $HUD

# Visual instances keyed by entity id
var _mote_nodes: Dictionary = {}
var _shade_nodes: Dictionary = {}
var _lantern_nodes: Dictionary = {}

func _ready() -> void:
	_cfg = Config.load_from_file("res://game.contract.json")
	_sim = GameSim.new()
	_sim.init(_cfg, randi() % 100000 + 1, 1, {})
	_input_state = InputState.new()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_build_visuals()
	_sync_visuals()

func _process(delta: float) -> void:
	# Fixed timestep accumulator: run sim at exactly 60 tick/s
	_accumulator += delta
	var step := 1.0 / TICK_RATE
	while _accumulator >= step:
		_accumulator -= step
		_read_input()
		_sim.tick(_input_state)
	_sync_visuals()
	_update_hud()

func _read_input() -> void:
	# Capture current input state for this tick
	_input_state.advance_prev()
	var move := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    move.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  move.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  move.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): move.x += 1.0
	_input_state.move = move
	_input_state.cam_yaw_deg = _cam_yaw
	_input_state.jump    = Input.is_key_pressed(KEY_SPACE)
	_input_state.interact = Input.is_key_pressed(KEY_E)
	_input_state.pulse   = Input.is_key_pressed(KEY_Q)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam_yaw -= event.relative.x * 0.25
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_visuals() -> void:
	for ld in _sim.lanterns:
		var post := MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.3, 0.2)
		var cyl := CylinderMesh.new()
		cyl.height = 3.0
		cyl.top_radius = 0.2
		cyl.bottom_radius = 0.3
		post.mesh = cyl
		post.material_override = mat
		post.position = ld.pos
		var lamp := OmniLight3D.new()
		lamp.position = ld.pos + Vector3(0, 3, 0)
		lamp.light_color = Color(1.0, 0.7, 0.3)
		lamp.light_energy = 0.0
		lamp.omni_range = 8.0
		_lantern_parent.add_child(post)
		_lantern_parent.add_child(lamp)
		_lantern_nodes[ld.id] = {"post": post, "lamp": lamp}
	# Ground
	var ground := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 40.0
	gm.bottom_radius = 40.0
	gm.height = 0.5
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.15, 0.25, 0.35)
	ground.material_override = gmat
	ground.position = Vector3(0, -0.25, 0)
	add_child(ground)

func _sync_visuals() -> void:
	_player_node.position = _sim.player.pos
	_camera.position = _sim.player.pos + Vector3(0, 4, -6)
	_camera.look_at(_sim.player.pos + Vector3(0, 1, 0))
	for ld in _sim.lanterns:
		if _lantern_nodes.has(ld.id):
			var l: Dictionary = _lantern_nodes[ld.id]
			var lamp: OmniLight3D = l["lamp"]
			lamp.light_energy = 2.0 if ld.lit else 0.0
	for sd in _sim.shades:
		if not _shade_nodes.has(sd.id):
			var m := MeshInstance3D.new()
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.1, 0.05, 0.2)
			mat.emission = Color(0.3, 0.0, 0.4)
			mat.emission_energy_multiplier = 0.5
			var spher := SphereMesh.new()
			spher.radius = 0.6
			m.mesh = spher
			m.material_override = mat
			_shade_parent.add_child(m)
			_shade_nodes[sd.id] = m
		var sn: MeshInstance3D = _shade_nodes[sd.id]
		sn.position = sd.pos + Vector3(0, 0.6, 0)
	for md in _sim.motes:
		if md.active and not _mote_nodes.has(md.id):
			var m := MeshInstance3D.new()
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(1.0, 0.85, 0.4)
			mat.emission = Color(1.0, 0.8, 0.3)
			mat.emission_energy_multiplier = 1.0
			var spher := SphereMesh.new()
			spher.radius = 0.15
			m.mesh = spher
			m.material_override = mat
			_mote_parent.add_child(m)
			_mote_nodes[md.id] = m
		if _mote_nodes.has(md.id):
			var mn: MeshInstance3D = _mote_nodes[md.id]
			mn.position = md.pos + Vector3(0, 0.5, 0)
			mn.visible = md.active

func _update_hud() -> void:
	if _hud and _hud.get_child_count() > 0:
		var label: Label = _hud.get_child(0)
		label.text = "Carried: %d / %d   Flames: %d   Score: %d   Time: %.0fs" % [
			_sim.player.carried, _cfg.carry_capacity, _sim.player.flames,
			_sim.score, _sim.time_left_s()]
