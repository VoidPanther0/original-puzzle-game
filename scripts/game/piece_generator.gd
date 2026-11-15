class_name PieceGenerator
extends RefCounted
## Produces sets of three pieces. Seedable so tests are deterministic.

const SET_SIZE: int = 3
const FAIR_RETRIES: int = 12

var rng := RandomNumberGenerator.new()


func _init(seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func random_piece() -> PieceData:
	var pool: Array = PieceDefs.pool()
	var shape: Array[Vector2i] = pool[rng.randi_range(0, pool.size() - 1)]
	return PieceData.new(shape, rng.randi_range(1, PieceDefs.COLOR_COUNT))


## Makes a set of three. To keep the game fair, the set is re-rolled a limited
## number of times if none of its pieces would fit the board at all. A set
## that still cannot fit is allowed, so a truly full board still ends the game.
func make_set(board: BoardModel = null) -> Array[PieceData]:
	var result: Array[PieceData] = []
	for _attempt: int in FAIR_RETRIES:
		result.clear()
		for _i: int in SET_SIZE:
			result.append(random_piece())
		if board == null:
			return result
		for piece: PieceData in result:
			if board.can_fit_anywhere(piece.shape):
				return result
	return result
