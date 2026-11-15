class_name BoardModel
extends RefCounted
## Pure board data and rules. No nodes, no drawing, no animation.
## cells[y * size + x] == 0 means empty, otherwise the colour id of the block.

var size: int
var cells: PackedInt32Array = PackedInt32Array()


func _init(p_size: int = 8) -> void:
	size = p_size
	cells.resize(size * size)
	cells.fill(0)


func clear_all() -> void:
	cells.fill(0)


func duplicate_model() -> BoardModel:
	var copy := BoardModel.new(size)
	copy.cells = cells.duplicate()
	return copy


func get_cell(x: int, y: int) -> int:
	return cells[y * size + x]


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < size and y < size


func is_empty() -> bool:
	for v: int in cells:
		if v != 0:
			return false
	return true


func can_place(shape: Array[Vector2i], origin: Vector2i) -> bool:
	for c: Vector2i in shape:
		var x: int = origin.x + c.x
		var y: int = origin.y + c.y
		if not in_bounds(x, y) or cells[y * size + x] != 0:
			return false
	return true


## Places the shape. Returns false (and changes nothing) if it does not fit.
func place(shape: Array[Vector2i], color_id: int, origin: Vector2i) -> bool:
	if not can_place(shape, origin):
		return false
	for c: Vector2i in shape:
		cells[(origin.y + c.y) * size + origin.x + c.x] = color_id
	return true


func can_fit_anywhere(shape: Array[Vector2i]) -> bool:
	for y: int in size:
		for x: int in size:
			if can_place(shape, Vector2i(x, y)):
				return true
	return false


func full_rows() -> Array[int]:
	var rows: Array[int] = []
	for y: int in size:
		var full: bool = true
		for x: int in size:
			if cells[y * size + x] == 0:
				full = false
				break
		if full:
			rows.append(y)
	return rows


## The columns that are completely filled.
func full_columns() -> Array[int]:
	var columns: Array[int] = []
	for x: int in size:
		var full: bool = true
		for y: int in size:
			if cells[y * size + x] == 0:
				full = false
				break
		if full:
			columns.append(x)
	return columns


## Removes the given rows and columns and applies classic gravity (blocks fall
## to the bottom of their column). Returns the cell moves for animation.
func clear_lines(rows: Array[int], columns: Array[int]) -> Dictionary:
	return Gravity.apply(cells, size, rows, columns)


## Removes the given columns (they become empty) and applies classic gravity.
func clear_columns(columns: Array[int]) -> Dictionary:
	var no_rows: Array[int] = []
	return clear_lines(no_rows, columns)


## Removes the given rows and applies classic gravity. Returns the cell moves.
func clear_rows(rows: Array[int]) -> Dictionary:
	var no_columns: Array[int] = []
	return clear_lines(rows, no_columns)
