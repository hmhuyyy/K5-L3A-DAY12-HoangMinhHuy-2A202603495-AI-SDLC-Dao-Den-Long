# run_unit.gd — in-process unit/scenario tests for GameSim, Config and friends.
# Run: godot --headless --path . --script res://tests/unit/run_unit.gd
# Exit code 0 = all passed. Called from tests/run_tests.sh.
extends SceneTree

var cfg: Config
var passed := 0
var failed := 0
var events: Array = []

func _init() -> void:
	cfg = Config.load_from_file("res://game.contract.json")
	if cfg == null:
		printerr("cannot load contract")
		quit(1)
		return
	var tests := [
		"t_config_strict", "t_fuel_decay", "t_fuel_zero", "t_first_light", "t_relight",
		"t_refuel_ceil", "t_refuel_full_noop", "t_lantern_selection", "t_safe_zone_threshold",
		"t_wander_weak_target", "t_drain_basic", "t_drain_stacking", "t_drain_exits",
		"t_pulse_normal", "t_pulse_drain", "t_safe_push", "t_safe_push_no_damage",
		"t_dawn_thresholds", "t_no_early_win", "t_no_flames_at_dawn", "t_dawn_score",
		"t_capacity_light", "t_capacity_relight", "t_capacity_prelit", "t_capacity_cap",
		"t_snapshot_v12", "t_events_v12", "t_determinism", "t_fall_single_flame",
		"t_stun_timing", "t_pause_ticks",
	]
	for t: String in tests:
		call(t)
	print("Unit results: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)

# ── helpers ───────────────────────────────────────────────────
func ok(cond: bool, label: String) -> void:
	if cond:
		passed += 1
		print("PASS  " + label)
	else:
		failed += 1
		print("FAIL  " + label)

func mk(night: int, sc: Dictionary, seed_v: int = 1) -> GameSim:
	var s := GameSim.new()
	s.init(cfg, seed_v, night, sc)
	s.bus.drain()
	events.clear()
	return s

func base(carried: int, lanterns: Array, shades: Array = [], ppos: Array = [0, 0, 0], extra: Dictionary = {}) -> Dictionary:
	var d := {
		"player": {"pos": ppos, "carried": carried, "flames": 3},
		"random_motes": false, "random_shades": false,
		"lanterns": lanterns,
	}
	if not shades.is_empty():
		d["shades"] = shades
	d.merge(extra, true)
	return d

func _t(s: GameSim, inp: InputState) -> void:
	s.tick(inp)
	events.append_array(s.bus.drain())

func idle(s: GameSim, n: int) -> void:
	for i in range(n):
		_t(s, InputState.new())

func tap(s: GameSim, btn: String) -> void:
	var inp := InputState.new()
	inp.set(btn, true)
	_t(s, inp)

func evs(name: String) -> Array:
	return events.filter(func(e: Dictionary) -> bool: return e["name"] == name)

func lan(s: GameSim, id: String) -> Entities.LanternData:
	return s._find_lantern_by_id(id)

func shd(s: GameSim, id: String) -> Entities.ShadeData:
	return s._find_shade(id)

func L(id: String, pos: Array, extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "pos": pos}
	d.merge(extra, true)
	return d

func SH(id: String, pos: Array, state: String = "wander", extra: Dictionary = {}) -> Dictionary:
	var d := {"id": id, "pos": pos, "state": state}
	d.merge(extra, true)
	return d

const FAR := [0, 0, -35]

# ── Config (strict validation) ────────────────────────────────
func _contract_dict() -> Dictionary:
	var f := FileAccess.open("res://game.contract.json", FileAccess.READ)
	var j := JSON.new()
	j.parse(f.get_as_text())
	return j.get_data()

func t_config_strict() -> void:
	ok(Config.parse_dict(_contract_dict()) != null, "CFG valid contract loads")
	ok(cfg.contract_version == "1.3" or cfg.contract_version == "1.2", "CFG contract_version is a String 1.2/1.3")
	var d := _contract_dict()
	d["tuning"]["fuel_max"] = 100.0
	ok(Config.parse_dict(d) != null, "CFG int accepts integer-valued float")
	d = _contract_dict(); d["tuning"]["fuel_max"] = 100.5
	ok(Config.parse_dict(d) == null and Config.last_error.contains("tuning.fuel_max"), "CFG int rejects fractional float (path in error)")
	d = _contract_dict(); d["tuning"]["fuel_max"] = true
	ok(Config.parse_dict(d) == null, "CFG int rejects bool")
	d = _contract_dict(); d["tuning"]["fuel_max"] = "100"
	ok(Config.parse_dict(d) == null, "CFG int rejects string")
	d = _contract_dict(); d["tuning"]["fuel_max"] = null
	ok(Config.parse_dict(d) == null, "CFG int rejects null")
	d = _contract_dict(); d["tuning"]["fuel_max"] = NAN
	ok(Config.parse_dict(d) == null, "CFG int rejects NaN")
	d = _contract_dict(); d["tuning"]["fuel_max"] = INF
	ok(Config.parse_dict(d) == null, "CFG int rejects Inf")
	d = _contract_dict(); d["tuning"]["win_ratio"] = true
	ok(Config.parse_dict(d) == null and Config.last_error.contains("tuning.win_ratio"), "CFG float rejects bool")
	d = _contract_dict(); d["tuning"]["win_ratio"] = "0.6"
	ok(Config.parse_dict(d) == null, "CFG float rejects string")
	d = _contract_dict(); d["tuning"]["win_ratio"] = null
	ok(Config.parse_dict(d) == null, "CFG float rejects null")
	d = _contract_dict(); d["tuning"]["fall_enabled"] = 1
	ok(Config.parse_dict(d) == null, "CFG bool only accepts bool")
	d = _contract_dict(); d["contract_version"] = 1.2
	ok(Config.parse_dict(d) == null, "CFG contract_version must be String")
	d = _contract_dict(); d["contract_version"] = "9.9"
	ok(Config.parse_dict(d) == null, "CFG unknown contract version rejected")
	d = _contract_dict(); d["tuning"].erase("relight_cost")
	ok(Config.parse_dict(d) == null and Config.last_error.contains("tuning.relight_cost"), "CFG missing required key names path")
	d = _contract_dict(); d["tuning"]["score"] = []
	ok(Config.parse_dict(d) == null, "CFG score must be dict")
	d = _contract_dict(); d["tuning"] = []
	ok(Config.parse_dict(d) == null, "CFG tuning must be dict")
	d = _contract_dict(); d["tuning"]["score"]["per_mote"] = 5.5
	ok(Config.parse_dict(d) == null and Config.last_error.contains("tuning.score.per_mote"), "CFG score int strict")
	ok(cfg.fuel_max == 100 and cfg.fuel_per_mote == 10 and cfg.relight_cost == 5 and cfg.capacity_max == 20
		and absf(cfg.win_ratio - 0.6) < 1e-9 and cfg.low_fuel_threshold == 30 and cfg.drain_per_s == 5.0
		and cfg.night1_duration_s == 240.0 and cfg.night2_duration_s == 270.0 and cfg.night3_duration_s == 300.0,
		"CFG v1.2 tuning values")

# ── 1. fuel decay ─────────────────────────────────────────────
func t_fuel_decay() -> void:
	var s := mk(1, base(0, [L("L1", [0, 0, 25], {"lit": true})], [], FAR))
	ok(lan(s, "L1").fuel_units == 6000, "FUEL scenario pre-lit defaults to fuel=100 (6000 units)")
	idle(s, 60)
	ok(lan(s, "L1").fuel_units == 5940, "FUEL decay = 1 unit/tick (5940 after 60 ticks)")
	ok(s.snapshot()["lanterns"][0]["fuel"] == 99.0, "FUEL snapshot rounds to 1 decimal (99.0)")
	s.lanterns[0].fuel_units = 2
	idle(s, 1)
	ok(lan(s, "L1").fuel_units == 1 and lan(s, "L1").lit, "FUEL integer units: 1 unit left, still lit")
	idle(s, 1)
	ok(not lan(s, "L1").lit and lan(s, "L1").fuel_units == 0, "FUEL exactly zero -> unlit (no float drift)")
	var s2 := mk(1, base(0, [L("L1", [0, 0, 25], {"lit": true})], [], FAR))
	s2._next_shade_spawn_tick = 99999999  # no spawned shades: pure decay
	var n := 0
	while lan(s2, "L1").lit and n < 7000 and s2.state == "playing":
		s2.player.invuln_ticks = 99
		_t(s2, InputState.new())
		n += 1
	ok(n == 6000 and not lan(s2, "L1").lit, "FUEL full lantern burns out in exactly 6000 ticks (100 s), got %d" % n)

# ── 2. fuel reaching zero ─────────────────────────────────────
func t_fuel_zero() -> void:
	var s := mk(1, base(0, [L("L1", [0, 0, 25], {"lit": true, "fuel": 0.05, "relit_count": 2, "deposited": 3})], [], FAR))
	idle(s, 2)
	ok(lan(s, "L1").lit, "ZERO lantern lit before depletion")
	idle(s, 1)
	var l := lan(s, "L1")
	ok(not l.lit and l.fuel_units == 0 and l.deposited == 0 and l.ever_lit and l.relit_count == 2, "ZERO lit=false fuel=0 deposited=0 ever_lit kept relit_count kept")
	ok(evs("lantern_out").size() == 1 and evs("lantern_out")[0]["data"]["lantern_id"] == "L1" and evs("lantern_out")[0]["tick"] == 3, "ZERO lantern_out once at tick 3")
	idle(s, 5)
	ok(evs("lantern_out").size() == 1, "ZERO lantern_out not repeated")
	ok(not s._in_any_safe_zone(0.0, 25.0), "ZERO safe zone vanishes immediately")

# ── 3. first light ────────────────────────────────────────────
func t_first_light() -> void:
	var s := mk(1, base(10, [L("L1", [0, 0, 1])]))
	tap(s, "interact")
	var l := lan(s, "L1")
	ok(l.lit and l.fuel_units == 6000 and l.ever_lit and l.relit_count == 0 and l.deposited == 0, "LIGHT first light: fuel=100 ever_lit relit_count=0")
	ok(s.score == 10 * 5 + 100, "LIGHT first light score 10*5+100")
	ok(s.player.carried == 0 and s.player.successful_lights == 1, "LIGHT carried consumed, successful_lights=1")
	var lit: Array = evs("lantern_lit")
	ok(lit.size() == 1 and lit[0]["data"]["relight"] == false, "LIGHT lantern_lit relight=false")
	ok(evs("deposit").size() == 1 and evs("deposit")[0]["data"]["amount"] == 10, "LIGHT deposit event amount 10")
	# partial deposits accumulate, 5 points per mote
	var s2 := mk(1, base(4, [L("L1", [0, 0, 1])]))
	tap(s2, "interact")
	ok(not lan(s2, "L1").lit and lan(s2, "L1").deposited == 4 and s2.score == 20, "LIGHT partial deposit 4 -> +20, deposited=4")

# ── 4. relight ────────────────────────────────────────────────
func t_relight() -> void:
	var s := mk(1, base(5, [L("L1", [0, 0, 1], {"lit": false, "ever_lit": true})]))
	tap(s, "interact")
	var l := lan(s, "L1")
	ok(l.lit and l.fuel_units == 6000 and l.relit_count == 1 and l.deposited == 0, "RELIGHT 5 motes relight: fuel=100 relit_count=1")
	ok(s.score == 5 * 5 + 40, "RELIGHT score 5*5+40")
	ok(evs("lantern_lit")[0]["data"]["relight"] == true, "RELIGHT lantern_lit relight=true")
	var s2 := mk(1, base(4, [L("L1", [0, 0, 1], {"lit": false, "ever_lit": true})]))
	tap(s2, "interact")
	ok(not lan(s2, "L1").lit and s2.score == 20, "RELIGHT 4 motes is not enough")

# ── 5. refuel ceil ────────────────────────────────────────────
func t_refuel_ceil() -> void:
	var s := mk(1, base(10, [L("L1", [0, 0, 1], {"lit": true, "fuel": 55})]))
	tap(s, "interact")
	var r: Array = evs("refuel")
	ok(r.size() == 1 and r[0]["data"]["amount"] == 5 and r[0]["data"]["lantern_id"] == "L1", "REFUEL fuel 55 -> ceil(45/10)=5 motes")
	ok(lan(s, "L1").fuel_units == 6000 and s.player.carried == 5, "REFUEL capped at 100, leftover kept")
	ok(s.score == 25 and evs("lantern_lit").is_empty(), "REFUEL +5/mote only, no light bonus")
	var s2 := mk(1, base(10, [L("L1", [0, 0, 1], {"lit": true, "fuel": 91})]))
	tap(s2, "interact")
	ok(evs("refuel")[0]["data"]["amount"] == 1 and s2.player.carried == 9, "REFUEL fuel 91 -> ceil(0.9)=1")
	var s3 := mk(1, base(2, [L("L1", [0, 0, 1], {"lit": true, "fuel": 20})]))
	tap(s3, "interact")
	ok(evs("refuel")[0]["data"]["amount"] == 2 and absf(float(lan(s3, "L1").fuel_units) / 60.0 - 40.0) < 0.05, "REFUEL limited by carried (2 motes = +20)")

# ── 6. refuel full no-op ──────────────────────────────────────
func t_refuel_full_noop() -> void:
	var s := mk(1, base(5, [L("L1", [0, 0, 1], {"lit": true, "fuel": 100})]))
	var inp := InputState.new()
	inp.interact = true
	s.tick(inp)  # tick 1: step 2 decays one unit BEFORE interaction (fuel 99.98 < full)
	events.append_array(s.bus.drain())
	ok(evs("refuel").size() == 1 and evs("refuel")[0]["data"]["amount"] == 1, "FULL decay-before-interact makes fuel just below full -> 1 mote")
	var s2 := mk(1, base(5, [L("L1", [0, 0, 1], {"lit": true, "fuel": 100})]))
	s2.lanterns[0].fuel_units = 6000
	var inp2 := InputState.new()
	inp2.interact = true
	var pre_score := s2.score
	# call the interaction step directly with a truly full lantern
	s2._step_lantern_interact(inp2, 1)
	var evs2 := s2.bus.drain()
	ok(evs2.is_empty() and s2.player.carried == 5 and s2.score == pre_score, "FULL full lantern: no event, no score, no mote used")

# ── 7. selection nearest / tie ───────────────────────────────
func t_lantern_selection() -> void:
	var s := mk(1, base(10, [L("L1", [0, 0, -1.0]), L("L2", [0, 0, 1.5])]))
	tap(s, "interact")
	ok(lan(s, "L1").lit and not lan(s, "L2").lit, "SELECT nearest lantern wins")
	var s2 := mk(1, base(10, [L("L1", [1, 0, 0]), L("L2", [-1, 0, 0])]))
	tap(s2, "interact")
	ok(lan(s2, "L1").lit and not lan(s2, "L2").lit, "SELECT tie -> lowest id")
	var s3 := mk(1, base(10, [L("L1", [0, 0, 0.5], {"lit": true, "fuel": 100}), L("L2", [0, 0, 1.5])]))
	s3._step_lantern_interact(_inp("interact"), 1)
	ok(lan(s3, "L2").lit, "SELECT full lantern is skipped even if nearer")
	var s4 := mk(1, base(10, [L("L1", [0, 0, 3.0])]))
	tap(s4, "interact")
	ok(not lan(s4, "L1").lit and s4.player.carried == 10, "SELECT out of interact radius ignored")

func _inp(btn: String) -> InputState:
	var i := InputState.new()
	i.set(btn, true)
	return i

# ── 8. safe zone threshold ────────────────────────────────────
func t_safe_zone_threshold() -> void:
	var s := mk(1, base(0, [L("L1", [0, 0, 0], {"lit": true, "fuel": 30})], [], FAR))
	ok(s._in_any_safe_zone(5.0, 0.0), "SAFE fuel exactly 30 keeps the safe zone")
	s.lanterns[0].fuel_units = 1799
	ok(not s._in_any_safe_zone(5.0, 0.0), "SAFE fuel < 30 loses the safe zone")
	s.lanterns[0].fuel_units = 6000
	ok(s._in_any_safe_zone(6.0, 0.0) and not s._in_any_safe_zone(6.5, 0.0), "SAFE radius 6 m")

# ── 9. wander targeting ──────────────────────────────────────
func t_wander_weak_target() -> void:
	var s := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 20}), L("L2", [-5, 0, 0], {"lit": true, "fuel": 25})], [SH("S1", [4, 0, 0])], FAR))
	idle(s, 1)
	ok(shd(s, "S1").target_lantern_id == "L1", "WANDER nearest weak lit lantern (L1 d=6 < L2 d=9)")
	var s2 := mk(1, base(0, [L("L1", [6, 0, 0], {"lit": true, "fuel": 20}), L("L2", [-6, 0, 0], {"lit": true, "fuel": 20})], [SH("S1", [0, 0, 0])], FAR))
	idle(s2, 1)
	ok(shd(s2, "S1").target_lantern_id == "L1", "WANDER tie -> lowest id")
	var s3 := mk(1, base(0, [L("L1", [20, 0, 0], {"lit": false}), L("L2", [-10, 0, 0], {"lit": false}), L("L3", [0, 0, 5], {"lit": true, "fuel": 90})], [SH("S1", [0, 0, 0])], FAR))
	idle(s3, 1)
	ok(shd(s3, "S1").target_lantern_id == "L3" or shd(s3, "S1").target_lantern_id == "L2", "WANDER no weak lit -> nearest unlit lantern")
	ok(shd(s3, "S1").target_lantern_id == "L2" or shd(s3, "S1").target_lantern_id == "L3", "WANDER target set")
	ok(shd(s3, "S1").target_lantern_id == "L2", "WANDER unlit target L2 (lit healthy L3 is not a candidate)")
	# chase shades never retarget
	var s4 := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 20})], [SH("S1", [-20, 0, 0], "chase")], [-30, 0, 0]))
	idle(s4, 3)
	ok(shd(s4, "S1").target_lantern_id == "" and shd(s4, "S1").state == "chase", "WANDER chase shade does not pick weak lantern")
	# a drain shade only starts when wandering shade reaches <= 2 m
	var s5 := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 20})], [SH("S1", [10, 0, 3])], FAR))
	idle(s5, 1)
	ok(shd(s5, "S1").state == "wander", "WANDER 3 m away: still walking")
	idle(s5, 30)
	ok(shd(s5, "S1").state == "drain", "WANDER walks into the lantern and starts draining")

# ── 10. drain ────────────────────────────────────────────────
func t_drain_basic() -> void:
	var s := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 20})], [SH("S1", [10, 0, 1])], FAR))
	idle(s, 1)
	ok(shd(s, "S1").state == "drain", "DRAIN wander within 2 m -> drain")
	ok(lan(s, "L1").fuel_units == 1199, "DRAIN tick 1 only base decay")
	idle(s, 1)
	ok(lan(s, "L1").fuel_units == 1193, "DRAIN 5 extra units/tick (5 fuel/s)")
	var pos_before := shd(s, "S1").pos
	idle(s, 59)
	ok(shd(s, "S1").pos == pos_before, "DRAIN shade stands still")
	var fd: Array = evs("fuel_drain")
	ok(fd.size() == 1 and fd[0]["tick"] == 61 and fd[0]["data"]["lantern_id"] == "L1" and fd[0]["data"]["shade_id"] == "S1", "DRAIN fuel_drain every 60 ticks (tick 61)")
	ok(fd[0]["data"]["fuel"] == 14.0, "DRAIN fuel_drain.fuel = fuel after update (14.0)")
	ok(fd.size() == 1, "DRAIN only one event per 60 ticks")

# ── 11. stacking ─────────────────────────────────────────────
func t_drain_stacking() -> void:
	var s := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 20})], [SH("S1", [10, 0, 1]), SH("S2", [10, 0, -1])], FAR))
	idle(s, 2)
	ok(lan(s, "L1").fuel_units == 1199 - 11, "STACK two drainers = 1 + 5 + 5 units per tick")
	idle(s, 59)
	var fd: Array = evs("fuel_drain")
	ok(fd.size() == 2 and fd[0]["data"]["shade_id"] != fd[1]["data"]["shade_id"], "STACK each shade has its own fuel_drain event")

# ── 12. drain exit conditions ────────────────────────────────
func _drain_sim(ppos: Array = FAR, extra: Dictionary = {}) -> GameSim:
	var sc := base(3, [L("L1", [10, 0, 0], {"lit": true, "fuel": 20})], [SH("S1", [10, 0, 1], "drain", {"target_lantern_id": "L1"})], ppos, extra)
	return mk(1, sc)

func t_drain_exits() -> void:
	var s := _drain_sim()
	idle(s, 1)
	ok(shd(s, "S1").state == "drain", "EXIT control: stays draining")
	var s1 := _drain_sim([10, 0, -3])
	idle(s1, 1)
	ok(shd(s1, "S1").state == "chase", "EXIT player within 6 m -> chase")
	var s2 := _drain_sim([10, 0, -3])
	tap(s2, "pulse")
	ok(shd(s2, "S1").state == "stunned", "EXIT pulse -> stunned")
	var s3 := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 0.05})], [SH("S1", [10, 0, 1], "drain", {"target_lantern_id": "L1"})], FAR))
	idle(s3, 3)
	ok(shd(s3, "S1").state == "wander", "EXIT lantern out -> wander")
	var s4 := _drain_sim()
	s4.lanterns[0].fuel_units = 1810
	idle(s4, 1)
	ok(shd(s4, "S1").state == "wander", "EXIT fuel refilled to >= 30 -> wander")
	var s5 := _drain_sim()
	shd(s5, "S1").pos = Vector3(10, 0, 5)
	idle(s5, 1)
	ok(shd(s5, "S1").state != "drain" and shd(s5, "S1").state != "stunned", "EXIT farther than 2 m -> wander")
	var s6 := mk(1, base(0, [], [SH("S1", [-20, 0, 0], "stunned", {"state_ticks_left": 2})], FAR))
	idle(s6, 1)
	ok(shd(s6, "S1").state == "stunned", "EXIT stunned lasts until counter")
	idle(s6, 1)
	ok(shd(s6, "S1").state == "wander", "EXIT stunned over -> wander")

# ── 13/14. pulse scoring ─────────────────────────────────────
func t_pulse_normal() -> void:
	var s := mk(1, base(3, [], [SH("S1", [3, 0, 0]), SH("S2", [0, 0, 4], "chase"), SH("S3", [30, 0, 0])]))
	tap(s, "pulse")
	ok(s.score == 10, "PULSE normal shades +5 each (2 hit, 1 far)")
	ok(evs("pulse")[0]["data"]["stunned_ids"] == ["S1", "S2"], "PULSE stunned_ids")
	ok(s.player.carried == 0, "PULSE costs 3 motes")

func t_pulse_drain() -> void:
	var s := _drain_sim([10, 0, -3])
	tap(s, "pulse")
	ok(s.score == 15, "PULSE draining shade total +15 (not +20)")
	var s2 := _drain_sim([10, 0, -3])
	tap(s2, "pulse")
	s2.player.pulse_cd_ticks = 0
	s2.player.carried = 3
	var before := s2.score
	tap(s2, "pulse")
	ok(s2.score - before == 5, "PULSE re-pulse of a stunned (ex-drain) shade is +5")

# ── 15/16. safe push ─────────────────────────────────────────
func _push_sim(shade_pos: Array, ppos: Array) -> GameSim:
	return mk(1, base(2, [L("L1", [0, 0, 0], {"lit": true, "fuel": 25})], [SH("S1", shade_pos)], ppos))

func t_safe_push() -> void:
	var s := _push_sim([3, 0, 0], [0, 0, -1.5])
	tap(s, "interact")
	ok(lan(s, "L1").fuel_units >= 1800, "PUSH refuel 25 -> >= 30")
	ok(shd(s, "S1").push_ticks_left > 0, "PUSH shade inside 6 m is being pushed")
	idle(s, 29)
	var d := GameSim._xz_dist(shd(s, "S1").pos, Vector3.ZERO)
	ok(d >= 6.0 and shd(s, "S1").push_ticks_left == 0, "PUSH shade at the rim within 30 ticks (d=%.3f)" % d)
	var s2 := _push_sim([3, 0, 0], [0, 0, -1.5])
	s2.lanterns[0].fuel_units = 1800
	idle(s2, 1)
	ok(shd(s2, "S1").push_ticks_left == 0, "PUSH no push when nothing crossed the threshold")
	var s3 := mk(1, base(10, [L("L1", [0, 0, 0])], [SH("S1", [2, 0, 2])], [0, 0, -1.5]))
	tap(s3, "interact")
	ok(shd(s3, "S1").push_ticks_left > 0, "PUSH first light also pushes shades out")

func t_safe_push_no_damage() -> void:
	var ctrl := _push_sim([0, 0, 0], [0, 0, -0.4])
	idle(ctrl, 1)
	ok(evs("player_hit").size() == 1, "NODMG control: overlapping shade hurts")
	var s := _push_sim([0, 0, 0], [0, 0, -0.4])
	tap(s, "interact")
	idle(s, 10)
	ok(evs("player_hit").is_empty() and s.player.flames == 3, "NODMG no damage while pushed")

# ── 17..21 dawn ──────────────────────────────────────────────
func _dawn(night: int, lit_n: int, total: int, extra_player: Dictionary = {}, lit_fuel: Array = []) -> GameSim:
	var lanterns: Array = []
	var world := WorldDefs.for_night(night)
	for i in range(total):
		var def: Dictionary = world["lanterns"][i]
		var p: Vector3 = def["pos"]
		var d := {"id": def["id"], "pos": [p.x, p.y, p.z], "lit": i < lit_n}
		if i < lit_fuel.size():
			d["fuel"] = lit_fuel[i]
		lanterns.append(d)
	var sc := base(0, lanterns, [], [0, 0, 0], {"time_left_s": 1.0})
	for k in extra_player:
		sc["player"][k] = extra_player[k]
	return mk(night, sc)

func t_dawn_thresholds() -> void:
	for pair in [[1, 5, 3], [2, 6, 4], [3, 7, 5]]:
		var n: int = pair[0]
		var total: int = pair[1]
		var req: int = pair[2]
		var s := _dawn(n, req, total)
		ok(s.required_lit() == req, "DAWN night %d requires %d/%d" % [n, req, total])
		idle(s, 60)
		ok(s.state == "won" and evs("game_over")[0]["data"]["reason"] == "dawn_survived", "DAWN night %d: %d lit -> dawn_survived" % [n, req])
		var s2 := _dawn(n, req - 1, total)
		idle(s2, 60)
		ok(s2.state == "lost" and evs("game_over")[0]["data"]["reason"] == "dawn", "DAWN night %d: %d lit -> dawn loss" % [n, req - 1])

func t_no_early_win() -> void:
	var s := mk(1, base(0, [L("L1", [0, 0, 2], {"lit": true}), L("L2", [0, 0, 4], {"lit": true}), L("L3", [0, 0, 6], {"lit": true}), L("L4", [0, 0, 8], {"lit": true}), L("L5", [0, 0, 10], {"lit": true})], [], [0, 0, 0], {"time_left_s": 300}))
	idle(s, 30)
	ok(s.state == "playing" and evs("game_over").is_empty(), "EARLY all lanterns lit does not end the night")
	ok(evs("game_over").filter(func(e): return e["data"]["reason"] == "all_lit").is_empty(), "EARLY no all_lit reason")

func t_no_flames_at_dawn() -> void:
	var lanterns: Array = []
	for i in range(5):
		lanterns.append(L("L%d" % (i + 1), [0, 0, 2 + 2 * i], {"lit": true}))
	var sc := base(0, lanterns, [SH("S1", [0, 0, 0], "chase")], [0, 0, 0], {"time_left_s": 1.0})
	sc["player"]["flames"] = 1
	sc["player"]["invuln_ticks"] = 60
	var s := mk(1, sc)
	idle(s, 60)
	var go: Array = evs("game_over")
	ok(go.size() == 1 and go[0]["data"]["reason"] == "no_flames" and s.state == "lost", "NOFLAME exactly at dawn tick: no_flames beats dawn_survived")
	ok(go[0]["tick"] == 60, "NOFLAME game_over on tick 60")

func t_dawn_score() -> void:
	var s := _dawn(1, 3, 5, {}, [50, 70.5, 100])
	idle(s, 60)
	# fuel after 60 ticks: 49.0, 69.5, 99.0 -> floor 49, 69, 99; + 50 each lit; + 50*3 flames
	ok(s.score == (50 + 49) + (50 + 69) + (50 + 99) + 150, "SCORE dawn = sum(50+floor(fuel)) + 50*flames (=%d)" % s.score)
	ok(evs("game_over")[0]["data"]["reason"] == "dawn_survived", "SCORE dawn win reason")
	var s2 := _dawn(1, 3, 5, {"flames": 2})
	idle(s2, 60)
	ok(s2.score == 3 * (50 + 99) + 100, "SCORE no time bonus, flames count (=%d)" % s2.score)
	var s3 := _dawn(1, 2, 5)
	idle(s3, 60)
	ok(s3.score == 0, "SCORE dawn loss gives no end bonus")

# ── 22..25 capacity ──────────────────────────────────────────
func t_capacity_light() -> void:
	var s := mk(1, base(10, [L("L1", [0, 0, 1]), L("L2", [0, 0, -1])]))
	ok(s.player.capacity == 10, "CAP start capacity 10")
	tap(s, "interact")
	ok(s.player.capacity == 12 and s.player.successful_lights == 1, "CAP first light -> 12")
	s.player.carried = 10
	s.player.pos = Vector3(0, 0, -8)
	s.lanterns[1].pos = Vector3(0, 0, -8)
	idle(s, 1)
	tap(s, "interact")
	ok(s.player.capacity == 14, "CAP second light -> 14")
	ok(s.player.carried == 0, "CAP carried untouched by capacity growth")
	var s2 := mk(1, base(8, [L("L1", [0, 0, 1])]))
	s2.player.capacity = 10
	tap(s2, "interact")
	ok(s2.player.carried == 0, "CAP deposit lowers carried")

func t_capacity_relight() -> void:
	var s := mk(1, base(5, [L("L1", [0, 0, 1], {"ever_lit": true})]))
	tap(s, "interact")
	ok(s.player.capacity == 12, "CAP relight counts as a successful light")
	var s2 := mk(1, base(10, [L("L1", [0, 0, 1], {"lit": true, "fuel": 50})]))
	tap(s2, "interact")
	ok(s2.player.capacity == 10, "CAP refuel does not grow capacity")

func t_capacity_prelit() -> void:
	var s := mk(1, base(0, [L("L1", [0, 0, 25], {"lit": true}), L("L2", [3, 0, 25], {"lit": true})], [], FAR))
	ok(s.player.capacity == 10 and s.player.successful_lights == 0, "CAP scenario pre-lit lanterns do not raise capacity")
	ok(s.bus.drain().is_empty() and s.score == 0, "CAP scenario setup: no events, no score")
	var s2 := mk(1, base(0, [L("L1", [0, 0, 25])], [], FAR, {}))
	s2.player.successful_lights = 0
	ok(s2.player.capacity == 10, "CAP successful_lights reset each night (fresh sim)")

func t_capacity_cap() -> void:
	var sc := base(10, [L("L1", [0, 0, 1])])
	sc["player"]["successful_lights"] = 5
	var s := mk(1, sc)
	ok(s.player.capacity == 20, "CAP 5 lights -> 20")
	tap(s, "interact")
	ok(s.player.successful_lights == 6 and s.player.capacity == 20, "CAP never exceeds 20")

# ── 26/27 snapshot & events v1.2 ─────────────────────────────
func t_snapshot_v12() -> void:
	var s := mk(1, base(0, [L("L1", [0, 0, 25], {"lit": true, "fuel": 50, "relit_count": 1}), L("L2", [5, 0, 25])], [SH("S1", [0, 0, 24], "drain", {"target_lantern_id": "L1"})], FAR))
	s.lanterns[0].fuel_units = 1200
	idle(s, 1)
	var snap := s.snapshot()
	var l0: Dictionary = snap["lanterns"][0]
	var l1: Dictionary = snap["lanterns"][1]
	for k in ["id", "pos", "lit", "deposited", "fuel", "ever_lit", "relit_count"]:
		ok(l0.has(k), "SNAP lantern has '%s'" % k)
	ok(l0["fuel"] == 19.9, "SNAP fuel rounded to 1 decimal (%s)" % str(l0["fuel"]))
	ok(l1["fuel"] == 0.0 and l1["lit"] == false, "SNAP unlit lantern fuel 0")
	ok(snap["shades"][0]["state"] == "drain", "SNAP shade state drain")
	for k in ["pos", "vel", "flames", "carried", "capacity", "grounded", "invuln", "dash_cd_s", "pulse_cd_s", "charm_s"]:
		ok(snap["player"].has(k), "SNAP player has '%s'" % k)
	for k in ["type", "tick", "sim_tick", "night", "state", "time_left_s", "score", "wind", "lanterns", "shades", "motes", "drifters", "charms"]:
		ok(snap.has(k), "SNAP top-level '%s'" % k)
	ok(snap["wind"].has("active") and snap["wind"].has("dir_deg"), "SNAP wind {active, dir_deg}")
	ok(JSON.stringify(snap).find("1.0e") == -1, "SNAP json has no exponent floats")

func t_events_v12() -> void:
	var s := mk(1, base(10, [L("L1", [0, 0, 1])]))
	tap(s, "interact")
	ok(evs("lantern_lit")[0]["data"].keys() == ["lantern_id", "relight"], "EVT lantern_lit {lantern_id, relight}")
	var s2 := mk(1, base(3, [L("L1", [0, 0, 1], {"lit": true, "fuel": 40})]))
	tap(s2, "interact")
	ok(evs("refuel")[0]["data"].keys() == ["lantern_id", "amount", "fuel"], "EVT refuel {lantern_id, amount, fuel}")
	var s3 := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 0.05})], [], FAR))
	idle(s3, 3)
	ok(evs("lantern_out")[0]["data"].keys() == ["lantern_id"], "EVT lantern_out {lantern_id}")
	var s4 := mk(1, base(0, [L("L1", [10, 0, 0], {"lit": true, "fuel": 20})], [SH("S1", [10, 0, 1])], FAR))
	idle(s4, 61)
	ok(evs("fuel_drain")[0]["data"].keys() == ["lantern_id", "shade_id", "fuel"], "EVT fuel_drain {lantern_id, shade_id, fuel}")
	var s5 := _dawn(1, 3, 5)
	idle(s5, 60)
	ok(evs("game_over")[0]["data"]["result"] == "won" and evs("game_over")[0]["data"]["reason"] == "dawn_survived", "EVT game_over dawn_survived")

# ── 28 determinism ───────────────────────────────────────────
func _scripted_run(seed_v: int, night: int) -> String:
	var s := mk(night, {}, seed_v)
	var inp := InputState.new()
	var out := ""
	for k in range(2400):
		inp.advance_prev()
		inp.move = Vector2(sin(k * 0.013), cos(k * 0.007)).normalized()
		inp.jump = (k % 97) < 3
		inp.dash = (k % 151) < 2
		inp.interact = (k % 40) < 2
		inp.pulse = (k % 233) < 2
		s.tick(inp)
		for e in s.bus.drain():
			out += JSON.stringify(e)
		if s.state == "won" or s.state == "lost":
			break
	return out + JSON.stringify(s.snapshot())

func t_determinism() -> void:
	for n in [1, 2, 3]:
		var a := _scripted_run(42, n)
		var b := _scripted_run(42, n)
		ok(a == b and a.length() > 100, "DET night %d same seed -> identical events+snapshot" % n)
	ok(_scripted_run(42, 1) != _scripted_run(43, 1), "DET different seed differs")

# ── Phase-2 regression: fall, stun timing, pause ─────────────
func t_fall_single_flame() -> void:
	var s := mk(1, base(4, [], [], [41, 0, 0]))
	s.player.pos = Vector3(60, -11, 0)
	idle(s, 1)
	ok(s.player.flames == 2 and s.player.carried == 0, "FALL exactly one flame lost, motes lost")
	idle(s, 70)
	ok(s.player.flames == 2 and s.player.invuln_ticks > 0 and s.player.pos == Vector3.ZERO, "FALL respawn does not cost a second flame")
	ok(evs("player_hit").size() == 1, "FALL single player_hit")

func t_stun_timing() -> void:
	var s := mk(1, base(3, [], [SH("S1", [3, 0, 0])]))
	tap(s, "pulse")
	ok(shd(s, "S1").state == "stunned" and shd(s, "S1").state_ticks_left == 120, "STUN set to 120 on pulse tick")
	idle(s, 119)
	ok(shd(s, "S1").state == "stunned", "STUN still stunned after 119 more ticks")
	idle(s, 1)
	ok(shd(s, "S1").state != "stunned", "STUN ends on 120th counter step")

func t_pause_ticks() -> void:
	var s := mk(1, base(0, [L("L1", [0, 0, 25], {"lit": true})], [], FAR))
	var p := InputState.new()
	p.pause = true
	_t(s, p)
	ok(s.paused and s.state == "paused" and s.executed_ticks == 1 and s.sim_tick == 0, "PAUSE executed_ticks++ sim_tick frozen")
	var q := InputState.new()
	q.pause = true
	q.advance_prev()
	q.pause = true
	idle(s, 5)
	ok(s.executed_ticks == 6 and s.sim_tick == 0 and lan(s, "L1").fuel_units == 6000, "PAUSE counters and fuel frozen")
