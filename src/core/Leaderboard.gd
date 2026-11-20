# Leaderboard.gd — local top-10 leaderboard (TICKET-04 §3.3). Pure data + disk I/O, corrupt-file safe.
class_name Leaderboard
extends RefCounted

const DEFAULT_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10
const NAME_MIN := 3
const NAME_MAX := 12

# Name: 3–12 chars of [A-Za-z0-9_].
static func validate_name(player_name: Variant) -> bool:
	if not (player_name is String):
		return false
	var n: String = player_name
	if n.length() < NAME_MIN or n.length() > NAME_MAX:
		return false
	for i in range(n.length()):
		var c := n.unicode_at(i)
		var okc := (c >= 48 and c <= 57) or (c >= 65 and c <= 90) or (c >= 97 and c <= 122) or c == 95
		if not okc:
			return false
	return true

# ISO-8601 with timezone offset, e.g. 2026-11-20T20:43:12+07:00
static func now_iso() -> String:
	var bias_min: int = int(Time.get_time_zone_from_system().get("bias", 0))
	var dt := Time.get_datetime_string_from_system(false)  # local time "YYYY-MM-DDTHH:MM:SS"
	var sign := "+" if bias_min >= 0 else "-"
	var a := absi(bias_min)
	return "%s%s%02d:%02d" % [dt, sign, a / 60, a % 60]

# Parses ISO-8601 with offset to unix seconds; returns -1 when malformed.
static func iso_to_unix(iso: Variant) -> int:
	if not (iso is String):
		return -1
	var s: String = iso
	var re := RegEx.new()
	re.compile("^(\\d{4})-(\\d{2})-(\\d{2})T(\\d{2}):(\\d{2}):(\\d{2})(?:\\.\\d+)?(Z|[+-]\\d{2}:\\d{2})$")
	var m := re.search(s)
	if m == null:
		return -1
	var dict := {
		"year": int(m.get_string(1)), "month": int(m.get_string(2)), "day": int(m.get_string(3)),
		"hour": int(m.get_string(4)), "minute": int(m.get_string(5)), "second": int(m.get_string(6)),
	}
	if dict["month"] < 1 or dict["month"] > 12 or dict["day"] < 1 or dict["day"] > 31 \
			or dict["hour"] > 23 or dict["minute"] > 59 or dict["second"] > 59:
		return -1
	var unix := Time.get_unix_time_from_datetime_dict(dict)
	var tz := m.get_string(7)
	if tz != "Z":
		var off := int(tz.substr(1, 2)) * 3600 + int(tz.substr(4, 2)) * 60
		unix -= off if tz[0] == "+" else -off
	return unix

static func _is_whole(v: Variant) -> bool:
	return v is int or (v is float and not is_nan(v) and not is_inf(v) and v == floorf(v))

static func is_valid_entry(e: Variant) -> bool:
	if not (e is Dictionary):
		return false
	for k in ["name", "score", "nights_won", "achieved_at", "seed"]:
		if not e.has(k):
			return false
	if not validate_name(e["name"]):
		return false
	if not _is_whole(e["score"]) or int(e["score"]) < 0:
		return false
	if not _is_whole(e["nights_won"]) or int(e["nights_won"]) < 0 or int(e["nights_won"]) > 3:
		return false
	if not _is_whole(e["seed"]):
		return false
	return iso_to_unix(e["achieved_at"]) >= 0

# Builds a normalized entry; returns {} when the name is invalid.
static func make_entry(player_name: String, score: int, nights_won: int, seed_value: int, achieved_at: String = "") -> Dictionary:
	if not validate_name(player_name):
		return {}
	return {
		"name": player_name,
		"score": score,
		"nights_won": nights_won,
		"achieved_at": achieved_at if achieved_at != "" else now_iso(),
		"seed": seed_value,
	}

static func _normalize(e: Dictionary) -> Dictionary:
	return {
		"name": e["name"], "score": int(e["score"]), "nights_won": int(e["nights_won"]),
		"achieved_at": e["achieved_at"], "seed": int(e["seed"]),
	}

# Score descending; equal score -> earlier achieved_at first; still equal -> original order (stable).
static func sort_entries(entries: Array) -> Array:
	var idx: Array = []
	for i in range(entries.size()):
		idx.append({"e": entries[i], "i": i, "t": iso_to_unix(entries[i]["achieved_at"])})
	idx.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["e"]["score"] != b["e"]["score"]:
			return a["e"]["score"] > b["e"]["score"]
		if a["t"] != b["t"]:
			return a["t"] < b["t"]
		return a["i"] < b["i"])
	var out: Array = []
	for x: Dictionary in idx:
		out.append(x["e"])
	return out

static func ranked(entries: Array) -> Array:
	var s := sort_entries(entries)
	return s.slice(0, MAX_ENTRIES)

# Loads, validates (dropping bad entries), sorts, truncates to 10. Never throws; returns [] for a missing/corrupt file.
static func load_entries(path: String = DEFAULT_PATH) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return []
	var txt := f.get_as_text()
	f.close()
	var j := JSON.new()
	if j.parse(txt) != OK:
		return []
	var d: Variant = j.get_data()
	if not (d is Dictionary) or not (d.get("entries") is Array):
		return []
	var good: Array = []
	for e in d["entries"]:
		if is_valid_entry(e):
			good.append(_normalize(e))
	return ranked(good)

static func save_entries(entries: Array, path: String = DEFAULT_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"entries": ranked(entries)}, "  ") + "\n")
	f.close()
	return true

# Adds an entry (must be valid), keeps top 10, saves. Returns the new ranked list ([] if entry invalid).
static func add_entry(entry: Dictionary, path: String = DEFAULT_PATH) -> Array:
	if not is_valid_entry(entry):
		return []
	var list := load_entries(path)
	list.append(_normalize(entry))
	list = ranked(list)
	save_entries(list, path)
	return list

# `--export-leaderboard out.json`: writes {"entries": [...]} in ranking order. Returns true on success.
static func export_to(out_path: String, src_path: String = DEFAULT_PATH) -> bool:
	return save_entries(load_entries(src_path), out_path)
