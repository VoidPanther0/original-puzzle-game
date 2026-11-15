class_name Gravity
extends RefCounted
## Isolated, pure gravity rule.
##
## RULE: a cleared line (row or column) is removed; then every surviving block
## falls straight down to the bottom of its own column, filling every gap
## (classic per-column gravity). Columns never slide sideways. Because blocks
## fall to the bottom, a fall can create new full lines, so the game cascades
## (clear -> fall -> clear -> fall ...) until no full line remains. The rule
## lives here; the cascade loop lives in GameState.place_piece().


## Applies gravity in place to `cells` (row-major, size x size) after the rows
## in `cleared_rows` and the columns in `cleared_cols` have been removed.
## Returns a dictionary with:
##   "from": Array[Vector2i] - old cell of every block that moved
##   "to":   Array[Vector2i] - new cell of the same block
## Only blocks that actually moved are reported, so a view can animate them.
static func apply(cells: PackedInt32Array, size: int, cleared_rows: Array[int], cleared_cols: Array[int]) -> Dictionary:
	# Nothing to clear: leave the board untouched.
	if cleared_rows.is_empty() and cleared_cols.is_empty():
		var empty_from: Array[Vector2i] = []
		var empty_to: Array[Vector2i] = []
		return {"from": empty_from, "to": empty_to}

	var old_cells: PackedInt32Array = cells.duplicate()

	# Mark cleared cells.
	var cleared: Dictionary = {}
	for r: int in cleared_rows:
		for x: int in size:
			cleared["%d,%d" % [x, r]] = true
	for c: int in cleared_cols:
		for y: int in size:
			cleared["%d,%d" % [c, y]] = true

	var new_cells := PackedInt32Array()
	new_cells.resize(size * size)
	new_cells.fill(0)

	var from: Array[Vector2i] = []
	var to: Array[Vector2i] = []

	for x: int in size:
		# Collect surviving blocks in this column, top to bottom.
		var blocks: Array[int] = []
		var old_ys: Array[int] = []
		for y: int in size:
			if cleared.has("%d,%d" % [x, y]):
				continue
			var v: int = old_cells[y * size + x]
			if v != 0:
				blocks.append(v)
				old_ys.append(y)
		# Drop them to the bottom, preserving order.
		var start: int = size - blocks.size()
		for i: int in blocks.size():
			var ny: int = start + i
			new_cells[ny * size + x] = blocks[i]
			if old_ys[i] != ny:
				from.append(Vector2i(x, old_ys[i]))
				to.append(Vector2i(x, ny))

	for i: int in size * size:
		cells[i] = new_cells[i]

	return {"from": from, "to": to}
