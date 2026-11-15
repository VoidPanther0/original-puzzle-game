class_name Gravity
extends RefCounted
## Isolated, pure gravity rule.
##
## RULE: after full rows are removed, every remaining row keeps its contents
## and drops down so that no removed row remains below it. Rows are moved as
## whole units (row compaction), so the shape of everything left on the board
## is preserved exactly. Row contents never change, so gravity can never
## create a new full row (no cascades).


## Applies gravity in place to `cells` (row-major, size x size) after the rows
## listed in `cleared_rows` are removed. Returns the list of rows that moved as
## Vector2i(from_row, to_row), ordered bottom to top. Empty rows are not
## reported, because there is nothing to animate.
static func apply(cells: PackedInt32Array, size: int, cleared_rows: Array[int]) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var write_row: int = size - 1
	for read_row: int in range(size - 1, -1, -1):
		if cleared_rows.has(read_row):
			continue
		if read_row != write_row:
			var row_has_blocks: bool = false
			for x: int in size:
				var value: int = cells[read_row * size + x]
				cells[write_row * size + x] = value
				if value != 0:
					row_has_blocks = true
			if row_has_blocks:
				moves.append(Vector2i(read_row, write_row))
		write_row -= 1
	# Everything above the compacted stack is now empty.
	for row: int in range(write_row, -1, -1):
		for x: int in size:
			cells[row * size + x] = 0
	return moves
