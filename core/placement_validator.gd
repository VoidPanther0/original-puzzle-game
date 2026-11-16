class_name PlacementValidator
extends RefCounted
## Placement queries on top of Board. Anchors are Vector2i(x=col, y=row).

static func all_positions(board: Board, piece: Dictionary) -> Array:
	var out: Array = []
	for r in range(0, Board.SIZE - piece.h + 1):
		for c in range(0, Board.SIZE - piece.w + 1):
			if board.can_place(piece, r, c):
				out.append(Vector2i(c, r))
	return out

static func can_place_anywhere(board: Board, piece: Dictionary) -> bool:
	for r in range(0, Board.SIZE - piece.h + 1):
		for c in range(0, Board.SIZE - piece.w + 1):
			if board.can_place(piece, r, c):
				return true
	return false

## Nearest valid anchor to a fractional grid position (snap-to-grid). (-1,-1) if none in range.
static func snap(board: Board, piece: Dictionary, fr: float, fc: float, max_dist: float = 1.6) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := max_dist * max_dist
	var r0 := int(floor(fr)) - 2
	var c0 := int(floor(fc)) - 2
	for r in range(r0, r0 + 5):
		for c in range(c0, c0 + 5):
			if board.can_place(piece, r, c):
				var d := (r - fr) * (r - fr) + (c - fc) * (c - fc)
				if d <= best_d:
					best_d = d
					best = Vector2i(c, r)
	return best
