class_name Board
extends RefCounted
## 8x8 occupancy grid. Value 0 = empty, >0 = color index. Index = row * SIZE + col.

const SIZE := 8
const CELLS := 64

var cells := PackedInt32Array()

func _init() -> void:
	cells.resize(CELLS)
	cells.fill(0)

func clear_all() -> void:
	cells.fill(0)

func copy() -> Board:
	var b := Board.new()
	b.cells = cells.duplicate()
	return b

static func idx(row: int, col: int) -> int:
	return row * SIZE + col

static func in_bounds(row: int, col: int) -> bool:
	return row >= 0 and col >= 0 and row < SIZE and col < SIZE

func get_cell(row: int, col: int) -> int:
	return cells[row * SIZE + col]

func set_cell(row: int, col: int, v: int) -> void:
	cells[row * SIZE + col] = v

func is_occupied(row: int, col: int) -> bool:
	return cells[row * SIZE + col] != 0

func occupied_count() -> int:
	var n := 0
	for v in cells:
		if v != 0: n += 1
	return n

func is_empty() -> bool:
	return occupied_count() == 0

## Piece anchor = top-left of its bounding box placed at (row, col).
func can_place(piece: Dictionary, row: int, col: int) -> bool:
	for p in piece.cells:
		var r: int = row + p.y
		var c: int = col + p.x
		if r < 0 or c < 0 or r >= SIZE or c >= SIZE: return false
		if cells[r * SIZE + c] != 0: return false
	return true

func place(piece: Dictionary, row: int, col: int) -> bool:
	if not can_place(piece, row, col): return false
	for p in piece.cells:
		cells[(row + p.y) * SIZE + col + p.x] = piece.color
	return true

func full_rows() -> Array:
	var out: Array = []
	for r in SIZE:
		var full := true
		for c in SIZE:
			if cells[r * SIZE + c] == 0:
				full = false
				break
		if full: out.append(r)
	return out

func full_cols() -> Array:
	var out: Array = []
	for c in SIZE:
		var full := true
		for r in SIZE:
			if cells[r * SIZE + c] == 0:
				full = false
				break
		if full: out.append(c)
	return out

func to_array() -> Array:
	return Array(cells)

func from_array(a: Array) -> bool:
	if a.size() != CELLS: return false
	for i in CELLS:
		cells[i] = int(a[i])
	return true
