class_name PieceView
extends Control
## Draws one piece. Used for the three tray slots (auto-fitted, with a panel
## behind it) and for the piece being dragged (fixed cell size, no panel).

signal pressed(global_point: Vector2)

var piece: PieceData = null:
	set(value):
		piece = value
		queue_redraw()
## Cell size in pixels. 0 means "fit inside the control".
var fixed_cell: float = 0.0:
	set(value):
		fixed_cell = value
		queue_redraw()
var show_panel: bool = false:
	set(value):
		show_panel = value
		queue_redraw()
## When true the piece is hidden (it is being dragged elsewhere).
var hidden_piece: bool = false:
	set(value):
		hidden_piece = value
		queue_redraw()
## The piece does not fit anywhere on the board right now.
var blocked: bool = false:
	set(value):
		blocked = value
		queue_redraw()


func _ready() -> void:
	resized.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	if not show_panel:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			pressed.emit(mb.global_position)
			accept_event()


func cell_for_size() -> float:
	if fixed_cell > 0.0:
		return fixed_cell
	return minf(size.x / 5.3, size.y / 3.8)


func _draw() -> void:
	if show_panel:
		var panel_color: Color = UiTheme.PANEL.darkened(0.25) if blocked else UiTheme.PANEL
		UiTheme.draw_round_rect(self, Rect2(Vector2.ZERO, size), panel_color, minf(size.x, size.y) * 0.14)
	if piece == null or hidden_piece:
		return
	var cell: float = cell_for_size()
	var extent := Vector2(piece.width, piece.height) * cell
	var offset: Vector2 = (size - extent) / 2.0
	var inset: float = cell * 0.04
	for c: Vector2i in piece.shape:
		var rect := Rect2(offset + Vector2(c) * cell, Vector2(cell, cell)).grow(-inset)
		if blocked:
			UiTheme.draw_round_rect(self, rect, Color(0.35, 0.33, 0.5, 0.55), cell * 0.2)
		else:
			UiTheme.draw_block(self, rect, piece.color_id)
