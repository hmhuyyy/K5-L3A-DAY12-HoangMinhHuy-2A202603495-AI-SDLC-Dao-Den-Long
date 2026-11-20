# ScenarioLoader.gd — Parses --scenario JSON file into a Dictionary.
# Returns {} on missing file (use game defaults).
# Returns {"__error": true} on malformed JSON — caller must check and exit 2.
class_name ScenarioLoader
extends RefCounted

static func load(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		printerr("ScenarioLoader: cannot open file: " + path)
		return {"__error": true}
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	var err := json.parse(txt)
	if err != OK:
		printerr("ScenarioLoader: JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()])
		return {"__error": true}
	var data = json.get_data()
	if not data is Dictionary:
		printerr("ScenarioLoader: root must be a JSON object: " + path)
		return {"__error": true}
	return data
