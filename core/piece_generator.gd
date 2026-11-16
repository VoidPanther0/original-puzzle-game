class_name PieceGenerator
extends RefCounted
## Deterministic (seeded) tray generation. Same seed + same board history => same pieces.

var rng := RandomNumberGenerator.new()
var pool: Array = []          # piece dictionaries allowed
var difficulty := 0.2
var guarantee_playable := true

func _init(seed_value: int = 0, pool_ids: Array = []) -> void:
	rng.seed = seed_value
	set_pool(pool_ids)

func set_pool(pool_ids: Array) -> void:
	pool.clear()
	if pool_ids.is_empty():
		pool = PieceDB.all().duplicate()
	else:
		for id in pool_ids:
			var p := PieceDB.get_piece(str(id))
			if not p.is_empty(): pool.append(p)
		if pool.is_empty(): pool = PieceDB.all().duplicate()

## Generates `count` pieces. Guarantees (when possible) that at least one piece can be placed.
func generate_tray(board: Board, count: int = 3) -> Array:
	var fill := BoardEvaluator.fill_ratio(board)
	var tray: Array = []
	if rng.randf() < 0.25 + 0.2 * (1.0 - difficulty) and count == 3 and fill < 0.55:
		tray = Algorithms.entropy3_medium(board, pool, rng)
	else:
		for _i in count:
			var algo := DifficultyManager.pick(rng, fill, difficulty)
			var p := Algorithms.select(algo, board, pool, rng)
			if p.is_empty():
				p = Algorithms.random_no_die(board, pool, rng)
			tray.append(p)
	if guarantee_playable and DeathDetector.is_dead(board, tray):
		var fit := Algorithms._fitting(board, pool)
		if not fit.is_empty():
			tray[rng.randi_range(0, tray.size() - 1)] = Algorithms._weighted(fit, rng)
	return tray

func single(board: Board) -> Dictionary:
	return Algorithms.random_no_die(board, pool, rng)
