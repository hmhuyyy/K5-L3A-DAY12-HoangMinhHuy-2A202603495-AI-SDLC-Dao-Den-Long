# CampaignController.gd — multi-night campaign state (Nights 1 -> 2 -> 3). Pure logic, no display.
# Campaign score = sum of the scores of the Nights WON (a lost Night adds nothing).
class_name CampaignController
extends RefCounted

const LAST_NIGHT := 3

var seed_value: int = 1
var current_night: int = 1
var campaign_score: int = 0
var nights_won: int = 0
var finished: bool = false
var victory: bool = false   # true only after winning Night 3

func _init(p_seed: int = 1) -> void:
	seed_value = p_seed

# Deterministic seed for the Night about to be played.
func night_seed() -> int:
	return seed_value + (current_night - 1)

# Reports the terminal state of the current Night ("won" | "lost") with its Night score.
# Returns "next_night", "victory" or "defeat".
func report_night(result: String, night_score: int) -> String:
	if finished:
		return "victory" if victory else "defeat"
	if result == "won":
		campaign_score += night_score
		nights_won += 1
		if current_night >= LAST_NIGHT:
			finished = true
			victory = true
			return "victory"
		current_night += 1
		return "next_night"
	finished = true
	victory = false
	return "defeat"
