extends SceneTree
func _initialize():
	var gs = root.get_node("GameState")
	gs.start_endless(false)
	var v := BoardView.new()
	root.add_child(v)
	v.size = Vector2(700, 1000)
	v._relayout()
	v.bind(gs.session)
	var s: GameSession = gs.session
	var idx := 0
	var piece: Dictionary = s.tray[idx]
	var a: Vector2i = PlacementValidator.all_positions(s.board, piece)[0]
	print("cell ", v.cell, " board ", v.board_rect, " slot ", v._slot_rects[idx], " piece ", piece.id, " anchor ", a)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = v._slot_rects[idx].get_center()
	v._gui_input(ev)
	print("drag ", v._drag)
	var mm := InputEventMouseMotion.new()
	mm.position = v.board_rect.position + Vector2(a.x + piece.w / 2.0, a.y + piece.h / 2.0) * v.cell + Vector2(0, v.cell * BoardView.LIFT_CELLS)
	v._gui_input(mm)
	print("snap ", v._snap, " dragpos ", v._drag_pos)
	quit()
