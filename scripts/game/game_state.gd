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


## Points for clearing `lines` lines at the given combo streak (combo >= 1).
static func clear_points(lines: int, combo_streak: int) -> int:
	return LINE_BASE_POINTS * lines * lines * maxi(1, combo_streak)


## Attempts to place the piece in `slot`. The result dictionary always has
## "ok". On success it also holds:
##   cells, color_id, steps (Array of {cleared_rows, cleared_cols, moves,
##   before}), points, combo, board_before_clear, refilled, game_over
## Each entry in `steps` is one cascade: the lines that cleared and the
## gravity that followed. `moves` is {"from": Array[Vector2i],
## "to": Array[Vector2i]} for the blocks that moved in that step.
func place_piece(slot: int, origin: Vector2i) -> Dictionary:
	if not can_place_piece(slot, origin):
		return {"ok": false}
	var piece: PieceData = tray[slot]
	board.place(piece.shape, piece.color_id, origin)

	var placed_cells: Array[Vector2i] = []
	for c: Vector2i in piece.shape:
		placed_cells.append(origin + c)

	var points: int = piece.cell_count()
	var board_before_clear: PackedInt32Array = board.cells.duplicate()

	# Cascade: clear -> fall -> clear -> fall ... until no full line remains.
	var steps: Array[Dictionary] = []
	var combo_before: int = combo
	var combo_streak: int = combo_before
	var any_clear: bool = true
	while any_clear:
		var cleared: Array[int] = board.full_rows()
		var cleared_cols: Array[int] = board.full_columns()
		if cleared.is_empty() and cleared_cols.is_empty():
			any_clear = false
			break
		any_clear = true
		combo_streak += 1
		var lines: int = cleared.size() + cleared_cols.size()
		points += clear_points(lines, combo_streak)
		var before: PackedInt32Array = board.cells.duplicate()
		var moves: Dictionary = board.clear_lines(cleared, cleared_cols)
		var after: PackedInt32Array = board.cells.duplicate()
		steps.append({
			"cleared_rows": cleared,
			"cleared_cols": cleared_cols,
			"moves": moves,
			"before": before,
			"after": after,
		})

	if steps.is_empty():
		combo = 0
	else:
		combo = combo_streak

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

	# Backward-compatible top-level keys (first cascade step, if any).
	var first_cleared: Array[int] = []
	var first_cleared_cols: Array[int] = []
	var first_moves: Dictionary = {}
	if not steps.is_empty():
		var first_step: Dictionary = steps[0]
		first_cleared = first_step["cleared_rows"]
		first_cleared_cols = first_step["cleared_cols"]
		first_moves = first_step["moves"]

	return {
		"ok": true,
		"cells": placed_cells,
		"color_id": piece.color_id,
		"steps": steps,
		"cleared_rows": first_cleared,
		"cleared_cols": first_cleared_cols,
		"moves": first_moves,
		"points": points,
		"combo": combo,
		"board_before_clear": board_before_clear,
		"refilled": refilled,
		"game_over": is_over,
	}


## True if at least one remaining tray piece fits somewhere.
func has_any_move() -> bool:
	for piece: PieceData in tray:
		if piece != null and board.can_fit_anywhere(piece.shape):
			return true
	return false
