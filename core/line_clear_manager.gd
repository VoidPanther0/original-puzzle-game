class_name LineClearManager
extends RefCounted
## Detects and clears completed rows/columns simultaneously. Intersections count once.

## Does not mutate. Returns {rows, cols, cells (unique indices), lines}.
static func detect(board: Board) -> Dictionary:
	var rows := board.full_rows()
	var cols := board.full_cols()
	var set := {}
	for r in rows:
		for c in Board.SIZE: set[r * Board.SIZE + c] = true
	for c in cols:
		for r in Board.SIZE: set[r * Board.SIZE + c] = true
	return {"rows": rows, "cols": cols, "cells": set.keys(), "lines": rows.size() + cols.size()}

## Clears all detected lines at once. Result also has "colors" (idx -> color before clear).
static func clear(board: Board) -> Dictionary:
	var res := detect(board)
	var colors := {}
	for i in res.cells:
		colors[i] = board.cells[i]
		board.cells[i] = 0
	res["colors"] = colors
	return res

## Simulates a placement on a copy and reports the lines it would complete.
static func preview(board: Board, piece: Dictionary, row: int, col: int) -> Dictionary:
	var b := board.copy()
	if not b.place(piece, row, col):
		return {"rows": [], "cols": [], "cells": [], "lines": 0}
	return detect(b)

## GRAVITY: every block falls straight down its column until it rests on the floor or another block.
## `origin` (optional, size 64) tracks where each currently-placed cell started (for animations).
## Returns true if anything moved.
static func gravity(board: Board, origin: PackedInt32Array = PackedInt32Array()) -> bool:
	var moved := false
	for c in Board.SIZE:
		var write := Board.SIZE - 1
		for r in range(Board.SIZE - 1, -1, -1):
			var v := board.cells[r * Board.SIZE + c]
			if v == 0: continue
			if r != write:
				board.cells[write * Board.SIZE + c] = v
				board.cells[r * Board.SIZE + c] = 0
				if origin.size() == Board.CELLS:
					origin[write * Board.SIZE + c] = origin[r * Board.SIZE + c]
					origin[r * Board.SIZE + c] = -1
				moved = true
			write -= 1
	return moved

## Clear -> gravity -> re-check, repeated until no line is complete (chain / cascade).
## With `gravity_first` the board is settled before the first check (used after a hammer).
## Result: lines (total over all rounds), rounds, rows/cols (first round), cells (ORIGINAL indices of
## every cleared cell), colors (original idx -> colour), falls [{from, to, color}] for animation.
static func resolve(board: Board, gravity_first: bool = false) -> Dictionary:
	var origin := PackedInt32Array()
	origin.resize(Board.CELLS)
	for i in Board.CELLS:
		origin[i] = i if board.cells[i] != 0 else -1
	var colors := {}
	var total := 0
	var rounds := 0
	var first_rows: Array = []
	var first_cols: Array = []
	if gravity_first: gravity(board, origin)
	while true:
		var det := detect(board)
		if int(det.lines) == 0: break
		if rounds == 0:
			first_rows = det.rows
			first_cols = det.cols
		total += int(det.lines)
		rounds += 1
		for i in det.cells:
			colors[origin[i]] = board.cells[i]
			board.cells[i] = 0
			origin[i] = -1
		gravity(board, origin)
	var falls: Array = []
	for i in Board.CELLS:
		if board.cells[i] != 0 and origin[i] != i:
			falls.append({"from": origin[i], "to": i, "color": board.cells[i]})
	return {"rows": first_rows, "cols": first_cols, "cells": colors.keys(), "lines": total,
		"rounds": rounds, "colors": colors, "falls": falls}
