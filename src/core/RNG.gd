# RNG.gd — Single deterministic random source.
# One RandomNumberGenerator, seeded once. All randomness goes through here.
# No bare randf()/randi() anywhere else.
class_name SimRNG
extends RefCounted

var _rng := RandomNumberGenerator.new()
var _mote_counter := 0
var _shade_counter := 0

func seed_rng(s: int) -> void:
	# Normalize seed: Godot RNG accepts any int; map negative/zero to positive range.
	var seed_val := s if s != 0 else 1
	if seed_val < 0:
		seed_val = -seed_val
	_rng.seed = seed_val
	_rng.state = seed_val

func randf() -> float:
	return _rng.randf()

func randf_range(lo: float, hi: float) -> float:
	return _rng.randf_range(lo, hi)

func randi() -> int:
	return _rng.randi()

func randi_range(lo: int, hi: int) -> int:
	return _rng.randi_range(lo, hi)

# Deterministic auto-ID generators.
func next_mote_id() -> String:
	_mote_counter += 1
	return "M%d" % _mote_counter

func next_shade_id() -> String:
	_shade_counter += 1
	return "S%d" % _shade_counter

func reset_counters() -> void:
	_mote_counter = 0
	_shade_counter = 0
