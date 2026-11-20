# headless.gd — Thin entrypoint for headless mode.
# Invoked via: godot --headless --path . --script res://src/headless.gd -- [args]
# Parses OS.get_cmdline_user_args() and delegates to HeadlessRunner.
extends SceneTree

func _init() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	if args.has("__error"):
		quit(1)
		return
	var code := HeadlessRunner.run(args)
	quit(code)

func _parse_args(raw: PackedStringArray) -> Dictionary:
	var d := {
		"seed": 0,
		"night": 1,
		"ticks": 0,
		"out": "",
		"scenario_path": "",
		"inputs_path": "",
		"snapshot_every": 10
	}
	var has_ticks := false
	var i := 0
	while i < raw.size():
		match raw[i]:
			"--seed":
				i += 1
				if i >= raw.size(): return _err("--seed requires a value")
				if not raw[i].is_valid_int(): return _err("--seed must be an integer")
				d["seed"] = raw[i].to_int()
			"--night":
				i += 1
				if i >= raw.size(): return _err("--night requires a value")
				if not raw[i].is_valid_int(): return _err("--night must be an integer")
				d["night"] = raw[i].to_int()
			"--ticks":
				i += 1
				if i >= raw.size(): return _err("--ticks requires a value")
				if not raw[i].is_valid_int(): return _err("--ticks must be an integer")
				d["ticks"] = raw[i].to_int()
				has_ticks = true
			"--out":
				i += 1
				if i >= raw.size(): return _err("--out requires a value")
				d["out"] = raw[i]
			"--scenario":
				i += 1
				if i >= raw.size(): return _err("--scenario requires a value")
				d["scenario_path"] = raw[i]
			"--inputs":
				i += 1
				if i >= raw.size(): return _err("--inputs requires a value")
				d["inputs_path"] = raw[i]
			"--snapshot-every":
				i += 1
				if i >= raw.size(): return _err("--snapshot-every requires a value")
				if not raw[i].is_valid_int(): return _err("--snapshot-every must be an integer")
				d["snapshot_every"] = raw[i].to_int()
			_:
				printerr("headless.gd: unknown argument: " + raw[i])
				return _err("")
		i += 1

	if d["out"] == "":
		return _err("--out is required")
	if int(d["night"]) < 1 or int(d["night"]) > 3:
		return _err("--night must be 1, 2 or 3")
	if not has_ticks:
		return _err("--ticks is required")
	return d

func _err(msg: String) -> Dictionary:
	if msg != "":
		printerr("headless.gd: " + msg)
	printerr("Usage: godot --headless --path . --script res://src/headless.gd -- --seed <int> --night <int> --ticks <int> --out <file.jsonl> [--scenario <file.json>] [--inputs <file.json>] [--snapshot-every <int>]")
	return {"__error": true}
