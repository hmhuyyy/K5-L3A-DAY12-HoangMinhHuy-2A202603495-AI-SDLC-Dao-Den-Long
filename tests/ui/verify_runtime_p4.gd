# verify_runtime_p4.gd — Windowed 3D runtime verification of Leaderboard & Accessibility (TICKET-04 §5).
# Run WITHOUT --headless so the real 1280x720 window, viewport, camera frustum, 3D meshes and HUD layout are active:
#   godot --path . --script res://tests/ui/verify_runtime_p4.gd
extends SceneTree

const Leaderboard := preload("res://src/core/Leaderboard.gd")
const GameSettings := preload("res://src/core/GameSettings.gd")

var _scene: Node3D
var _frame := 0
var _pass := 0
var _fail := 0

func _ok(cond: bool, msg: String) -> void:
	if cond:
		_pass += 1
		print("RUNTIME_PASS  " + msg)
	else:
		_fail += 1
		print("RUNTIME_FAIL  " + msg)

func _init() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var packed: PackedScene = load("res://src/gameplay/GameScene.tscn")
	_scene = packed.instantiate()
	get_root().add_child(_scene)

func _process(delta: float) -> bool:
	_frame += 1
	if _frame == 3:
		_verify_runtime_features()
	if _frame == 15:
		print("Runtime verification: %d passed, %d failed" % [_pass, _fail])
		quit(0 if _fail == 0 else 1)
		return true
	return false

func _verify_runtime_features() -> void:
	# 1. Verify 1280x720 viewport active in tree
	var vp_rect := _scene.get_viewport().get_visible_rect().size
	_ok(vp_rect.x >= 1200 and vp_rect.y >= 700, "Windowed viewport active (%dx%d)" % [int(vp_rect.x), int(vp_rect.y)])

	# 2. Verify Colorblind mode runtime visual changes on 3D meshes & HUD
	_scene._sim.lanterns[0].lit = true
	_scene._sim.lanterns[0].fuel_units = 1200  # fuel = 20 (<30)
	_scene._sim.lanterns[1].lit = false
	var sd := Entities.ShadeData.new()
	sd.id = "S1"
	sd.pos = Vector3(18.0, 0.0, 18.0)  # behind camera (camera is at z=+6 looking toward z=0) -> off-screen
	sd.state = Entities.SHADE_WANDER
	_scene._sim.shades.append(sd)

	_scene._cb_check.button_pressed = true
	_scene._cb_check.toggled.emit(true)
	var l1: Dictionary = _scene._lantern_nodes["L1"]
	var l2: Dictionary = _scene._lantern_nodes["L2"]
	var s1: Dictionary = _scene._shade_nodes["S1"]
	_ok(_scene._settings.colorblind == true, "Colorblind toggle activates setting and saves to disk")
	_ok((s1["emat"] as StandardMaterial3D).albedo_color.is_equal_approx(Color("#00B3FF")), "Colorblind Shade eyes/rim color is #00B3FF in 3D scene")
	_ok(_scene._warning_label.modulate.is_equal_approx(Color("#FFFFFF")) and _scene._warning_label.text.find("⚠") != -1, "Colorblind warning label uses #FFFFFF and ⚠ glyph")
	_ok((l1["bar_fill"] as MeshInstance3D).visible, "Lit lantern displays 3D fuel bar")
	_ok(is_equal_approx((l2["post"] as MeshInstance3D).scale.y, 0.8) and (l2["tear"] as MeshInstance3D).visible, "Extinguished lantern deflated 20% with torn-paper strip")

	# 3. Verify off-screen Shade directional edge arrow in real Camera3D viewport
	var any_arrow_visible := false
	for arr: Label in _scene._edge_arrows:
		if arr.visible and arr.text.find("⚠ Bóng Mực") != -1:
			any_arrow_visible = true
	_ok(any_arrow_visible, "Off-screen Shade triggers directional edge indicator arrow on HUD")

	# 4. Verify Reduce Motion disables camera shake & screen flash on player_hit
	_scene._rm_check.button_pressed = true
	_scene._rm_check.toggled.emit(true)
	_scene._handle_sim_events([{"name": "player_hit", "data": {"by": "shade", "flames": 2, "dropped": 0}}])
	_scene._update_hud()
	_ok(_scene._shake_ticks == 0 and is_equal_approx(_scene._flash_rect.color.a, 0.0), "Reduce Motion suppresses camera shake and screen flash")
	_ok(_scene._banner_label.text.find("⚠") != -1, "Reduce Motion keeps replacement text/glyph warning banner")

	# 5. Verify Large Font x1.25 (18px -> 23px) and no HUD overflow at 1280x720
	_scene._lf_check.button_pressed = true
	_scene._lf_check.toggled.emit(true)
	var fsize: int = _scene._hud_label.get_theme_font_size("font_size")
	_ok(fsize == 23, "Large Font toggle scales UI font to 23px (round(18 * 1.25))")
	_ok(_scene._hud_label.position.x + _scene._hud_label.size.x <= 1280.0, "HUD label fits within 1280x720 without horizontal overflow")

	# 6. Verify Key Remapping via InputEventKey in runtime, duplicate warning & reset defaults
	_scene._awaiting_rebind_action = "jump"
	var dup_ev := InputEventKey.new()
	dup_ev.pressed = true
	dup_ev.keycode = KEY_W
	_scene._unhandled_input(dup_ev)
	_ok(_scene._settings.key_of("jump") == KEY_SPACE and _scene._rebind_status_label.text.find("⚠ Trùng phím") != -1, "Duplicate key press rejected with warning in UI")

	_scene._awaiting_rebind_action = "jump"
	var ok_ev := InputEventKey.new()
	ok_ev.pressed = true
	ok_ev.keycode = KEY_J
	_scene._unhandled_input(ok_ev)
	_ok(_scene._settings.key_of("jump") == KEY_J and (_scene._rebind_buttons["jump"] as Button).text == "J", "Key remap to J updates action binding and UI button text")

	# Verify persistence across reload
	var reloaded_settings = GameSettings.load_from()
	_ok(reloaded_settings.key_of("jump") == KEY_J and reloaded_settings.colorblind == true, "Settings persist across disk reload")

	# Reset defaults
	_scene._settings.reset_bindings()
	_scene._settings.colorblind = false
	_scene._settings.reduce_motion = false
	_scene._settings.large_font = false
	_scene._settings.save_to()
	_ok(_scene._settings.key_of("jump") == KEY_SPACE, "Reset default bindings restores KEY_SPACE")

	# 7. Verify Leaderboard runtime UI submission + restart persistence
	_scene._campaign.campaign_score = 945
	_scene._campaign.nights_won = 3
	_scene._show_gameover_panel(true)
	_scene._name_input.text = "bad"
	_scene._name_input.text = "A!"
	_scene._submit_leaderboard_score()
	_ok(not _scene._score_saved and _scene._name_error.text.find("⚠") != -1, "Invalid player name rejected in GameOver UI")

	_scene._name_input.text = "MAY_HERO"
	_scene._submit_leaderboard_score()
	_ok(_scene._score_saved and _scene._leaderboard_panel.visible, "Valid name saves campaign score and opens Leaderboard panel")
	var lb_entries: Array = Leaderboard.load_entries()
	var found_hero := false
	for e: Dictionary in lb_entries:
		if str(e.get("name", "")) == "MAY_HERO" and int(e.get("score", 0)) == 945:
			found_hero = true
	_ok(found_hero, "Leaderboard entry persisted on disk and reloaded")
