# InputsLoader.gd — Parses --inputs JSON file.
# Validates strictly increasing tick order.
# Sets _has_error=true on malformed JSON or bad tick order; caller exits 2.
class_name InputsLoader
extends RefCounted

var _frames: Array = []  # sorted array of frame dicts
var _frame_idx: int = 0
var _has_error: bool = false

static func load(path: String) -> InputsLoader:
	var loader := InputsLoader.new()
	if path.is_empty():
		return loader  # no file = player stands still
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		printerr("InputsLoader: cannot open file: " + path)
		loader._has_error = true
		return loader
	var txt := f.get_as_text()
	f.close()
	var json := JSON.new()
	var err := json.parse(txt)
	if err != OK:
		printerr("InputsLoader: JSON parse error in %s at line %d: %s" % [
			path, json.get_error_line(), json.get_error_message()])
		loader._has_error = true
		return loader
	var data = json.get_data()
	if not data is Dictionary or not data.has("frames"):
		printerr("InputsLoader: root must be {\"frames\":[...]} in " + path)
		loader._has_error = true
		return loader
	var frames: Array = data["frames"]
	# Validate strictly increasing ticks
	var last_tick := -1
	for frame in frames:
		if not frame is Dictionary or not frame.has("tick"):
			printerr("InputsLoader: each frame must have a 'tick' field")
			loader._has_error = true
			return loader
		var t := int(frame["tick"])
		if t <= last_tick:
			printerr("InputsLoader: frame ticks must be strictly increasing; got %d after %d" % [t, last_tick])
			loader._has_error = true
			return loader
		last_tick = t
	loader._frames = frames
	return loader

# Returns the frame dict for tick k, or null if none.
func get_frame_for_tick(k: int) -> Variant:
	# Advance index to find the frame exactly matching tick k.
	while _frame_idx < _frames.size():
		var t := int(_frames[_frame_idx]["tick"])
		if t == k:
			var f = _frames[_frame_idx]
			_frame_idx += 1
			return f
		elif t > k:
			return null
		else:
			_frame_idx += 1
	return null
