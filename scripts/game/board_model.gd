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


## Removes the given rows and applies gravity. Returns the row moves
## (Vector2i(from_row, to_row)) so views can animate them.
func clear_rows(rows: Array[int]) -> Array[Vector2i]:
	return Gravity.apply(cells, size, rows)
