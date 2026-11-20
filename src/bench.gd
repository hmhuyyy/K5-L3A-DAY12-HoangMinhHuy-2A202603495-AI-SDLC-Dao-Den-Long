# bench.gd — 3D Benchmark runner (TICKET-04 §3.1).
# Invoked via: godot --path . --script res://src/bench.gd -- --seed 42 --duration 30 --out bench.json
# Scene: 1280x720 windowed, VSync off if supported, Night 1, 200 wander Shades, 100 motes,
# L1-L3 lit fuel=100, no player input, player at (0,0,0), camera orbiting R=30m Y=15m looking at origin,
# start angle 0° at (30,15,0), CCW from above, 15s/rev. 3s warm-up, then measure duration seconds and quit(0).
extends SceneTree

const BenchStats := preload("res://src/core/BenchStats.gd")
const ProcMem := preload("res://src/core/ProcMem.gd")

const WARMUP_S := 3.0
const ORBIT_R := 30.0
const ORBIT_Y := 15.0
const ORBIT_PERIOD_S := 15.0
const TICK_RATE := 60.0

var _seed: int = 42
var _duration_s: float = 30.0
var _out_path: String = "bench.json"

var _cfg: Config
var _sim: GameSim
var _cam: Camera3D
var _shade_meshes: Dictionary = {}
var _mote_meshes: Dictionary = {}
var _lantern_lights: Dictionary = {}

var _first_frame_done: bool = false
var _load_ms: int = 0
var _vsync_off: bool = false
var _elapsed_s: float = 0.0
var _measure_s: float = 0.0
var _accumulator: float = 0.0
var _dts_ms: Array = []
var _peak_mem_mb: float = -1.0
var _mem_sample_accum: float = 0.0

func _init() -> void:
	if not _parse_args(OS.get_cmdline_user_args()):
		quit(1)
		return
	_cfg = Config.load_from_file("res://game.contract.json")
	if _cfg == null:
		printerr("bench.gd: failed to load res://game.contract.json")
		quit(1)
		return

	# Window 1280x720, not fullscreen, disable VSync if supported
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_vsync_off = (DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED)

	_sim = GameSim.new()
	_sim.init_bench(_cfg, _seed)
	_build_bench_scene()

func _parse_args(raw: PackedStringArray) -> bool:
	var i := 0
	var has_out := false
	while i < raw.size():
		match raw[i]:
			"--seed":
				i += 1
				if i >= raw.size() or not raw[i].is_valid_int():
					return _err("--seed requires an integer")
				_seed = raw[i].to_int()
			"--duration":
				i += 1
				if i >= raw.size() or not raw[i].is_valid_float():
					return _err("--duration requires a number")
				_duration_s = float(raw[i])
				if _duration_s <= 0.0:
					return _err("--duration must be > 0")
			"--out":
				i += 1
				if i >= raw.size():
					return _err("--out requires a file path")
				_out_path = raw[i]
				has_out = true
			_:
				return _err("unknown argument: " + raw[i])
		i += 1
	if not has_out or _out_path.is_empty():
		return _err("--out is required")
	return true

func _err(msg: String) -> bool:
	printerr("bench.gd: " + msg)
	printerr("Usage: godot --path . --script res://src/bench.gd -- --seed 42 --duration 30 --out bench.json")
	return false

func _build_bench_scene() -> void:
	var root3d := Node3D.new()
	root3d.name = "BenchScene"
	get_root().add_child(root3d)

	# Full lighting & environment (Night 1)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.22, 0.32)
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	root3d.add_child(we)

	var dir_light := DirectionalLight3D.new()
	dir_light.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	dir_light.light_color = Color(0.65, 0.75, 0.95)
	dir_light.light_energy = 0.6
	root3d.add_child(dir_light)

	# Island ground disc R=40
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
	root3d.add_child(ground)

	# Player at (0,0,0)
	var player_mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.2
	player_mesh.mesh = cap
	player_mesh.position = Vector3(0.0, 0.6, 0.0)
	root3d.add_child(player_mesh)

	# 5 Lanterns (L1-L3 lit with fuel=100, L4-L5 unlit)
	for ld: Entities.LanternData in _sim.lanterns:
		var post := MeshInstance3D.new()
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color("#FFB347") if ld.lit else Color("#5B5F6E")
		var cyl := CylinderMesh.new()
		cyl.height = 3.0
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.35
		post.mesh = cyl
		post.material_override = pmat
		post.position = ld.pos + Vector3(0, 1.5, 0)
		root3d.add_child(post)

		var lamp := OmniLight3D.new()
		lamp.position = ld.pos + Vector3(0, 3.0, 0)
		lamp.light_color = Color(1.0, 0.7, 0.3)
		lamp.light_energy = 2.4 if ld.lit else 0.0
		lamp.omni_range = 12.0
		root3d.add_child(lamp)
		_lantern_lights[ld.id] = lamp

	# 200 Shades in wander state
	var shade_sphere := SphereMesh.new()
	shade_sphere.radius = 0.6
	var shade_mat := StandardMaterial3D.new()
	shade_mat.albedo_color = Color(0.07, 0.04, 0.1)
	shade_mat.emission_enabled = true
	shade_mat.emission = Color("#7A3CFF")
	shade_mat.emission_energy_multiplier = 0.7
	for sd: Entities.ShadeData in _sim.shades:
		var sm := MeshInstance3D.new()
		sm.mesh = shade_sphere
		sm.material_override = shade_mat
		sm.position = sd.pos + Vector3(0, 0.6, 0)
		root3d.add_child(sm)
		_shade_meshes[sd.id] = sm

	# 100 Motes
	var mote_sphere := SphereMesh.new()
	mote_sphere.radius = 0.15
	var mote_mat := StandardMaterial3D.new()
	mote_mat.albedo_color = Color(1.0, 0.85, 0.4)
	mote_mat.emission_enabled = true
	mote_mat.emission = Color(1.0, 0.9, 0.5)
	mote_mat.emission_energy_multiplier = 1.2
	for md: Entities.MoteData in _sim.motes:
		var mm := MeshInstance3D.new()
		mm.mesh = mote_sphere
		mm.material_override = mote_mat
		mm.position = md.pos + Vector3(0, 0.5, 0)
		root3d.add_child(mm)
		_mote_meshes[md.id] = mm

	# Camera: starts at angle 0° -> (30, 15, 0), looking at (0, 0, 0)
	_cam = Camera3D.new()
	_cam.current = true
	root3d.add_child(_cam)
	_update_camera(0.0)

func _update_camera(t_s: float) -> void:
	# Counterclockwise when viewed from above (+Y): x = R*cos(a), z = R*sin(a), 15s per full revolution
	var angle := (t_s / ORBIT_PERIOD_S) * TAU
	var cx := ORBIT_R * cos(angle)
	var cz := ORBIT_R * sin(angle)
	_cam.look_at_from_position(Vector3(cx, ORBIT_Y, cz), Vector3.ZERO, Vector3.UP)

func _process(delta: float) -> bool:
	if not _first_frame_done:
		_first_frame_done = true
		_load_ms = Time.get_ticks_msec()
		return false

	_elapsed_s += delta
	_accumulator += delta
	var step := 1.0 / TICK_RATE
	while _accumulator >= step:
		_accumulator -= step
		_sim.tick(null)

	for sd: Entities.ShadeData in _sim.shades:
		if _shade_meshes.has(sd.id):
			var sm: MeshInstance3D = _shade_meshes[sd.id]
			sm.position = sd.pos + Vector3(0, 0.6, 0)

	_update_camera(_elapsed_s)

	if _elapsed_s > WARMUP_S:
		_dts_ms.append(delta * 1000.0)
		_measure_s += delta
		if _measure_s >= _duration_s:
			_finish_bench()
			return true
	return false

func _finish_bench() -> void:
	_peak_mem_mb = maxf(_peak_mem_mb, ProcMem.peak_mb())
	var stats: Dictionary = BenchStats.compute(_dts_ms)
	var ver_info := Engine.get_version_info()
	var godot_ver := str(ver_info.get("string", "4.7.2"))
	var r_method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "gl_compatibility"))
	var gpu_name := RenderingServer.get_video_adapter_name()
	var renderer_str := "Godot %s / %s" % [godot_ver, r_method]
	if not gpu_name.is_empty():
		renderer_str += " / " + gpu_name
	var os_str := "%s (%s)" % [OS.get_name(), OS.get_version()]

	var out := {
		"contract_version": _cfg.contract_version,
		"avg_fps": stats["avg_fps"],
		"p1_low_fps": stats["p1_low_fps"],
		"frame_ms_p95": stats["frame_ms_p95"],
		"frames": stats["frames"],
		"load_ms": _load_ms,
		"peak_mem_mb": null if _peak_mem_mb < 0.0 else int(round(_peak_mem_mb)),
		"vsync_off": _vsync_off,
		"renderer": renderer_str,
		"os": os_str,
	}
	var f := FileAccess.open(_out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out, "  ") + "\n")
		f.close()
	print("bench: frames=%d avg_fps=%.1f p1_low_fps=%.1f p95_ms=%.1f load_ms=%d peak_mem_mb=%s vsync_off=%s" % [
		out["frames"], out["avg_fps"], out["p1_low_fps"], out["frame_ms_p95"],
		out["load_ms"], str(out["peak_mem_mb"]), str(out["vsync_off"])
	])
	quit(0)
