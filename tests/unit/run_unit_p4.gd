# run_unit_p4.gd — Phase 3 Colorblind/3D UI & Phase 4 (Leaderboard, Accessibility, Bench, Soak) tests.
# Run: godot --headless --path . --script res://tests/unit/run_unit_p4.gd
extends SceneTree

const Leaderboard := preload("res://src/core/Leaderboard.gd")
const CampaignController := preload("res://src/core/CampaignController.gd")
const GameSettings := preload("res://src/core/GameSettings.gd")
const BenchStats := preload("res://src/core/BenchStats.gd")
const SoakRunner := preload("res://src/tools/SoakRunner.gd")

var passed := 0
var failed := 0

func _init() -> void:
	t_leaderboard_validation_and_ranking()
	t_leaderboard_persistence_and_corrupt()
	t_campaign_score_accumulation()
	t_settings_remapping_and_font()
	t_bench_workload_and_stats()
	t_soak_determinism()
	t_gamescene_3d_colorblind_and_hud()
	print("Unit-P4 results: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

func ok(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("PASS  " + label)
	else:
		failed += 1
		print("FAIL  " + label)

func t_leaderboard_validation_and_ranking() -> void:
	# Name validation: 3-12 chars [A-Za-z0-9_]
	ok(Leaderboard.validate_name("ABC"), "LB valid 3-char name")
	ok(Leaderboard.validate_name("PLAYER_01_OK"), "LB valid 12-char name")
	ok(not Leaderboard.validate_name("AB"), "LB rejects <3 chars")
	ok(not Leaderboard.validate_name("ABCDEFGHIJKLM"), "LB rejects >12 chars")
	ok(not Leaderboard.validate_name("BAD NAME"), "LB rejects space")
	ok(not Leaderboard.validate_name("BAD-NAME"), "LB rejects hyphen")
	ok(not Leaderboard.validate_name(123), "LB rejects non-string")

	# Tie-break by earlier timestamp + top 10 truncation
	var entries: Array = []
	for i in range(12):
		var e := Leaderboard.make_entry(
			"PLY_%02d" % i,
			100 * i,
			2,
			42,
			"2026-11-20T10:%02d:00+07:00" % i
		)
		entries.append(e)
	# Add tie score with earlier and later timestamp
	entries.append(Leaderboard.make_entry("TIE_LATE", 1100, 3, 42, "2026-11-20T12:00:00+07:00"))
	entries.append(Leaderboard.make_entry("TIE_EARLY", 1100, 3, 42, "2026-11-20T08:00:00+07:00"))

	var ranked := Leaderboard.ranked(entries)
	ok(ranked.size() == 10, "LB keeps top 10 only")
	ok(ranked[0]["name"] == "TIE_EARLY", "LB tie-break: earlier timestamp ranks first")
	ok(ranked[1]["name"] == "PLY_11", "LB tie-break: second 1100 score is 10:11")
	ok(ranked[2]["name"] == "TIE_LATE", "LB tie-break: latest 1100 score ranks third")
	ok(int(ranked[0]["score"]) >= int(ranked[9]["score"]), "LB sorted descending by score")

func t_leaderboard_persistence_and_corrupt() -> void:
	var tmp_path := "user://test_lb.json"
	var exp_path := "user://test_lb_export.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(exp_path))

	# Save and load
	var e1 := Leaderboard.make_entry("MAY_01", 850, 2, 7, "2026-11-20T20:00:00+07:00")
	var e2 := Leaderboard.make_entry("MAY_02", 1240, 3, 7, "2026-11-20T20:05:00+07:00")
	Leaderboard.add_entry(e1, tmp_path)
	Leaderboard.add_entry(e2, tmp_path)
	var loaded := Leaderboard.load_entries(tmp_path)
	ok(loaded.size() == 2 and loaded[0]["name"] == "MAY_02" and loaded[1]["name"] == "MAY_01", "LB save/load preserves ranking")

	# Export format {"entries": [...]}
	ok(Leaderboard.export_to(exp_path, tmp_path), "LB export_to succeeds")
	var f := FileAccess.open(exp_path, FileAccess.READ)
	var j := JSON.new()
	ok(f != null and j.parse(f.get_as_text()) == OK and (j.get_data() is Dictionary) and j.get_data().has("entries"), "LB export format {\"entries\": []}")
	if f != null:
		f.close()

	# Corrupt file must not crash and must return []
	var cf := FileAccess.open(tmp_path, FileAccess.WRITE)
	cf.store_string("{corrupt_json_here!!!")
	cf.close()
	var after_corrupt := Leaderboard.load_entries(tmp_path)
	ok(after_corrupt is Array and after_corrupt.is_empty(), "LB corrupt JSON handled safely without crash")

	# Partially invalid entries filtered out
	var pf := FileAccess.open(tmp_path, FileAccess.WRITE)
	pf.store_string(JSON.stringify({"entries": [
		{"name": "BAD", "score": -10, "nights_won": 1, "achieved_at": "2026-11-20T20:00:00+07:00", "seed": 1},
		{"name": "GOOD_ONE", "score": 500, "nights_won": 1, "achieved_at": "2026-11-20T20:00:00+07:00", "seed": 1},
	]}))
	pf.close()
	var filtered := Leaderboard.load_entries(tmp_path)
	ok(filtered.size() == 1 and filtered[0]["name"] == "GOOD_ONE", "LB filters invalid entries on load")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(exp_path))

func t_campaign_score_accumulation() -> void:
	var c := CampaignController.new(42)
	ok(c.current_night == 1 and c.night_seed() == 42, "CAMP starts at Night 1")
	ok(c.report_night("won", 450) == "next_night", "CAMP Night 1 win advances to Night 2")
	ok(c.current_night == 2 and c.campaign_score == 450 and c.nights_won == 1, "CAMP score after Night 1")
	ok(c.report_night("lost", 999) == "defeat", "CAMP Night 2 loss ends campaign")
	ok(c.campaign_score == 450 and c.nights_won == 1 and not c.victory, "CAMP lost night score is NOT added to campaign_score")

	var c2 := CampaignController.new(10)
	c2.report_night("won", 300)
	c2.report_night("won", 400)
	var fin := c2.report_night("won", 500)
	ok(fin == "victory" and c2.victory and c2.nights_won == 3 and c2.campaign_score == 1200, "CAMP 3 wins -> victory, total score = sum of 3 nights")

func t_settings_remapping_and_font() -> void:
	var tmp := "user://test_settings.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

	var s := GameSettings.new()
	ok(s.font_size(18) == 18 and s.font_size(14) == 18, "SET font minimum 18px at 1280x720")
	s.large_font = true
	ok(s.font_size(18) == 23, "SET large font x1.25 (round(18*1.25)=23)")

	# All 9 required actions present
	ok(GameSettings.ACTIONS.size() == 9, "SET all 9 actions configured")

	# Duplicate key detection
	var conflict := s.rebind("jump", KEY_W)
	ok(conflict == "move_up" and s.key_of("jump") == KEY_SPACE, "SET duplicate key rejected and names conflicting action")

	# Valid rebind + persistence + reset default
	ok(s.rebind("jump", KEY_J) == "" and s.key_of("jump") == KEY_J, "SET valid key rebind succeeds")
	s.colorblind = true
	s.reduce_motion = true
	ok(s.save_to(tmp), "SET save_to disk")

	var s2 := GameSettings.load_from(tmp)
	ok(s2.colorblind and s2.reduce_motion and s2. large_font and s2.key_of("jump") == KEY_J, "SET load_from restores toggles and bindings")
	s2.reset_bindings()
	ok(s2.key_of("jump") == KEY_SPACE, "SET reset_bindings restores defaults")

	# Corrupt settings file falls back to defaults
	var cf := FileAccess.open(tmp, FileAccess.WRITE)
	cf.store_string("not-json")
	cf.close()
	var s3 := GameSettings.load_from(tmp)
	ok(s3.key_of("move_up") == KEY_W and not s3.load_warning.is_empty(), "SET corrupt settings handled safely")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))

func t_bench_workload_and_stats() -> void:
	var cfg := Config.load_from_file("res://game.contract.json")
	var sim := GameSim.new()
	sim.init_bench(cfg, 42)
	ok(sim.bench_mode and sim.night == 1, "BENCH Night 1 bench_mode active")
	ok(sim.shades.size() == 200, "BENCH exactly 200 Shades")
	ok(sim.motes.size() == 100, "BENCH exactly 100 motes")
	var lit_ids: Array[String] = []
	for ld: Entities.LanternData in sim.lanterns:
		if ld.lit:
			lit_ids.append(ld.id)
			ok(ld.fuel_units == 6000, "BENCH lit lantern %s has fuel=100" % ld.id)
	ok(lit_ids == ["L1", "L2", "L3"], "BENCH L1-L3 lit")
	ok(sim.player.pos == Vector3.ZERO, "BENCH player at (0,0,0)")

	# Advance 120 ticks: shades wander, but no fuel decay, no spawn, no damage, no terminal
	var s0_pos := sim.shades[0].pos
	for _i in range(120):
		sim.tick(null)
	ok(sim.lanterns[0].fuel_units == 6000, "BENCH fuel decay disabled")
	ok(sim.shades.size() == 200 and sim.motes.size() == 100, "BENCH spawn and pickup disabled")
	ok(sim.player.flames == 3 and sim.state == "playing", "BENCH damage and terminal disabled")
	ok(sim.shades[0].pos != s0_pos, "BENCH Shades move in wander state")

	# BenchStats math check: 100 frames of 10ms (100 FPS), except 1 worst frame of 20ms (50 FPS)
	var dts: Array = []
	for i in range(99):
		dts.append(10.0)
	dts.append(20.0)
	var st := BenchStats.compute(dts)
	ok(st["frames"] == 100 and st["p1_low_fps"] == 50.0 and st["frame_ms_p95"] == 10.0, "BENCH stats formula N, p1_low_fps, frame_ms_p95")

func t_soak_determinism() -> void:
	var cfg := Config.load_from_file("res://game.contract.json")
	var r1 := SoakRunner.play_night(cfg, 1, 7)
	var r2 := SoakRunner.play_night(cfg, 1, 7)
	ok(not r1["crashed"] and r1["ticks"] == r2["ticks"] and r1["result"] == r2["result"] and r1["score"] == r2["score"],
		"SOAK single night deterministic and crash-free")

func t_gamescene_3d_colorblind_and_hud() -> void:
	var packed: PackedScene = load("res://src/gameplay/GameScene.tscn")
	ok(packed != null, "UI GameScene.tscn loads")
	var scene: Node3D = packed.instantiate()
	get_root().add_child(scene)
	scene._ready()

	# Verify HUD shows carried / capacity
	scene._update_hud()
	ok(scene._hud_label.text.find("0 / 10") != -1, "UI HUD displays carried / capacity")

	# Light L1 and leave L2 unlit to verify fuel bar vs 20% deflate + torn paper
	scene._sim.lanterns[0].lit = true
	scene._sim.lanterns[0].fuel_units = 1500  # fuel = 25 (<30)
	scene._sim.lanterns[1].lit = false
	var sd := Entities.ShadeData.new()
	sd.id = "S1"
	sd.pos = Vector3(12, 0, 12)
	sd.state = Entities.SHADE_WANDER
	scene._sim.shades.append(sd)

	# Normal mode sync
	scene._settings.colorblind = false
	scene._sync_visuals()
	scene._update_hud()
	var l1_nodes: Dictionary = scene._lantern_nodes["L1"]
	var l2_nodes: Dictionary = scene._lantern_nodes["L2"]
	var s1_nodes: Dictionary = scene._shade_nodes["S1"]
	ok((l1_nodes["bar_fill"] as MeshInstance3D).visible, "UI lit lantern shows fuel bar")
	ok(is_equal_approx((l2_nodes["post"] as MeshInstance3D).scale.y, 0.8) and (l2_nodes["tear"] as MeshInstance3D).visible,
		"UI unlit lantern deflated 20% (scale.y=0.8) with torn paper")
	ok((s1_nodes["emat"] as StandardMaterial3D).albedo_color.is_equal_approx(Color("#7A3CFF")),
		"UI normal Shade eyes/rim color is #7A3CFF")

	# Enable Colorblind mode ("Bảng màu dễ phân biệt")
	scene._settings.colorblind = true
	scene._sync_visuals()
	scene._update_hud()
	ok((s1_nodes["emat"] as StandardMaterial3D).albedo_color.is_equal_approx(Color("#00B3FF")),
		"UI colorblind Shade eyes/rim switches to #00B3FF")
	ok(scene._warning_label.modulate.is_equal_approx(Color("#FFFFFF")) and scene._warning_label.text.find("⚠") != -1,
		"UI colorblind warning uses #FFFFFF + ⚠ icon")

	scene.free()
