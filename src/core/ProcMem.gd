# ProcMem.gd — process memory (RSS / working set) in MB. No fakes: returns -1.0 when unavailable.
class_name ProcMem
extends RefCounted

static func _parse_kb(status: String, key: String) -> float:
	for line in status.split("\n"):
		if line.begins_with(key + ":"):
			var parts := line.substr(key.length() + 1).strip_edges().split(" ", false)
			if parts.size() > 0:
				return float(parts[0]) / 1024.0
	return -1.0

# Current resident / working-set size in MB.
static func rss_mb() -> float:
	match OS.get_name():
		"Windows":
			var out: Array = []
			var code := OS.execute("powershell", ["-NoProfile", "-Command",
				"(Get-Process -Id %d).WorkingSet64" % OS.get_process_id()], out)
			if code == 0 and out.size() > 0:
				return float(str(out[0]).strip_edges()) / 1048576.0
		"Linux", "Android":
			var f := FileAccess.open("/proc/self/status", FileAccess.READ)
			if f != null:
				return _parse_kb(f.get_as_text(), "VmRSS")
		"macOS":
			var out2: Array = []
			var code2 := OS.execute("ps", ["-o", "rss=", "-p", str(OS.get_process_id())], out2)
			if code2 == 0 and out2.size() > 0:
				return float(str(out2[0]).strip_edges()) / 1024.0
	return -1.0

# Peak resident / working-set size of the process so far, in MB.
static func peak_mb() -> float:
	match OS.get_name():
		"Windows":
			var out: Array = []
			var code := OS.execute("powershell", ["-NoProfile", "-Command",
				"(Get-Process -Id %d).PeakWorkingSet64" % OS.get_process_id()], out)
			if code == 0 and out.size() > 0:
				return float(str(out[0]).strip_edges()) / 1048576.0
		"Linux", "Android":
			var f := FileAccess.open("/proc/self/status", FileAccess.READ)
			if f != null:
				return _parse_kb(f.get_as_text(), "VmHWM")
	return rss_mb()
