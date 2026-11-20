# Entities.gd — Pure data structs for all game entities.
# No Node3D, no display dependency.
class_name Entities
extends RefCounted

# ── Player ──────────────────────────────────────────────────
class PlayerData extends RefCounted:
	var pos: Vector3 = Vector3.ZERO  # foot position; Y used for jump
	var flames: int = 3              # health
	var carried: int = 0             # motes held
	var invuln_ticks: int = 0        # remaining invulnerability ticks
	# Jump state
	var jump_tick: int = -1          # tick the jump started; -1 = grounded

	func is_airborne() -> bool:
		return jump_tick >= 0

	# Y offset at a given tick since jump start (parabola, peak at 24 ticks)
	# height = 1.5 m, duration = 48 ticks
	static func jump_y(ticks_since_start: int) -> float:
		const H := 1.5
		const HALF := 24.0
		var t := float(ticks_since_start)
		# parabola: y = H * (1 - ((t - HALF)/HALF)^2)
		var rel := (t - HALF) / HALF
		return max(0.0, H * (1.0 - rel * rel))

# ── Lantern ──────────────────────────────────────────────────
class LanternData extends RefCounted:
	var id: String
	var pos: Vector3
	var deposited: int = 0
	var lit: bool = false

# ── Mote ─────────────────────────────────────────────────────
class MoteData extends RefCounted:
	var id: String
	var pos: Vector3   # ground point; Y cosmetic only in display
	var active: bool = true

# ── Shade ────────────────────────────────────────────────────
class ShadeData extends RefCounted:
	var id: String
	var pos: Vector3
	var stun_ticks: int = 0   # remaining stun duration

	func state_string() -> String:
		return "stunned" if stun_ticks > 0 else "chase"
