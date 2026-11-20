# GameScene.gd — 3D presentation, Campaign flow, HUD, Leaderboard & Accessibility UI (Phase 3–4).
# Passive view over GameSim: all gameplay rules live in GameSim. No global randf()/randi().
extends Node3D

const GameSettings := preload("res://src/core/GameSettings.gd")
const CampaignController := preload("res://src/core/CampaignController.gd")
const Leaderboard := preload("res://src/core/Leaderboard.gd")

const TICK_RATE := 60.0

var _cfg: Config
var _sim: GameSim
var _input_state: InputState
var _settings
var _campaign
var _accumulator: float = 0.0
var _cam_yaw: float = 0.0
var _base_seed: int = 42
var _in_menu: bool = false
var _awaiting_rebind_action: String = ""
var _shake_ticks: int = 0
var _flash_alpha: float = 0.0

# Notification banner state
var _banner_text: String = ""
var _banner_ticks: int = 0

@onready var _player_node: Node3D = $Player3D
@onready var _camera: Camera3D = $Camera3D
@onready var _mote_parent: Node3D = $Motes
@onready var _shade_parent: Node3D = $Shades
@onready var _lantern_parent: Node3D = $Lanterns
@onready var _hud: CanvasLayer = $HUD

var _island_root: Node3D
var _drifter_parent: Node3D
var _charm_parent: Node3D

var _mote_nodes: Dictionary = {}
var _shade_nodes: Dictionary = {}
var _lantern_nodes: Dictionary = {}
var _drifter_nodes: Dictionary = {}
var _charm_nodes: Dictionary = {}

# UI controls built dynamically on $HUD
var _hud_label: Label
var _warning_label: Label
var _banner_label: Label
var _wind_label: Label
var _edge_arrows_root: Control
var _edge_arrows: Array[Label] = []
var _flash_rect: ColorRect

var _menu_panel: PanelContainer
var _settings_panel: PanelContainer
var _leaderboard_panel: PanelContainer
var _gameover_panel: PanelContainer
var _next_night_panel: PanelContainer

var _rebind_buttons: Dictionary = {}
var _rebind_status_label: Label
var _cb_check: CheckBox
var _rm_check: CheckBox
var _lf_check: CheckBox
var _lb_list_label: RichTextLabel
var _gameover_title: Label
var _gameover_summary: Label
var _name_input: LineEdit
var _name_error: Label
var _save_score_btn: Button
var _score_saved: bool = false

func _ready() -> void:
	if _cfg != null:
		return
	if _player_node == null:
		_player_node = get_node_or_null("Player3D")
		_camera = get_node_or_null("Camera3D")
		_mote_parent = get_node_or_null("Motes")
		_shade_parent = get_node_or_null("Shades")
		_lantern_parent = get_node_or_null("Lanterns")
		_hud = get_node_or_null("HUD")
	# Check CLI --export-leaderboard first (TICKET-04 §3.3)
	if _handle_cli_export():
		return

	_cfg = Config.load_from_file("res://game.contract.json")
	_settings = GameSettings.load_from()
	_base_seed = int(Time.get_ticks_usec() % 100000) + 1
	_campaign = CampaignController.new(_base_seed)
	_sim = GameSim.new()
	_input_state = InputState.new()

	_island_root = Node3D.new()
	_island_root.name = "IslandGeometry"
	add_child(_island_root)

	_drifter_parent = Node3D.new()
	_drifter_parent.name = "Drifters"
	add_child(_drifter_parent)

	_charm_parent = Node3D.new()
	_charm_parent.name = "Charms"
	add_child(_charm_parent)

	_setup_environment()
	_build_ui()
	_apply_font_scale()
	_start_night(_campaign.current_night, _campaign.night_seed())

func _handle_cli_export() -> bool:
	var all_args := OS.get_cmdline_args() + OS.get_cmdline_user_args()
	for i in range(all_args.size()):
		if all_args[i] == "--export-leaderboard":
			if i + 1 >= all_args.size():
				printerr("GameScene: --export-leaderboard requires an output path")
				get_tree().quit(1)
				return true
			var out_path := str(all_args[i + 1])
			var ok := Leaderboard.export_to(out_path)
			get_tree().quit(0 if ok else 1)
			return true
	return false

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.05, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.22, 0.32)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.light_color = Color(0.65, 0.75, 0.95)
	sun.light_energy = 0.55
	add_child(sun)

func start_new_campaign(p_seed: int = -1) -> void:
	if p_seed > 0:
		_base_seed = p_seed
	else:
		_base_seed = (_base_seed * 1103515245 + 12345) & 0x7fffffff
		if _base_seed <= 0:
			_base_seed = 42
	_campaign = CampaignController.new(_base_seed)
	_hide_all_panels()
	_in_menu = false
	_start_night(_campaign.current_night, _campaign.night_seed())

func _start_night(night_num: int, night_seed: int) -> void:
	_clear_world_nodes()
	_sim = GameSim.new()
	_sim.init(_cfg, night_seed, night_num, {})
	_input_state = InputState.new()
	_score_saved = false
	_banner_text = "Đêm %d bắt đầu!" % night_num
	_banner_ticks = 120
	_build_visuals()
	_sync_visuals()
	_update_hud()

func _clear_world_nodes() -> void:
	for c in _lantern_parent.get_children():
		c.queue_free()
	for c in _shade_parent.get_children():
		c.queue_free()
	for c in _mote_parent.get_children():
		c.queue_free()
	for c in _drifter_parent.get_children():
		c.queue_free()
	for c in _charm_parent.get_children():
		c.queue_free()
	for c in _island_root.get_children():
		c.queue_free()
	_lantern_nodes.clear()
	_shade_nodes.clear()
	_mote_nodes.clear()
	_drifter_nodes.clear()
	_charm_nodes.clear()

func _process(delta: float) -> void:
	if _sim == null:
		return
	if not _in_menu:
		_accumulator += delta
		var step := 1.0 / TICK_RATE
		while _accumulator >= step:
			_accumulator -= step
			_read_input()
			if _sim.state == "won" or _sim.state == "lost":
				break
			var prev_state := _sim.state
			var bus := _sim.tick(_input_state)
			_handle_sim_events(bus.drain())
			if _banner_ticks > 0:
				_banner_ticks -= 1
			if _shake_ticks > 0:
				_shake_ticks -= 1
			if (_sim.state == "won" or _sim.state == "lost") and prev_state != _sim.state:
				_on_night_finished()
				break
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - delta * 2.5)
	_sync_visuals()
	_update_hud()

func _handle_sim_events(evs: Array) -> void:
	for ev: Dictionary in evs:
		var ename: String = str(ev.get("name", ""))
		match ename:
			"shade_spawned":
				_banner_text = "⚠ Bóng Mực xuất hiện!"
				_banner_ticks = 120
			"player_hit":
				_banner_text = "⚠ Mây bị thương! (-1 Ngọn Lửa)"
				_banner_ticks = 120
				if not _settings.reduce_motion:
					_shake_ticks = 18
					_flash_alpha = 0.45
			"pulse":
				if not _settings.reduce_motion:
					_flash_alpha = 0.25
			"lantern_out":
				var lid := str(ev.get("data", {}).get("lantern_id", ""))
				_banner_text = "⚠ Đèn %s đã cạn dầu!" % lid
				_banner_ticks = 150
			"lantern_lit":
				var lid2 := str(ev.get("data", {}).get("lantern_id", ""))
				var is_rel := bool(ev.get("data", {}).get("relight", false))
				_banner_text = "Đã thắp lại đèn %s!" % lid2 if is_rel else "Đã thắp sáng đèn %s!" % lid2
				_banner_ticks = 120

func _on_night_finished() -> void:
	var outcome: String = _campaign.report_night(_sim.state, _sim.score)
	if outcome == "next_night":
		_next_night_panel.visible = true
		var lbl: Label = _next_night_panel.find_child("NextNightSummary", true, false)
		if lbl:
			lbl.text = "Qua Đêm %d!\nĐiểm đêm này: %d\nTổng điểm chiến dịch: %d\nChuẩn bị sang Đêm %d..." % [
				_sim.night, _sim.score, _campaign.campaign_score, _campaign.current_night
			]
	else:
		_show_gameover_panel(outcome == "victory")

func _read_input() -> void:
	_input_state.advance_prev()
	if not _awaiting_rebind_action.is_empty():
		return
	var move := Vector2.ZERO
	if _is_action_key_pressed("move_up") or Input.is_key_pressed(KEY_UP):
		move.y += 1.0
	if _is_action_key_pressed("move_down") or Input.is_key_pressed(KEY_DOWN):
		move.y -= 1.0
	if _is_action_key_pressed("move_left") or Input.is_key_pressed(KEY_LEFT):
		move.x -= 1.0
	if _is_action_key_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT):
		move.x += 1.0
	_input_state.move = move
	_input_state.cam_yaw_deg = _cam_yaw
	_input_state.jump = _is_action_key_pressed("jump")
	_input_state.interact = _is_action_key_pressed("interact")
	_input_state.pulse = _is_action_key_pressed("pulse")
	_input_state.dash = _is_action_key_pressed("dash")
	_input_state.pause = _is_action_key_pressed("pause")

func _is_action_key_pressed(action: String) -> bool:
	var code: int = _settings.key_of(action)
	if code <= 0:
		return false
	return Input.is_key_pressed(code as Key) or Input.is_physical_key_pressed(code as Key)

func _unhandled_input(event: InputEvent) -> void:
	if not _awaiting_rebind_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			var kc: int = event.keycode if event.keycode != 0 else event.physical_keycode
			var conflict: String = _settings.rebind(_awaiting_rebind_action, kc)
			if conflict == "":
				_settings.save_to()
				_rebind_status_label.text = "Đã gán '%s' -> %s" % [
					GameSettings.ACTION_LABELS.get(_awaiting_rebind_action, _awaiting_rebind_action),
					OS.get_keycode_string(kc as Key)
				]
				_awaiting_rebind_action = ""
				_refresh_rebind_labels()
			elif conflict == "invalid":
				_rebind_status_label.text = "⚠ Phím không hợp lệ, hãy thử lại."
				_awaiting_rebind_action = ""
			else:
				var clash_name: String = GameSettings.ACTION_LABELS.get(conflict, conflict)
				_rebind_status_label.text = "⚠ Trùng phím với '%s'! Hãy chọn phím khác." % clash_name
				_awaiting_rebind_action = ""
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not _in_menu:
		_cam_yaw -= event.relative.x * 0.25

# ── 3D Visuals (Lanterns, Shades, Motes, Islands, Colorblind support) ──────
func _build_visuals() -> void:
	# Island ground meshes per Night
	if _sim.night == 1:
		_add_ground_disc(Vector3(0, -0.25, 0), 40.0, 0.5, Color(0.15, 0.25, 0.35))
	elif _sim.night == 2:
		_add_ground_disc(Vector3(0, -0.25, 0), 28.0, 0.5, Color(0.15, 0.25, 0.35))
		_add_ground_disc(Vector3(70, -0.25, 0), 28.0, 0.5, Color(0.16, 0.27, 0.34))
		var bridge := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(18.0, 0.3, 4.0)
		bridge.mesh = bm
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.45, 0.34, 0.20)
		bridge.material_override = bmat
		bridge.position = Vector3(35.0, -0.15, 0.0)
		_island_root.add_child(bridge)
	else:
		_add_ground_disc(Vector3(0, -0.25, 0), 45.0, 0.5, Color(0.14, 0.23, 0.33))
		_add_ground_disc(Vector3(0, 1.5, 0), 24.0, 3.0, Color(0.18, 0.27, 0.37))
		_add_ground_disc(Vector3(0, 4.5, 0), 8.0, 3.0, Color(0.22, 0.31, 0.40))

	for ld: Entities.LanternData in _sim.lanterns:
		var root := Node3D.new()
		root.position = ld.pos

		var post := MeshInstance3D.new()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#5B5F6E")
		var cyl := CylinderMesh.new()
		cyl.height = 3.0
		cyl.top_radius = 0.35
		cyl.bottom_radius = 0.4
		post.mesh = cyl
		post.material_override = mat
		post.position = Vector3(0, 1.5, 0)
		root.add_child(post)

		# Torn paper strips on unlit lantern (TICKET-03 §9: structural cue, not color-only)
		var tear := MeshInstance3D.new()
		var tmesh := BoxMesh.new()
		tmesh.size = Vector3(0.82, 0.18, 0.82)
		tear.mesh = tmesh
		var tmat := StandardMaterial3D.new()
		tmat.albedo_color = Color(0.08, 0.08, 0.1)
		tear.material_override = tmat
		tear.position = Vector3(0, 1.6, 0)
		tear.rotation_degrees = Vector3(12, 25, -18)
		root.add_child(tear)

		# 3D Fuel bar above lantern (TICKET-03 §9)
		var bar_bg := MeshInstance3D.new()
		var bg_mesh := BoxMesh.new()
		bg_mesh.size = Vector3(1.6, 0.18, 0.08)
		bar_bg.mesh = bg_mesh
		var bg_mat := StandardMaterial3D.new()
		bg_mat.albedo_color = Color(0.12, 0.12, 0.15)
		bar_bg.material_override = bg_mat
		bar_bg.position = Vector3(0, 3.6, 0)
		root.add_child(bar_bg)

		var bar_fill := MeshInstance3D.new()
		var fill_mesh := BoxMesh.new()
		fill_mesh.size = Vector3(1.56, 0.14, 0.10)
		bar_fill.mesh = fill_mesh
		var fill_mat := StandardMaterial3D.new()
		fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fill_mat.albedo_color = Color("#FFB347")
		bar_fill.material_override = fill_mat
		bar_fill.position = Vector3(0, 3.6, 0)
		root.add_child(bar_fill)

		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 3.0, 0)
		lamp.light_color = Color("#FFB347")
		lamp.light_energy = 0.0
		lamp.omni_range = 10.0
		root.add_child(lamp)

		_lantern_parent.add_child(root)
		_lantern_nodes[ld.id] = {
			"root": root,
			"post": post,
			"mat": mat,
			"tear": tear,
			"bar_bg": bar_bg,
			"bar_fill": bar_fill,
			"fill_mat": fill_mat,
			"lamp": lamp,
		}

func _add_ground_disc(pos: Vector3, radius: float, height: float, col: Color) -> void:
	var ground := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = radius
	gm.bottom_radius = radius
	gm.height = height
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = col
	ground.material_override = gmat
	ground.position = pos
	_island_root.add_child(ground)

func _sync_visuals() -> void:
	if _sim == null:
		return
	_player_node.position = _sim.player.pos
	var cam_offset := Vector3(sin(deg_to_rad(_cam_yaw)) * 6.0, 4.0, cos(deg_to_rad(_cam_yaw)) * 6.0)
	var shake_ofs := Vector3.ZERO
	if _shake_ticks > 0 and not _settings.reduce_motion:
		var s := float(_shake_ticks) * 0.015
		shake_ofs = Vector3(sin(float(_sim.executed_ticks) * 1.7) * s, cos(float(_sim.executed_ticks) * 2.3) * s, 0.0)
	var cam_pos := _sim.player.pos + cam_offset + shake_ofs
	if _camera.is_inside_tree():
		_camera.look_at_from_position(cam_pos, _sim.player.pos + Vector3(0, 1, 0), Vector3.UP)
	else:
		_camera.position = cam_pos

	var cb: bool = bool(_settings.colorblind)
	var shade_accent := Color("#00B3FF") if cb else Color("#7A3CFF")
	var low_blink_on := (int(Time.get_ticks_msec() / 500) % 2) == 0  # 1 Hz blink (500ms on, 500ms off)

	# Lanterns: fuel bar, 20% deflate + torn paper when unlit, 1 Hz blink when fuel < 30
	for ld: Entities.LanternData in _sim.lanterns:
		if not _lantern_nodes.has(ld.id):
			continue
		var info: Dictionary = _lantern_nodes[ld.id]
		var post: MeshInstance3D = info["post"]
		var mat: StandardMaterial3D = info["mat"]
		var tear: MeshInstance3D = info["tear"]
		var bar_bg: MeshInstance3D = info["bar_bg"]
		var bar_fill: MeshInstance3D = info["bar_fill"]
		var fill_mat: StandardMaterial3D = info["fill_mat"]
		var lamp: OmniLight3D = info["lamp"]

		var fuel_val := float(ld.fuel_units) / 60.0
		var ratio := clampf(fuel_val / float(maxi(1, _cfg.fuel_max)), 0.0, 1.0)
		var is_low := ld.lit and fuel_val < float(_cfg.low_fuel_threshold)

		if ld.lit:
			# Lit lantern: full height, fuel bar visible, 1 Hz blink when fuel < 30
			post.scale = Vector3(1.0, 1.0, 1.0)
			tear.visible = false
			bar_bg.visible = true
			bar_fill.visible = true
			bar_fill.scale = Vector3(maxf(0.02, ratio), 1.0, 1.0)
			bar_fill.position.x = -0.78 * (1.0 - ratio)
			if is_low:
				fill_mat.albedo_color = Color("#FFFFFF") if cb else Color("#FF5A5F")
				var blink_e := 2.2 if low_blink_on else 0.5
				lamp.light_energy = blink_e
				mat.albedo_color = Color("#FFB347") if low_blink_on else Color("#8A5A20")
			else:
				fill_mat.albedo_color = Color("#00B3FF") if cb else Color("#FFB347")
				lamp.light_energy = 1.2 + 1.2 * ratio
				mat.albedo_color = Color("#FFB347")
		else:
			# Unlit lantern: deflated 20% (scale.y = 0.8) and torn paper visible (not color-only)
			post.scale = Vector3(0.88, 0.8, 0.88)
			tear.visible = true
			bar_bg.visible = false
			bar_fill.visible = false
			lamp.light_energy = 0.0
			mat.albedo_color = Color("#5B5F6E")

	# Shades: outline/eyes color switches #7A3CFF -> #00B3FF in colorblind mode
	for sd: Entities.ShadeData in _sim.shades:
		if not _shade_nodes.has(sd.id):
			var sroot := Node3D.new()
			var body := MeshInstance3D.new()
			var bmat := StandardMaterial3D.new()
			bmat.albedo_color = Color(0.07, 0.04, 0.1)
			bmat.emission_enabled = true
			bmat.emission = shade_accent
			bmat.emission_energy_multiplier = 0.75
			var spher := SphereMesh.new()
			spher.radius = 0.6
			body.mesh = spher
			body.material_override = bmat
			sroot.add_child(body)

			# Eyes mesh so colorblind switch is unmistakably visible on eyes + rim
			var eyes := MeshInstance3D.new()
			var emat := StandardMaterial3D.new()
			emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			emat.albedo_color = shade_accent
			var emesh := BoxMesh.new()
			emesh.size = Vector3(0.45, 0.14, 0.14)
			eyes.mesh = emesh
			eyes.material_override = emat
			eyes.position = Vector3(0, 0.15, 0.52)
			sroot.add_child(eyes)

			_shade_parent.add_child(sroot)
			_shade_nodes[sd.id] = {"root": sroot, "bmat": bmat, "emat": emat}
		var sinfo: Dictionary = _shade_nodes[sd.id]
		var snode: Node3D = sinfo["root"]
		var sbmat: StandardMaterial3D = sinfo["bmat"]
		var semat: StandardMaterial3D = sinfo["emat"]
		sbmat.emission = shade_accent
		semat.albedo_color = shade_accent
		snode.position = sd.pos + Vector3(0, 0.6, 0)
		snode.visible = sd.state != Entities.SHADE_STUNNED or (Time.get_ticks_msec() / 150) % 2 == 0

	# Motes
	for md: Entities.MoteData in _sim.motes:
		if md.active and not _mote_nodes.has(md.id):
			var m := MeshInstance3D.new()
			var mmat := StandardMaterial3D.new()
			mmat.albedo_color = Color(1.0, 0.85, 0.4)
			mmat.emission_enabled = true
			mmat.emission = Color(1.0, 0.9, 0.5)
			mmat.emission_energy_multiplier = 1.2
			var mspher := SphereMesh.new()
			mspher.radius = 0.15
			m.mesh = mspher
			m.material_override = mmat
			_mote_parent.add_child(m)
			_mote_nodes[md.id] = m
		if _mote_nodes.has(md.id):
			var mn: MeshInstance3D = _mote_nodes[md.id]
			mn.position = md.pos + Vector3(0, 0.5, 0)
			mn.visible = md.active

	# Drifters
	for dr: Entities.DrifterData in _sim.drifters:
		if dr.state != Entities.DRIFTER_REMOVED and not _drifter_nodes.has(dr.id):
			var dm := MeshInstance3D.new()
			var dmat := StandardMaterial3D.new()
			dmat.albedo_color = Color(0.55, 0.85, 0.95)
			var dmesh := CylinderMesh.new()
			dmesh.top_radius = 0.25
			dmesh.bottom_radius = 0.5
			dmesh.height = 1.1
			dm.mesh = dmesh
			dm.material_override = dmat
			_drifter_parent.add_child(dm)
			_drifter_nodes[dr.id] = dm
		if _drifter_nodes.has(dr.id):
			var dn: MeshInstance3D = _drifter_nodes[dr.id]
			dn.position = dr.pos + Vector3(0, 0.6, 0)
			dn.visible = dr.state != Entities.DRIFTER_REMOVED

	# Charms
	for ch: Entities.CharmData in _sim.charms:
		if not _charm_nodes.has(ch.id):
			var cm := MeshInstance3D.new()
			var cmat := StandardMaterial3D.new()
			cmat.albedo_color = Color(0.3, 1.0, 0.75)
			var cmesh := BoxMesh.new()
			cmesh.size = Vector3(0.45, 0.45, 0.45)
			cm.mesh = cmesh
			cm.material_override = cmat
			_charm_parent.add_child(cm)
			_charm_nodes[ch.id] = cm
		if _charm_nodes.has(ch.id):
			var cn: MeshInstance3D = _charm_nodes[ch.id]
			cn.position = ch.pos + Vector3(0, 0.5, 0)
			cn.visible = ch.available

# ── HUD, Subtitles, Off-screen Shade Arrows & Menus (TICKET-03 §9, TICKET-04 §3.3–3.4) ─
func _build_ui() -> void:
	if _hud.get_child_count() > 0:
		_hud_label = _hud.get_child(0) as Label
	else:
		_hud_label = Label.new()
		_hud.add_child(_hud_label)
	_hud_label.position = Vector2(16, 12)
	_hud_label.size = Vector2(980, 36)

	_warning_label = Label.new()
	_warning_label.name = "WarningLabel"
	_warning_label.position = Vector2(16, 50)
	_warning_label.size = Vector2(980, 36)
	_hud.add_child(_warning_label)

	_wind_label = Label.new()
	_wind_label.name = "WindLabel"
	_wind_label.position = Vector2(16, 86)
	_wind_label.size = Vector2(980, 34)
	_hud.add_child(_wind_label)

	_banner_label = Label.new()
	_banner_label.name = "BannerLabel"
	_banner_label.position = Vector2(16, 122)
	_banner_label.size = Vector2(980, 34)
	_hud.add_child(_banner_label)

	# Off-screen Shade directional edge arrows container
	_edge_arrows_root = Control.new()
	_edge_arrows_root.name = "EdgeArrows"
	_edge_arrows_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge_arrows_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_edge_arrows_root)
	for i in range(12):
		var arr := Label.new()
		arr.visible = false
		arr.text = "⚠▲"
		_edge_arrows_root.add_child(arr)
		_edge_arrows.append(arr)

	# Screen flash overlay (disabled when reduce_motion is enabled)
	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 0.9, 0.7, 0.0)
	_hud.add_child(_flash_rect)

	# Top-right quick buttons for Menu / Leaderboard / Settings
	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.position = Vector2(860, 12)
	top_bar.add_theme_constant_override("separation", 8)
	_hud.add_child(top_bar)

	var btn_menu := Button.new()
	btn_menu.name = "BtnMenu"
	btn_menu.text = "Menu"
	btn_menu.pressed.connect(func() -> void: _toggle_main_menu())
	top_bar.add_child(btn_menu)

	var btn_lb := Button.new()
	btn_lb.name = "BtnLeaderboard"
	btn_lb.text = "Bảng xếp hạng"
	btn_lb.pressed.connect(func() -> void: _show_leaderboard_panel())
	top_bar.add_child(btn_lb)

	var btn_set := Button.new()
	btn_set.name = "BtnSettings"
	btn_set.text = "Cài đặt"
	btn_set.pressed.connect(func() -> void: _show_settings_panel())
	top_bar.add_child(btn_set)

	_build_menu_panel()
	_build_settings_panel()
	_build_leaderboard_panel()
	_build_next_night_panel()
	_build_gameover_panel()

func _build_menu_panel() -> void:
	_menu_panel = PanelContainer.new()
	_menu_panel.name = "MainMenuPanel"
	_menu_panel.position = Vector2(390, 150)
	_menu_panel.custom_minimum_size = Vector2(500, 380)
	_menu_panel.visible = false
	_hud.add_child(_menu_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_menu_panel.add_child(vb)

	var title := Label.new()
	title.text = "ĐẢO ĐÈN LỒNG — v1.0.0"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	var b_play := Button.new()
	b_play.name = "MenuPlayBtn"
	b_play.text = "Chơi chiến dịch mới (Đêm 1 → 3)"
	b_play.pressed.connect(func() -> void: start_new_campaign())
	vb.add_child(b_play)

	var b_resume := Button.new()
	b_resume.name = "MenuResumeBtn"
	b_resume.text = "Tiếp tục"
	b_resume.pressed.connect(func() -> void:
		_hide_all_panels()
		_in_menu = false)
	vb.add_child(b_resume)

	var b_lb := Button.new()
	b_lb.name = "MenuLeaderboardBtn"
	b_lb.text = "Bảng xếp hạng (Top 10)"
	b_lb.pressed.connect(func() -> void: _show_leaderboard_panel())
	vb.add_child(b_lb)

	var b_set := Button.new()
	b_set.name = "MenuSettingsBtn"
	b_set.text = "Cài đặt & Trợ năng"
	b_set.pressed.connect(func() -> void: _show_settings_panel())
	vb.add_child(b_set)

	var b_quit := Button.new()
	b_quit.name = "MenuQuitBtn"
	b_quit.text = "Thoát"
	b_quit.pressed.connect(func() -> void: get_tree().quit(0))
	vb.add_child(b_quit)

func _build_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.position = Vector2(240, 60)
	_settings_panel.custom_minimum_size = Vector2(800, 580)
	_settings_panel.visible = false
	_hud.add_child(_settings_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_settings_panel.add_child(vb)

	var title := Label.new()
	title.text = "CÀI ĐẶT & TRỢ NĂNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	_cb_check = CheckBox.new()
	_cb_check.name = "ColorblindToggle"
	_cb_check.text = "Bảng màu dễ phân biệt (Bóng Mực #00B3FF, Cảnh báo #FFFFFF + ⚠)"
	_cb_check.button_pressed = _settings.colorblind
	_cb_check.toggled.connect(func(v: bool) -> void:
		_settings.colorblind = v
		_settings.save_to()
		_sync_visuals()
		_update_hud())
	vb.add_child(_cb_check)

	_rm_check = CheckBox.new()
	_rm_check.name = "ReduceMotionToggle"
	_rm_check.text = "Giảm chuyển động (Tắt rung camera & tắt chớp màn hình)"
	_rm_check.button_pressed = _settings.reduce_motion
	_rm_check.toggled.connect(func(v: bool) -> void:
		_settings.reduce_motion = v
		_settings.save_to())
	vb.add_child(_rm_check)

	_lf_check = CheckBox.new()
	_lf_check.name = "LargeFontToggle"
	_lf_check.text = "Chữ lớn ×1.25 (Tối thiểu 18px ở 1280×720)"
	_lf_check.button_pressed = _settings.large_font
	_lf_check.toggled.connect(func(v: bool) -> void:
		_settings.large_font = v
		_settings.save_to()
		_apply_font_scale())
	vb.add_child(_lf_check)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	vb.add_child(grid)

	for act: String in GameSettings.ACTIONS:
		var lbl := Label.new()
		lbl.text = str(GameSettings.ACTION_LABELS.get(act, act))
		grid.add_child(lbl)

		var btn := Button.new()
		btn.name = "Rebind_" + act
		btn.text = _settings.key_label(act)
		btn.pressed.connect(func() -> void:
			_awaiting_rebind_action = act
			_rebind_status_label.text = "Nhấn phím mới cho '%s'..." % str(GameSettings.ACTION_LABELS.get(act, act)))
		grid.add_child(btn)
		_rebind_buttons[act] = btn

	_rebind_status_label = Label.new()
	_rebind_status_label.name = "RebindStatusLabel"
	_rebind_status_label.text = ""
	vb.add_child(_rebind_status_label)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	vb.add_child(hb)

	var b_reset := Button.new()
	b_reset.name = "ResetBindingsBtn"
	b_reset.text = "Khôi phục mặc định"
	b_reset.pressed.connect(func() -> void:
		_settings.reset_bindings()
		_settings.save_to()
		_rebind_status_label.text = "Đã khôi phục phím mặc định."
		_refresh_rebind_labels())
	hb.add_child(b_reset)

	var b_close := Button.new()
	b_close.name = "CloseSettingsBtn"
	b_close.text = "Đóng"
	b_close.pressed.connect(func() -> void:
		_settings_panel.visible = false
		_in_menu = false)
	hb.add_child(b_close)

func _refresh_rebind_labels() -> void:
	for act: String in GameSettings.ACTIONS:
		if _rebind_buttons.has(act):
			var b: Button = _rebind_buttons[act]
			b.text = _settings.key_label(act)

func _build_leaderboard_panel() -> void:
	_leaderboard_panel = PanelContainer.new()
	_leaderboard_panel.name = "LeaderboardPanel"
	_leaderboard_panel.position = Vector2(260, 90)
	_leaderboard_panel.custom_minimum_size = Vector2(760, 500)
	_leaderboard_panel.visible = false
	_hud.add_child(_leaderboard_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_leaderboard_panel.add_child(vb)

	var title := Label.new()
	title.text = "BẢNG XẾP HẠNG LOCAL (TOP 10)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)

	_lb_list_label = RichTextLabel.new()
	_lb_list_label.name = "LeaderboardList"
	_lb_list_label.custom_minimum_size = Vector2(720, 360)
	_lb_list_label.fit_content = false
	vb.add_child(_lb_list_label)

	var b_close := Button.new()
	b_close.name = "CloseLeaderboardBtn"
	b_close.text = "Đóng"
	b_close.pressed.connect(func() -> void:
		_leaderboard_panel.visible = false
		_in_menu = false)
	vb.add_child(b_close)

func _refresh_leaderboard_view() -> void:
	var entries := Leaderboard.load_entries()
	if entries.is_empty():
		_lb_list_label.text = "Chưa có kỷ lục nào."
		return
	var lines: Array[String] = ["#   TÊN          ĐIỂM    ĐÊM THẮNG   SEED   THỜI GIAN"]
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		lines.append("%2d. %-12s %6d   %d/3         %4d   %s" % [
			i + 1, str(e["name"]), int(e["score"]), int(e["nights_won"]), int(e["seed"]), str(e["achieved_at"])
		])
	_lb_list_label.text = "\n".join(lines)

func _build_next_night_panel() -> void:
	_next_night_panel = PanelContainer.new()
	_next_night_panel.name = "NextNightPanel"
	_next_night_panel.position = Vector2(380, 180)
	_next_night_panel.custom_minimum_size = Vector2(520, 280)
	_next_night_panel.visible = false
	_hud.add_child(_next_night_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_next_night_panel.add_child(vb)

	var sum_lbl := Label.new()
	sum_lbl.name = "NextNightSummary"
	sum_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(sum_lbl)

	var btn := Button.new()
	btn.name = "ContinueNightBtn"
	btn.text = "Tiếp tục sang Đêm tiếp theo"
	btn.pressed.connect(func() -> void:
		_next_night_panel.visible = false
		_start_night(_campaign.current_night, _campaign.night_seed()))
	vb.add_child(btn)

func _build_gameover_panel() -> void:
	_gameover_panel = PanelContainer.new()
	_gameover_panel.name = "GameOverPanel"
	_gameover_panel.position = Vector2(340, 140)
	_gameover_panel.custom_minimum_size = Vector2(600, 380)
	_gameover_panel.visible = false
	_hud.add_child(_gameover_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_gameover_panel.add_child(vb)

	_gameover_title = Label.new()
	_gameover_title.name = "GameOverTitle"
	_gameover_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_gameover_title)

	_gameover_summary = Label.new()
	_gameover_summary.name = "GameOverSummary"
	_gameover_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_gameover_summary)

	_name_input = LineEdit.new()
	_name_input.name = "PlayerNameInput"
	_name_input.placeholder_text = "Nhập tên (3-12 ký tự A-Z, 0-9, _)"
	_name_input.max_length = 12
	vb.add_child(_name_input)

	_name_error = Label.new()
	_name_error.name = "NameErrorLabel"
	_name_error.text = ""
	vb.add_child(_name_error)

	_save_score_btn = Button.new()
	_save_score_btn.name = "SaveScoreBtn"
	_save_score_btn.text = "Lưu điểm vào Bảng xếp hạng"
	_save_score_btn.pressed.connect(func() -> void: _submit_leaderboard_score())
	vb.add_child(_save_score_btn)

	var b_again := Button.new()
	b_again.name = "PlayAgainBtn"
	b_again.text = "Chơi lại từ Đêm 1"
	b_again.pressed.connect(func() -> void: start_new_campaign())
	vb.add_child(b_again)

func _show_gameover_panel(is_victory: bool) -> void:
	_hide_all_panels()
	_gameover_panel.visible = true
	_gameover_title.text = "BÌNH MINH ĐÃ LÊN — CHIẾN THẮNG!" if is_victory else "ĐÊM TỐI BUÔNG XUỐNG — THẤT BẠI"
	_gameover_summary.text = "Số đêm thắng: %d/3  |  Tổng điểm chiến dịch: %d  |  Seed: %d" % [
		_campaign.nights_won, _campaign.campaign_score, _campaign.seed_value
	]
	_name_error.text = ""
	_save_score_btn.disabled = false

func _submit_leaderboard_score() -> void:
	if _score_saved:
		return
	var pname := _name_input.text.strip_edges()
	if not Leaderboard.validate_name(pname):
		_name_error.text = "⚠ Tên phải từ 3–12 ký tự [A-Za-z0-9_]."
		return
	var entry := Leaderboard.make_entry(pname, _campaign.campaign_score, _campaign.nights_won, _campaign.seed_value)
	Leaderboard.add_entry(entry)
	_score_saved = true
	_save_score_btn.disabled = true
	_name_error.text = "Đã lưu điểm thành công!"
	_show_leaderboard_panel()

func _hide_all_panels() -> void:
	_menu_panel.visible = false
	_settings_panel.visible = false
	_leaderboard_panel.visible = false
	_next_night_panel.visible = false
	_gameover_panel.visible = false

func _toggle_main_menu() -> void:
	var show := not _menu_panel.visible
	_hide_all_panels()
	_menu_panel.visible = show
	_in_menu = show
	if show:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _show_settings_panel() -> void:
	_hide_all_panels()
	_settings_panel.visible = true
	_in_menu = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_rebind_labels()

func _show_leaderboard_panel() -> void:
	_hide_all_panels()
	_refresh_leaderboard_view()
	_leaderboard_panel.visible = true
	_in_menu = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_font_scale() -> void:
	var fsize: int = _settings.font_size(18)
	_apply_font_recursive(_hud, fsize)

func _apply_font_recursive(node: Node, fsize: int) -> void:
	if node is Control:
		(node as Control).add_theme_font_size_override("font_size", fsize)
	for child in node.get_children():
		_apply_font_recursive(child, fsize)

func _update_hud() -> void:
	if _sim == null or _hud_label == null:
		return
	var state_str := ""
	if _sim.state == "paused":
		state_str = "  [PAUSED]"
	elif _sim.state == "won":
		state_str = "  [BÌNH MINH]"
	elif _sim.state == "lost":
		state_str = "  [THẤT BẠI]"

	var lit_count := 0
	var low_lanterns: Array[String] = []
	for ld: Entities.LanternData in _sim.lanterns:
		if ld.lit:
			lit_count += 1
			var f := float(ld.fuel_units) / 60.0
			if f < float(_cfg.low_fuel_threshold):
				low_lanterns.append("%s(%.0f)" % [ld.id, f])

	# TICKET-03 §6: HUD displays carried / capacity
	_hud_label.text = "Đêm %d  |  Đom đóm: %d / %d  |  Đèn sáng: %d/%d (cần %d)  |  Lửa: %d  |  Điểm: %d  |  Còn: %.0fs%s" % [
		_sim.night, _sim.player.carried, _sim.player.capacity,
		lit_count, _sim.lanterns.size(), _sim.required_lit(),
		_sim.player.flames, _sim.score, _sim.time_left_s(), state_str
	]

	# Warning color: #FF5A5F normal -> #FFFFFF in colorblind mode, always with ⚠ icon (TICKET-03 §9)
	var warn_col := Color("#FFFFFF") if _settings.colorblind else Color("#FF5A5F")
	_warning_label.modulate = warn_col
	_wind_label.modulate = warn_col

	var warnings: Array[String] = []
	if not low_lanterns.is_empty():
		warnings.append("⚠ Đèn sắp cạn dầu (<30): " + ", ".join(low_lanterns))
	if _sim.time_left_s() <= 10.0 and _sim.time_left_s() > 0.0 and _sim.state == "playing":
		warnings.append("⚠ 10 giây cuối cùng trước Bình minh! (%.1fs)" % _sim.time_left_s())
	_warning_label.text = "   ".join(warnings)

	# Wind indicator (Night 3 warning 2s before active + while active)
	var wind_msg := ""
	if _sim.wind_active:
		wind_msg = "⚠ Gió mạnh đang thổi! Hướng %.0f°" % _sim.wind_dir_deg
	elif _sim._wind_enabled() and _sim._wind_next_warning_tick >= 0 and _sim.sim_tick >= _sim._wind_next_warning_tick and _sim.sim_tick < _sim._wind_next_active_tick:
		wind_msg = "⚠ Gió sắp thổi! Hướng %.0f°" % _sim.wind_dir_deg
	_wind_label.text = wind_msg

	_banner_label.modulate = warn_col if _banner_text.begins_with("⚠") else Color(0.95, 0.95, 1.0)
	_banner_label.text = _banner_text if _banner_ticks > 0 else ""

	if _flash_rect:
		var a := 0.0 if _settings.reduce_motion else _flash_alpha
		_flash_rect.color = Color(1.0, 0.85, 0.65, a)

	_update_edge_arrows(warn_col)

func _update_edge_arrows(warn_col: Color) -> void:
	for arr: Label in _edge_arrows:
		arr.visible = false
	if _sim == null or _camera == null or get_viewport() == null:
		return
	var vp_size := get_viewport().get_visible_rect().size
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		vp_size = Vector2(1280, 720)
	var center := vp_size * 0.5
	var margin := 38.0
	var idx := 0
	for sd: Entities.ShadeData in _sim.shades:
		if idx >= _edge_arrows.size():
			break
		var wpos := sd.pos + Vector3(0, 0.6, 0)
		var behind := _camera.is_position_behind(wpos)
		var sp := _camera.unproject_position(wpos)
		var inside := (not behind) and sp.x >= margin and sp.x <= vp_size.x - margin and sp.y >= margin and sp.y <= vp_size.y - margin
		if inside:
			continue
		var dir := (sp - center)
		if behind:
			dir = -dir
		if dir.length_squared() < 1.0:
			dir = Vector2(1, 0)
		dir = dir.normalized()
		var edge_pos := center + dir * Vector2(center.x - margin, center.y - margin)
		edge_pos.x = clampf(edge_pos.x, margin, vp_size.x - margin)
		edge_pos.y = clampf(edge_pos.y, margin, vp_size.y - margin)
		var arrow_lbl: Label = _edge_arrows[idx]
		arrow_lbl.visible = true
		arrow_lbl.modulate = Color("#00B3FF") if _settings.colorblind else warn_col
		arrow_lbl.position = edge_pos
		arrow_lbl.text = "⚠ Bóng Mực " + _dir_glyph(dir)
		idx += 1

static func _dir_glyph(d: Vector2) -> String:
	if absf(d.x) > absf(d.y):
		return "→" if d.x > 0.0 else "←"
	return "↓" if d.y > 0.0 else "↑"
