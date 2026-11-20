# Config.gd — Single source of truth for tuning values (Contract v1.1).
# Loads game.contract.json once; exposes all tuning fields.
# No Node3D / display dependency.
class_name Config
extends RefCounted

# ── Movement ─────────────────────────────────────────────────
var player_speed: float          # 6.0 m/s  [REQ TICKET-02]
var player_accel_s: float        # <= 0.1 s to reach/stop [REQ TICKET-02]
var jump_vel_y: float            # 7.0 m/s  [REQ TICKET-02]
var gravity: float               # -20.0 m/s² [REQ TICKET-02]
var dash_speed: float            # 14.0 m/s [REQ TICKET-02]
var dash_duration_s: float       # 0.2 s    [REQ TICKET-02]
var dash_cooldown_s: float       # 1.5 s    [REQ TICKET-02]

# ── Mote ────────────────────────────────────────────────────
var carry_capacity: int          # 10        [REQ TICKET-02]
var pickup_radius: float         # 1.0 m     [REQ TICKET-02]
var pickup_height_m: float       # 1.5 m vertical tolerance [REQ TICKET-02]
var mote_initial_count: int      # 20        [REQ TICKET-02]
var mote_cap: int                # 30        [REQ TICKET-02]
var mote_spawn_interval_ticks: int # 240     [REQ TICKET-02]
var mote_drop_ttl_ticks: int     # 480 tick TTL for dropped motes [REQ TICKET-02]
var mote_drop_ring_min_m: float  # 1.5 m inner radius scatter  [REQ TICKET-02]
var mote_drop_ring_max_m: float  # 2.5 m outer radius scatter  [REQ TICKET-02]

# ── Lantern ──────────────────────────────────────────────────
var lantern_cost: int            # 10        [REQ TICKET-02]
var lantern_count_night1: int    # 5         [REQ both]
var interact_radius: float       # 2.0 m     [REQ TICKET-02]
var safe_radius: float           # 6.0 m     [REQ TICKET-02]
var safe_push_ticks: int         # 30 tick push-out [REQ TICKET-02]

# ── Pulse ────────────────────────────────────────────────────
var pulse_cost: int              # 3 motes   [REQ TICKET-02]
var pulse_radius: float          # 5.0 m     [REQ TICKET-02]
var pulse_center_height_m: float # 0.8 m above foot [REQ TICKET-02]
var pulse_stun_ticks: int        # 120 ticks [REQ TICKET-02]
var pulse_push_m: float          # 4.0 m total [REQ TICKET-02]
var pulse_push_ticks: int        # 15 ticks for push [REQ TICKET-02]
var pulse_cooldown_s: float      # 3.0 s     [REQ TICKET-02]

# ── Shade ────────────────────────────────────────────────────
var shade_speed: float           # 4.0 m/s   [REQ TICKET-02]
var shade_speed_night3: float    # 4.5 m/s   [REQ TICKET-02]
var shade_detect_m: float        # 12.0 m    [REQ TICKET-02]
var shade_abandon_m: float       # 18.0 m    [REQ TICKET-02]
var shade_hit_radius: float      # 1.0 m XZ  [REQ TICKET-02]
var shade_hit_height_m: float    # 1.5 m vertical [REQ TICKET-02]
var shade_recoil_m: float        # 2.0 m total [REQ TICKET-02]
var shade_recoil_ticks: int      # 60 ticks  [REQ TICKET-02]

# ── Night durations ──────────────────────────────────────────
var night1_duration_s: float     # 300 s     [REQ TICKET-02]
var night2_duration_s: float     # 330 s     [REQ TICKET-02]
var night3_duration_s: float     # 360 s     [REQ TICKET-02]

# ── Player health ────────────────────────────────────────────
var flames: int                  # 3         [REQ TICKET-02]
var invuln_ticks: int            # 90 ticks  [REQ TICKET-02]
var hit_drop_ratio: float        # 0.5 — floor(carried/2) [REQ TICKET-02]

# ── Fall ─────────────────────────────────────────────────────
var fall_enabled: bool           # true in v1.1 [REQ TICKET-02]
var fall_y_threshold: float      # -10.0 m   [REQ TICKET-02]
var fall_wait_ticks: int         # 60 ticks  [REQ TICKET-02]

# ── Charm (Bùa Gió) ──────────────────────────────────────────
var charm_duration_ticks: int    # 600 ticks [REQ TICKET-02]
var charm_speed: float           # 7.2 m/s   [REQ TICKET-02]
var charm_respawn_ticks: int     # 2700 ticks [REQ TICKET-02]

# ── Drifter (Gió Lạc) ────────────────────────────────────────
var drifter_speed_idle: float    # 2.0 m/s   [REQ TICKET-02]
var drifter_speed_chase: float   # 7.0 m/s   [REQ TICKET-02]
var drifter_speed_flee: float    # 7.0 m/s   [REQ TICKET-02]
var drifter_detect_m: float      # 15.0 m    [REQ TICKET-02]
var drifter_steal_ticks: int     # max motes stolen = 3 [REQ TICKET-02]
var drifter_steal_radius: float  # 1.2 m XZ  [REQ TICKET-02]
var drifter_flee_ticks: int      # 240 ticks [REQ TICKET-02]
var drifter_carried_min: int     # 5 motes threshold [REQ TICKET-02]

# ── Wind (Night 3) ───────────────────────────────────────────
var wind_cycle_ticks: int        # 1800 (30 s) [REQ TICKET-02]
var wind_warning_ticks: int      # 120 (2 s) [REQ + C5]
var wind_active_ticks: int       # 300 (5 s) [REQ TICKET-02]
var wind_speed: float            # 2.0 m/s   [REQ TICKET-02]

# ── Score ────────────────────────────────────────────────────
var score_per_mote_deposited: int   # 10 per DEPOSITED mote [REQ TICKET-02]
var score_per_lantern: int          # 100       [REQ TICKET-02]
var score_per_stun: int             # 5 per pulse hit [REQ TICKET-02]
var score_per_second_left_x2: int   # multiplier 2 for floor(s_left)*2 [REQ TICKET-02]
var score_per_flame_left: int       # 50        [REQ TICKET-02]

# raw contract fields
var contract_version: String
var team: String

# ── loader ───────────────────────────────────────────────────
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

	# Movement
	c.player_speed        = float(t.get("player_speed", 6.0))
	c.player_accel_s      = float(t.get("player_accel_s", 0.1))
	c.jump_vel_y          = float(t.get("jump_vel_y", 7.0))
	c.gravity             = float(t.get("gravity", -20.0))
	c.dash_speed          = float(t.get("dash_speed", 14.0))
	c.dash_duration_s     = float(t.get("dash_duration_s", 0.2))
	c.dash_cooldown_s     = float(t.get("dash_cooldown_s", 1.5))

	# Mote
	c.carry_capacity           = int(t.get("carry_capacity", 10))
	c.pickup_radius            = float(t.get("pickup_radius", 1.0))
	c.pickup_height_m          = float(t.get("pickup_height_m", 1.5))
	c.mote_initial_count       = int(t.get("mote_initial_count", 20))
	c.mote_cap                 = int(t.get("mote_cap", 30))
	c.mote_spawn_interval_ticks = int(t.get("mote_spawn_interval_ticks", 240))
	c.mote_drop_ttl_ticks      = int(t.get("mote_drop_ttl_ticks", 480))
	c.mote_drop_ring_min_m     = float(t.get("mote_drop_ring_min_m", 1.5))
	c.mote_drop_ring_max_m     = float(t.get("mote_drop_ring_max_m", 2.5))

	# Lantern
	c.lantern_cost         = int(t.get("lantern_cost", 10))
	c.lantern_count_night1 = int(t.get("lantern_count_night1", 5))
	c.interact_radius      = float(t.get("interact_radius", 2.0))
	c.safe_radius          = float(t.get("safe_radius", 6.0))
	c.safe_push_ticks      = int(t.get("safe_push_ticks", 30))

	# Pulse
	c.pulse_cost           = int(t.get("pulse_cost", 3))
	c.pulse_radius         = float(t.get("pulse_radius", 5.0))
	c.pulse_center_height_m = float(t.get("pulse_center_height_m", 0.8))
	c.pulse_stun_ticks     = int(t.get("pulse_stun_ticks", 120))
	c.pulse_push_m         = float(t.get("pulse_push_m", 4.0))
	c.pulse_push_ticks     = int(t.get("pulse_push_ticks", 15))
	c.pulse_cooldown_s     = float(t.get("pulse_cooldown_s", 3.0))

	# Shade
	c.shade_speed         = float(t.get("shade_speed", 4.0))
	c.shade_speed_night3  = float(t.get("shade_speed_night3", 4.5))
	c.shade_detect_m      = float(t.get("shade_detect_m", 12.0))
	c.shade_abandon_m     = float(t.get("shade_abandon_m", 18.0))
	c.shade_hit_radius    = float(t.get("shade_hit_radius", 1.0))
	c.shade_hit_height_m  = float(t.get("shade_hit_height_m", 1.5))
	c.shade_recoil_m      = float(t.get("shade_recoil_m", 2.0))
	c.shade_recoil_ticks  = int(t.get("shade_recoil_ticks", 60))

	# Night durations
	c.night1_duration_s = float(t.get("night1_duration_s", 300.0))
	c.night2_duration_s = float(t.get("night2_duration_s", 330.0))
	c.night3_duration_s = float(t.get("night3_duration_s", 360.0))

	# Player health
	c.flames         = int(t.get("flames", 3))
	c.invuln_ticks   = int(t.get("invuln_ticks", 90))
	c.hit_drop_ratio = float(t.get("hit_drop_ratio", 0.5))

	# Fall
	c.fall_enabled     = bool(t.get("fall_enabled", true))
	c.fall_y_threshold = float(t.get("fall_y_threshold", -10.0))
	c.fall_wait_ticks  = int(t.get("fall_wait_ticks", 60))

	# Charm
	c.charm_duration_ticks = int(t.get("charm_duration_ticks", 600))
	c.charm_speed          = float(t.get("charm_speed", 7.2))
	c.charm_respawn_ticks  = int(t.get("charm_respawn_ticks", 2700))

	# Drifter
	c.drifter_speed_idle    = float(t.get("drifter_speed_idle", 2.0))
	c.drifter_speed_chase   = float(t.get("drifter_speed_chase", 7.0))
	c.drifter_speed_flee    = float(t.get("drifter_speed_flee", 7.0))
	c.drifter_detect_m      = float(t.get("drifter_detect_m", 15.0))
	c.drifter_steal_ticks   = int(t.get("drifter_steal_ticks", 3))
	c.drifter_steal_radius  = float(t.get("drifter_steal_radius", 1.2))
	c.drifter_flee_ticks    = int(t.get("drifter_flee_ticks", 240))
	c.drifter_carried_min   = int(t.get("drifter_carried_min", 5))

	# Wind
	c.wind_cycle_ticks   = int(t.get("wind_cycle_ticks", 1800))
	c.wind_warning_ticks = int(t.get("wind_warning_ticks", 120))
	c.wind_active_ticks  = int(t.get("wind_active_ticks", 300))
	c.wind_speed         = float(t.get("wind_speed", 2.0))

	# Score
	var sc: Dictionary = t.get("score", {})
	c.score_per_mote_deposited  = int(sc.get("per_mote_deposited", 10))
	c.score_per_lantern         = int(sc.get("per_lantern", 100))
	c.score_per_stun            = int(sc.get("per_stun", 5))
	c.score_per_second_left_x2  = int(sc.get("per_second_left_x2", 2))
	c.score_per_flame_left      = int(sc.get("per_flame_left", 50))
	return c

# ── convenience: night duration by number ────────────────────
func night_duration_s(night: int) -> float:
	match night:
		1: return night1_duration_s
		2: return night2_duration_s
		3: return night3_duration_s
		_:
			push_error("Config.night_duration_s: unknown night %d" % night)
			return night1_duration_s

# ── convenience: shade speed by night ─────────────────────────
func night_shade_speed(night: int) -> float:
	return shade_speed_night3 if night == 3 else shade_speed
