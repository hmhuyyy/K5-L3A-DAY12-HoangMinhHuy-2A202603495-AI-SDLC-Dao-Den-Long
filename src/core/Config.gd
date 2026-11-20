# Config.gd — Single source of truth for tuning values.
# Loads game.contract.json once; exposes all tuning fields.
# No Node3D / display dependency.
class_name Config
extends RefCounted

# --- tuning fields ---
var player_speed: float
var carry_capacity: int
var lantern_cost: int
var lantern_count_night1: int
var pickup_radius: float
var interact_radius: float
var pulse_cost: int
var pulse_radius: float
var night1_duration_s: float
var flames: int
var invuln_s: float
var hit_drop_ratio: float
var pulse_stun_s: float
var pulse_push_m: float
var pulse_cooldown_s: float
var safe_radius: float
var shade_speed: float
var shade_hit_radius: float
var fall_enabled: bool

# score sub-object
var score_per_mote: int
var score_per_lantern: int
var score_per_stun: int
var score_per_second_left: float
var score_per_flame_left: int

# raw contract fields (for game.contract.json output validation)
var contract_version: String
var team: String

static func load_from_file(path: String) -> Config:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Config: cannot open " + path)
		return null
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	var err := json.parse(txt)
	if err != OK:
		push_error("Config: JSON parse error in " + path)
		return null
	var d: Dictionary = json.get_data()
	var t: Dictionary = d.get("tuning", {})
	var c := Config.new()
	c.contract_version = d.get("contract_version", "")
	c.team             = d.get("team", "")
	c.player_speed        = float(t.get("player_speed", 5.0))
	c.carry_capacity      = int(t.get("carry_capacity", 5))
	c.lantern_cost        = int(t.get("lantern_cost", 3))
	c.lantern_count_night1 = int(t.get("lantern_count_night1", 5))
	c.pickup_radius       = float(t.get("pickup_radius", 1.5))
	c.interact_radius     = float(t.get("interact_radius", 2.5))
	c.pulse_cost          = int(t.get("pulse_cost", 1))
	c.pulse_radius        = float(t.get("pulse_radius", 5.0))
	c.night1_duration_s   = float(t.get("night1_duration_s", 300.0))
	c.flames              = int(t.get("flames", 3))
	c.invuln_s            = float(t.get("invuln_s", 1.5))
	c.hit_drop_ratio      = float(t.get("hit_drop_ratio", 0.5))
	c.pulse_stun_s        = float(t.get("pulse_stun_s", 3.0))
	c.pulse_push_m        = float(t.get("pulse_push_m", 4.0))
	c.pulse_cooldown_s    = float(t.get("pulse_cooldown_s", 5.0))
	c.safe_radius         = float(t.get("safe_radius", 4.0))
	c.shade_speed         = float(t.get("shade_speed", 3.0))
	c.shade_hit_radius    = float(t.get("shade_hit_radius", 1.0))
	c.fall_enabled        = bool(t.get("fall_enabled", false))
	var sc: Dictionary = t.get("score", {})
	c.score_per_mote        = int(sc.get("per_mote", 10))
	c.score_per_lantern     = int(sc.get("per_lantern", 100))
	c.score_per_stun        = int(sc.get("per_stun", 20))
	c.score_per_second_left = float(sc.get("per_second_left", 5.0))
	c.score_per_flame_left  = int(sc.get("per_flame_left", 50))
	return c
