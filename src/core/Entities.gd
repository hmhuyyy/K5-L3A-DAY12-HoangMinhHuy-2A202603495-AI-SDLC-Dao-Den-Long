# Entities.gd — Pure data structs for all game entities (Phase 2).
# No Node3D, no display dependency.
class_name Entities
extends RefCounted

const SHADE_SPAWNING := "spawning"
const SHADE_WANDER := "wander"
const SHADE_CHASE := "chase"
const SHADE_RECOIL := "recoil"
const SHADE_STUNNED := "stunned"
const SHADE_DRAIN := "drain"  # Phase 3 (defined here for forward compat)

const DRIFTER_IDLE := "idle"
const DRIFTER_CHASE := "chase"
const DRIFTER_FLEE := "flee"
const DRIFTER_REMOVED := "removed"

const MOTE_RANDOM := "random"
const MOTE_DROPPED := "dropped"

# ── Player ──────────────────────────────────────────────────
class PlayerData extends RefCounted:
	var pos: Vector3 = Vector3.ZERO
	var vel: Vector3 = Vector3.ZERO       # Phase 2: velocity-based physics
	var flames: int = 3
	var carried: int = 0
	var capacity: int = 10                # Phase 2: grows with successful_lights
	var invuln_ticks: int = 0
	var grounded: bool = true
	# Jump: vel.y set when jump; grounded clears airborne
	# Dash
	var dash_cd_ticks: int = 0            # remaining cooldown
	var dash_ticks_left: int = 0          # remaining dash duration
	var dash_dir: Vector2 = Vector2.ZERO # XZ direction of current dash
	# Pulse cooldown (ticks)
	var pulse_cd_ticks: int = 0
	# Charm
	var charm_ticks: int = 0             # remaining charm effect; 0 = none
	# Fall
	var falling: bool = false             # currently in fall-wait state
	var fall_wait_ticks: int = 0          # ticks remaining before respawn
	# Bounce pad ballistic lock
	var ballistic: bool = false            # true = horizontal vel locked from pad
	var _ballistic_hvel: Vector2 = Vector2.ZERO  # horizontal vel from pad
	# Facing direction (for dash when idle)
	var facing: Vector2 = Vector2(0.0, 1.0)  # default +Z
	# Phase 3: successful lights (capacity growth)
	var successful_lights: int = 0

# ── Lantern ──────────────────────────────────────────────────
class LanternData extends RefCounted:
	var id: String
	var pos: Vector3
	var deposited: int = 0
	var lit: bool = false
	# Phase 3 fuel fields (defined here, used in Phase 3):
	var fuel_units: int = 0       # internal: fuel * 60; 0 when unlit, 6000 when full
	var ever_lit: bool = false
	var relit_count: int = 0

# ── Mote ─────────────────────────────────────────────────────
class MoteData extends RefCounted:
	var id: String
	var pos: Vector3
	var active: bool = true
	var kind: String = "random"    # "random" or "dropped"
	var ttl_ticks: int = 0         # only for dropped motes; 0 = no TTL

# ── Shade ────────────────────────────────────────────────────
class ShadeData extends RefCounted:
	var id: String
	var pos: Vector3
	var state: String = "spawning"
	var state_ticks_left: int = 0    # ticks remaining in current temp state
	var previous_state: String = ""  # state to restore after temp state ends
	var target_lantern_id: String = ""  # Phase 3: drain target

	func state_string() -> String:
		return state

# ── Drifter (Gió Lạc) ─────────────────────────────────────────
class DrifterData extends RefCounted:
	var id: String
	var pos: Vector3
	var state: String = "idle"     # idle | chase | flee | removed
	var stolen: int = 0             # motes currently stolen
	var heading_deg: float = 0.0   # idle movement heading
	var state_ticks_left: int = 0  # ticks left for flee; 0 = indefinite
	var has_stolen: bool = false   # whether this drifter has stolen at least once

# ── Charm (Bùa Gió) ──────────────────────────────────────────
class CharmData extends RefCounted:
	var id: String
	var pos: Vector3
	var available: bool = true      # can be picked up
	var respawn_ticks_left: int = 0  # ticks until respawn; 0 = available or respawning
	var active_ticks_left: int = 0  # ticks of effect remaining on player; 0 = none
