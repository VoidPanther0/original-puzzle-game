class_name GameState
extends RefCounted
## All gameplay rules. Owns the board, the tray of three pieces, score and
## combo. It knows nothing about nodes, input or animation.

signal score_changed(score: int)
signal combo_changed(combo: int)
signal tray_changed()
signal game_over()

const BOARD_SIZE: int = 8
const LINE_BASE_POINTS: int = 10

var board: BoardModel
var generator: PieceGenerator
var tray: Array[PieceData] = []
var score: int = 0
var combo: int = 0
var is_over: bool = false


func _init(seed_value: int = -1, p_board_size: int = BOARD_SIZE) -> void:
	board = BoardModel.new(p_board_size)
	generator = PieceGenerator.new(seed_value)
	new_game()


func new_game() -> void:
	board.clear_all()
	score = 0
	combo = 0
	is_over = false
	tray = generator.make_set(board)
	score_changed.emit(score)
	combo_changed.emit(combo)
	tray_changed.emit()


func can_place_piece(slot: int, origin: Vector2i) -> bool:
	if is_over or slot < 0 or slot >= tray.size() or tray[slot] == null:
		return false
	return board.can_place(tray[slot].shape, origin)


## Points for clearing `rows` rows at the given combo streak (combo >= 1).
static func clear_points(rows: int, combo_streak: int) -> int:
	return LINE_BASE_POINTS * rows * rows * maxi(1, combo_streak)


## Attempts to place the piece in `slot`. The result dictionary always has
## "ok". On success it also holds:
##   cells, color_id, cleared_rows, moves, points, combo,
##   board_before_clear (PackedInt32Array), refilled, game_over
func place_piece(slot: int, origin: Vector2i) -> Dictionary:
	if not can_place_piece(slot, origin):
		return {"ok": false}
	var piece: PieceData = tray[slot]
	board.place(piece.shape, piece.color_id, origin)

	var placed_cells: Array[Vector2i] = []
	for c: Vector2i in piece.shape:
		placed_cells.append(origin + c)

	var points: int = piece.cell_count()
	var before_clear: PackedInt32Array = board.cells.duplicate()
	var cleared: Array[int] = board.full_rows()
	var moves: Array[Vector2i] = []
	if cleared.is_empty():
		combo = 0
	else:
		combo += 1
		points += clear_points(cleared.size(), combo)
		moves = board.clear_rows(cleared)

	tray[slot] = null
	var refilled: bool = false
	if tray.all(func(p: PieceData) -> bool: return p == null):
		tray = generator.make_set(board)
		refilled = true

	score += points
	score_changed.emit(score)
	combo_changed.emit(combo)
	tray_changed.emit()

	if not has_any_move():
		is_over = true
		game_over.emit()

	return {
		"ok": true,
		"cells": placed_cells,
		"color_id": piece.color_id,
		"cleared_rows": cleared,
		"moves": moves,
		"points": points,
		"combo": combo,
		"board_before_clear": before_clear,
		"refilled": refilled,
		"game_over": is_over,
	}


## True if at least one remaining tray piece fits somewhere.
func has_any_move() -> bool:
	for piece: PieceData in tray:
		if piece != null and board.can_fit_anywhere(piece.shape):
			return true
	return false
