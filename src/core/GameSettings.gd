# GameSettings.gd — persisted player settings: accessibility toggles + key bindings (TICKET-03 §9, TICKET-04 §3.4).
# Pure data + disk I/O. No display dependency (key names via OS only).
class_name GameSettings
extends RefCounted

const DEFAULT_PATH := "user://settings.json"
const VERSION := 1

# Action ids (stable, used in the JSON file).
const ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right", "jump", "dash", "interact", "pulse", "pause",
]
const ACTION_LABELS: Dictionary = {
	"move_up": "Đi lên", "move_down": "Đi xuống", "move_left": "Sang trái", "move_right": "Sang phải",
	"jump": "Nhảy", "dash": "Lướt", "interact": "Tương tác", "pulse": "Tỏa Sáng", "pause": "Tạm dừng",
}

var colorblind: bool = false      # "Bảng màu dễ phân biệt"
var reduce_motion: bool = false   # no camera shake, no screen flashing
var large_font: bool = false      # UI x1.25
var bindings: Dictionary = {}     # action -> physical keycode (int)

# Last problem found while loading (empty when the file was fine or absent).
var load_warning: String = ""

func _init() -> void:
	bindings = default_bindings()

static func default_bindings() -> Dictionary:
	return {
		"move_up": KEY_W, "move_down": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
		"jump": KEY_SPACE, "dash": KEY_SHIFT, "interact": KEY_E, "pulse": KEY_Q, "pause": KEY_ESCAPE,
	}

func reset_bindings() -> void:
	bindings = default_bindings()

# Returns the action that already uses `keycode` (other than `action`), or "".
func find_conflict(action: String, keycode: int) -> String:
	for a: String in ACTIONS:
		if a != action and int(bindings[a]) == keycode:
			return a
	return ""

# Rebind one action. Returns "" on success, or the conflicting action id (nothing changes).
# Unknown action / keycode <= 0 returns "invalid".
func rebind(action: String, keycode: int) -> String:
	if not ACTIONS.has(action) or keycode <= 0:
		return "invalid"
	var clash := find_conflict(action, keycode)
	if clash != "":
		return clash
	bindings[action] = keycode
	return ""

func key_of(action: String) -> int:
	return int(bindings.get(action, 0))

func key_label(action: String) -> String:
	return OS.get_keycode_string(key_of(action))

# UI font size for a base size: never below 18 px at 1280x720; x1.25 when large_font.
func font_size(base: int = 18) -> int:
	var b := maxi(base, 18)
	return int(round(b * (1.25 if large_font else 1.0)))

func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"colorblind": colorblind,
		"reduce_motion": reduce_motion,
		"large_font": large_font,
		"bindings": bindings.duplicate(),
	}

# Applies a parsed dictionary defensively; invalid fields keep their defaults.
func apply_dict(d: Dictionary) -> void:
	if d.get("colorblind") is bool: colorblind = d["colorblind"]
	if d.get("reduce_motion") is bool: reduce_motion = d["reduce_motion"]
	if d.get("large_font") is bool: large_font = d["large_font"]
	var b: Variant = d.get("bindings")
	if b is Dictionary:
		var cand := default_bindings()
		for a: String in ACTIONS:
			if b.has(a):
				var v: Variant = b[a]
				if (v is int or (v is float and v == floorf(v))) and int(v) > 0:
					cand[a] = int(v)
		# reject the whole binding set if it has duplicates (corrupt / hand-edited)
		var seen := {}
		var dup := false
		for a: String in ACTIONS:
			if seen.has(cand[a]):
				dup = true
			seen[cand[a]] = true
		if dup:
			load_warning = "bindings: duplicate keys, defaults restored"
		else:
			bindings = cand

static func load_from(path: String = DEFAULT_PATH) -> RefCounted:
	var s: RefCounted = (load("res://src/core/GameSettings.gd") as GDScript).new()
	if not FileAccess.file_exists(path):
		return s
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		s.load_warning = "cannot open settings"
		return s
	var txt := f.get_as_text()
	f.close()
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.get_data() is Dictionary):
		s.load_warning = "settings file corrupt, defaults used"
		return s
	s.apply_dict(j.get_data())
	return s

func save_to(path: String = DEFAULT_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), "  ") + "\n")
	f.close()
	return true
