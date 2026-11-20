# HeadlessRunner.gd — Drives GameSim, writes JSONL, enforces exit codes.
# Returns int exit code: 0 = success, 1 = error, 2 = bad format.
# caller (headless.gd) is responsible for calling quit(code).
class_name HeadlessRunner
extends RefCounted

static func run(args: Dictionary) -> int:
	# --- Load config (single source of truth) ---
	var cfg := Config.load_from_file("res://game.contract.json")
	if cfg == null:
		printerr("HeadlessRunner: failed to load res://game.contract.json")
		return 1

	# --- Open output file ---
	var writer := JsonlWriter.new(args["out"])
	if not writer.open():
		return 1

	# --- Load scenario and inputs ---
	var scenario := ScenarioLoader.load(args.get("scenario_path", ""))
	if scenario.has("__error"):
		return 2
	var inputs_loader := InputsLoader.load(args.get("inputs_path", ""))
	if inputs_loader._has_error:
		return 2

	# --- Init simulation ---
	var sim := GameSim.new()
	sim.init(cfg, int(args["seed"]), int(args["night"]), scenario)

	var n_ticks: int = int(args["ticks"])
	var snap_every: int = int(args.get("snapshot_every", 10))

	# --- Tick-0 snapshot (after setup, before inputs) ---
	writer.write_record(sim.snapshot())

	# --- Simulation loop ---
	var input_state := InputState.new()

	for k in range(n_ticks):
		# Capture prev-state BEFORE applying new frame, so edge detection sees
		# the transition from the previous tick's value to this tick's value.
		input_state.advance_prev()

		# Apply frame for tick k (if any)
		var frame = inputs_loader.get_frame_for_tick(k)
		if frame != null:
			input_state.apply_frame(frame)

		# Tick the simulation (advance_prev must NOT be called again inside tick)
		var bus := sim.tick(input_state)

		# Write events immediately
		for ev in bus.drain():
			writer.write_record(ev)

		# Write periodic snapshot (tick 0 already written above)
		var current_tick: int = sim.executed_ticks
		if snap_every > 0 and current_tick % snap_every == 0:
			writer.write_record(sim.snapshot())

		# Stop early on win/loss
		if sim.state != "playing":
			break

	# --- Mandatory end record (always last) ---
	writer.write_record({
		"type": "end",
		"ticks": sim.executed_ticks,
		"state": sim.state,
		"score": sim.score
	})

	writer.close()
	return 0
