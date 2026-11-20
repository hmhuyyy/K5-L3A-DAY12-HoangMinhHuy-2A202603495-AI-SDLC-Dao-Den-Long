# JsonlWriter.gd — Writes JSONL records to the --out file.
# One complete JSON object per line, UTF-8, LF endings, no trailing whitespace.
class_name JsonlWriter
extends RefCounted

var _path: String
var _file: FileAccess

func _init(path: String) -> void:
	_path = path

func open() -> bool:
	_file = FileAccess.open(_path, FileAccess.WRITE)
	if _file == null:
		printerr("JsonlWriter: cannot open output file: " + _path)
		return false
	return true

func write_record(record: Dictionary) -> void:
	if _file == null:
		return
	var line := JSON.stringify(record)
	_file.store_line(line)  # appends '\n'

func close() -> void:
	if _file != null:
		_file.close()
		_file = null
