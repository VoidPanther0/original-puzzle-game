extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _w(s: float) -> void: await create_timer(s).timeout
func _snap(n: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("C:/Users/This PC/AppData/Local/Temp/shots2/%s.png" % n)
func _run() -> void:
	var main: Node = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	await _w(0.5)
	var gs = root.get_node("GameState")
	gs.start_endless(false)
	main.go("game", {}, false)
	await _w(0.6)
	var s: GameSession = gs.session
	s.board.clear_all()
	for c in 8:
		if c != 3: s.board.set_cell(7, c, 1)
	s.board.set_cell(5, 1, 6); s.board.set_cell(4, 1, 2); s.board.set_cell(6, 5, 4); s.board.set_cell(3, 6, 8)
	s.tray = [PieceDB.get_piece("dot_0"), PieceDB.get_piece("o_0"), PieceDB.get_piece("i3_0")]
	main.current.view.queue_redraw()
	await _w(0.3); await _snap("g0_before")
	main.current.view._commit(0, s.tray[0], 7, 3)
	await _w(0.12); await _snap("g1_flash")
	await _w(0.35); await _snap("g2_falling")
	await _w(0.6); await _snap("g3_after")
	quit()
