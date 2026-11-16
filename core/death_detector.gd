class_name DeathDetector
extends RefCounted
## Game over = no remaining tray piece can be placed at ANY position.

static func is_dead(board: Board, pieces: Array) -> bool:
	for piece in pieces:
		if piece == null: continue
		if PlacementValidator.can_place_anywhere(board, piece):
			return false
	return true

## Number of tray pieces that currently have at least one legal position.
static func playable_count(board: Board, pieces: Array) -> int:
	var n := 0
	for piece in pieces:
		if piece != null and PlacementValidator.can_place_anywhere(board, piece):
			n += 1
	return n
