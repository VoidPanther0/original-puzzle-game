class_name BoardView
extends Control
## Draws the board and runs its animations. It holds a *display copy* of the
## grid, so animations can show intermediate states (before rows clear, while
## rows fall) without touching the game rules.

var board_size: int = 8
var display: PackedInt32Array = PackedInt32Array():
	set(value):
		display = value
		queue_redraw()

# Ghost preview while dragging
var ghost_shape: Array[Vector2i] = []
var ghost_origin: Vector2i = Vector2i.ZERO
var ghost_color_id: int = 1
var preview_rows: Array[int] = []

# Animation state
var _pop_cells: Array[Vector2i] = []
var _pop_t: float = 1.0
var _flash_rows: Array[int] = []
var _flash_t: float = 0.0
var _fall_from: Dictionary = {}  # to_row -> from_row
var _fall_t: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	resized.connect(queue_redraw)
	if display.is_empty():
		display.resize(board_size * board_size)
		display.fill(0)


# ---------------------------------------------------------------- geometry

func _side() -> float:
	return minf(size.x, size.y)


func cell_px() -> float:
	var side: float = _side()
	return (side - side * 0.05) / float(board_size)


## Top-left of the grid in this control's local space.
func grid_origin_local() -> Vector2:
	var side: float = _side()
	return (size - Vector2(side, side)) / 2.0 + Vector2(side, side) * 0.025


func grid_origin_global() -> Vector2:
	return get_global_transform() * grid_origin_local()


## Which grid cell (float) a global point falls on.
func global_to_cell(point: Vector2) -> Vector2:
	return (point - grid_origin_global()) / cell_px()


# ---------------------------------------------------------------- ghost

func set_ghost(shape: Array[Vector2i], origin: Vector2i, color_id: int, rows: Array[int]) -> void:
	ghost_shape = shape
	ghost_origin = origin
	ghost_color_id = color_id
	preview_rows = rows
	queue_redraw()


func clear_ghost() -> void:
	if ghost_shape.is_empty() and preview_rows.is_empty():
		return
	ghost_shape = []
	preview_rows = []
	queue_redraw()


# ---------------------------------------------------------------- animation

## Cells that were just placed bounce in.
func animate_pop(cells: Array[Vector2i]) -> void:
	_pop_cells = cells
	_pop_t = 0.0
	var tween: Tween = create_tween()
	tween.tween_method(_set_pop, 0.0, 1.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished
	_pop_cells = []
	queue_redraw()


## Full rows flash and shrink away. The caller then swaps in the post-clear grid.
func animate_clear(rows: Array[int]) -> void:
	_flash_rows = rows
	_flash_t = 0.0
	var tween: Tween = create_tween()
	tween.tween_method(_set_flash, 0.0, 1.0, 0.34).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_flash_rows = []
	_flash_t = 0.0
	queue_redraw()


## Rows that moved fall from their old row to their new row.
## `moves` holds Vector2i(from_row, to_row); `display` must already be the final grid.
func animate_gravity(moves: Array[Vector2i]) -> void:
	if moves.is_empty():
		return
	_fall_from.clear()
	var longest: int = 1
	for m: Vector2i in moves:
		_fall_from[m.y] = m.x
		longest = maxi(longest, m.y - m.x)
	_fall_t = 1.0
	var tween: Tween = create_tween()
	var duration: float = 0.16 + 0.07 * float(longest)
	tween.tween_method(_set_fall, 1.0, 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	_fall_from.clear()
	_fall_t = 0.0
	queue_redraw()


func _set_pop(value: float) -> void:
	_pop_t = value
	queue_redraw()


func _set_flash(value: float) -> void:
	_flash_t = value
	queue_redraw()


func _set_fall(value: float) -> void:
	_fall_t = value
	queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var side: float = _side()
	var frame := Rect2((size - Vector2(side, side)) / 2.0, Vector2(side, side))
	UiTheme.draw_round_rect(self, frame, UiTheme.PANEL, side * 0.04)

	var cell: float = cell_px()
	var origin: Vector2 = grid_origin_local()
	var inset: float = cell * 0.05

	# Empty cells
	for y: int in board_size:
		for x: int in board_size:
			var r := Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)).grow(-inset)
			UiTheme.draw_round_rect(self, r, UiTheme.CELL_EMPTY, cell * 0.2)

	# Rows that would clear if the dragged piece is dropped here
	for row: int in preview_rows:
		var band := Rect2(origin + Vector2(0, row) * cell, Vector2(cell * board_size, cell)).grow(-inset)
		UiTheme.draw_round_rect(self, band, Color(UiTheme.ACCENT, 0.22), cell * 0.2)

	# Placed blocks
	if display.size() == board_size * board_size:
		for y: int in board_size:
			var fall_offset: float = 0.0
			if _fall_from.has(y):
				fall_offset = float(_fall_from[y] - y) * _fall_t
			for x: int in board_size:
				var id: int = display[y * board_size + x]
				if id == 0:
					continue
				var pos: Vector2 = origin + Vector2(x, y + fall_offset) * cell
				var r := Rect2(pos, Vector2(cell, cell)).grow(-inset)
				if _pop_cells.has(Vector2i(x, y)):
					var s: float = lerpf(0.55, 1.0, _pop_t)
					r = Rect2(r.get_center() - r.size * s / 2.0, r.size * s)
				if _flash_rows.has(y):
					var shrink: float = 1.0 - _flash_t * 0.6
					r = Rect2(r.get_center() - r.size * shrink / 2.0, r.size * shrink)
				UiTheme.draw_block(self, r, id)
				if _flash_rows.has(y):
					UiTheme.draw_round_rect(self, r, Color(1, 1, 1, sin(_flash_t * PI) * 0.85), cell * 0.2)

	# Ghost of the piece being dragged
	for c: Vector2i in ghost_shape:
		var g := Rect2(origin + Vector2(ghost_origin + c) * cell, Vector2(cell, cell)).grow(-inset)
		UiTheme.draw_round_rect(self, g, Color(UiTheme.block_color(ghost_color_id), 0.42), cell * 0.2)
