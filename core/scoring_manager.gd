class_name ScoringManager
extends RefCounted
## Configurable scoring. Combo = consecutive moves that cleared >= 1 line.

var cfg := {
	"per_cell": 1,
	"per_line": 10,
	"multi_line_bonus": [0, 0, 10, 30, 60, 100, 150, 210, 280, 360],
	"combo_step": 0.5,
	"combo_max": 8,
	"clear_board_bonus": 100,
}

var score := 0
var combo := 0
var best_combo := 0
var lines_cleared := 0

func reset() -> void:
	score = 0
	combo = 0
	best_combo = 0
	lines_cleared = 0

func combo_multiplier(level: int) -> float:
	if level <= 1: return 1.0
	return 1.0 + float(cfg.combo_step) * float(mini(level, int(cfg.combo_max)) - 1)

## Applies one placement. Returns {gained, placement, clear, multiplier, combo}.
func apply_move(cells_placed: int, lines: int, board_cleared: bool = false) -> Dictionary:
	var placement: int = cells_placed * int(cfg.per_cell)
	var clear_pts := 0
	var mult := 1.0
	if lines > 0:
		combo += 1
		best_combo = maxi(best_combo, combo)
		mult = combo_multiplier(combo)
		var bonus_arr: Array = cfg.multi_line_bonus
		var bonus: int = int(bonus_arr[mini(lines, bonus_arr.size() - 1)])
		clear_pts = int(round((lines * int(cfg.per_line) + bonus) * mult))
		if board_cleared:
			clear_pts += int(cfg.clear_board_bonus)
		lines_cleared += lines
	else:
		combo = 0
	var gained := placement + clear_pts
	score += gained
	return {"gained": gained, "placement": placement, "clear": clear_pts, "multiplier": mult, "combo": combo}
