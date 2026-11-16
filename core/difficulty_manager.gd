class_name DifficultyManager
extends RefCounted
## Chooses which generation algorithm to use for each tray slot based on difficulty (0..1) and
## current board pressure.

## Returns {algo_name: weight} for the situation.
static func algorithm_weights(fill: float, difficulty: float) -> Dictionary:
	var d := clampf(difficulty, 0.0, 1.0)
	var w := {
		"random_no_die": 3.0,
		"can_put": 2.0,
		"fill_weight": 1.5,
		"fill_sort": 1.0 + (1.0 - d),
		"clear": 1.0 + (1.0 - d) * 2.0,
		"score": 0.5,
		"hole_max_diff": 0.5 + d,
		"avoid_clear_board": 0.2 + d * 1.5,
		"new_clear_board": 0.3,
		"deal_death_state": 0.5,
	}
	if fill > 0.55:     # board under pressure: help the player
		w["deal_death_state"] = 4.0 + (1.0 - d) * 3.0
		w["clear"] = float(w["clear"]) * 2.0
		w["avoid_clear_board"] = 0.0
		w["hole_max_diff"] = float(w["hole_max_diff"]) * 2.0
	if fill < 0.15:
		w["new_clear_board"] = 0.0
		w["clear"] = 0.0
	return w

static func pick(rng: RandomNumberGenerator, fill: float, difficulty: float) -> String:
	var w := algorithm_weights(fill, difficulty)
	var total := 0.0
	for k in w: total += float(w[k])
	var roll := rng.randf() * total
	for k in w:
		roll -= float(w[k])
		if roll <= 0.0 and float(w[k]) > 0.0: return k
	return "random_no_die"

## Difficulty 0..1 for a given endless-mode score (gently ramps up).
static func difficulty_for_score(score: int) -> float:
	return clampf(float(score) / 3000.0, 0.0, 1.0)
