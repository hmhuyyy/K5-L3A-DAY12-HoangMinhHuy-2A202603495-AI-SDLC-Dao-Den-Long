# soak.gd — entrypoint: godot --headless --path . --script res://src/soak.gd -- --seed 7 --nights 10 --out soak.json
extends SceneTree

const SoakRunner := preload("res://src/tools/SoakRunner.gd")

func _init() -> void:
	var seed_v := 7
	var nights := 10
	var out := ""
	var raw := OS.get_cmdline_user_args()
	var i := 0
	while i < raw.size():
		match raw[i]:
			"--seed":
				i += 1
				if i >= raw.size() or not raw[i].is_valid_int():
					return _bad("--seed requires an integer")
				seed_v = raw[i].to_int()
			"--nights":
				i += 1
				if i >= raw.size() or not raw[i].is_valid_int() or raw[i].to_int() < 1:
					return _bad("--nights requires a positive integer")
				nights = raw[i].to_int()
			"--out":
				i += 1
				if i >= raw.size():
					return _bad("--out requires a value")
				out = raw[i]
			_:
				return _bad("unknown argument: " + raw[i])
		i += 1
	if out == "":
		return _bad("--out is required")
	var cfg := Config.load_from_file("res://game.contract.json")
	if cfg == null:
		quit(1)
		return
	var res := SoakRunner.run(cfg, seed_v, nights, out)
	print("soak: nights=%d crashes=%d mem %s -> %s MB, %.1f s" % [
		res["nights"], res["crashes"], str(res["mem_start_mb"]), str(res["mem_end_mb"]), res["duration_s"]])
	quit(0)

func _bad(msg: String) -> void:
	printerr("soak.gd: " + msg)
	printerr("Usage: --seed <int> --nights <int> --out <file.json>")
	quit(1)
