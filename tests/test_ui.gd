extends TestCase
## Smoke test: boots the real Main scene, visits every screen and plays moves through BoardView.

func _frames(n: int = 3) -> void:
	for i in n: await tree.process_frame

func test_all_screens_build() -> void:
	var sm := tree.root.get_node("SaveManager")
	sm.save_path = "user://test_ui_save.json"
	sm.backup_path = "user://test_ui_save.bak.json"
	sm.data = SaveManager.defaults()
	sm.data.settings["consent"] = "granted"
	var main: Node = load("res://ui/main.tscn").instantiate()
	tree.root.add_child(main)
	await _frames()
	for name in main.SCREENS:
		if name == "game" or name == "level_complete": continue
		main.go(name, {"chapter": 1}, false)
		await _frames(4)
		check(main.current != null and main.current_name == name, "screen %s loaded" % name)
		check(name == "splash" or main.current.get_child_count() > 0, "screen %s has content" % name)
	# theme switch + language switch rebuild
	sm.set_setting("theme", "light")
	main.retheme()
	await _frames(3)
	sm.set_setting("language", "es")
	I18n.reload()
	main.go("home", {}, false)
	await _frames(3)
	eq(I18n.t("Play"), "Jugar", "spanish translation")
	sm.set_setting("language", "en")
	sm.set_setting("theme", "dark")
	I18n.reload()
	main.queue_free()
	await _frames(2)

func test_play_through_game_screen() -> void:
	var gs := tree.root.get_node("GameState")
	var main: Node = load("res://ui/main.tscn").instantiate()
	tree.root.add_child(main)
	await _frames()
	gs.start_endless(false)
	main.go("game", {}, false)
	await _frames(4)
	var game = main.current
	check(game.view != null, "board view exists")
	game.view.size = Vector2(700, 1000)
	game.view._relayout()
	var s: GameSession = gs.session
	var played := 0
	for _i in 30:
		var mv := MoveSolver.best_move(s.board, s.tray)
		if mv.is_empty(): break
		var piece: Dictionary = s.tray[mv.index]
		game.view._commit(mv.index, piece, mv.anchor.y, mv.anchor.x)
		played += 1
		await _frames(1)
		if s.game_over: break
	check(played > 3, "played several moves via the view")
	check(s.scoring.score > 0, "score increased")
	# simulate drag: press on tray piece, move to a valid spot, release
	if not s.game_over:
		var v: BoardView = game.view
		var idx := -1
		for i in 3:
			if s.tray[i] != null: idx = i
		if idx >= 0:
			var piece: Dictionary = s.tray[idx]
			var pos := PlacementValidator.all_positions(s.board, piece)
			if not pos.is_empty():
				var a: Vector2i = pos[0]
				var before := s.moves
				var start: Vector2 = v._slot_rects[idx].get_center()
				var ev := InputEventMouseButton.new()
				ev.button_index = MOUSE_BUTTON_LEFT
				ev.pressed = true
				ev.position = start
				v._gui_input(ev)
				var mm := InputEventMouseMotion.new()
				mm.position = v.board_rect.position + Vector2(a.x + piece.w / 2.0, a.y + piece.h / 2.0) * v.cell + Vector2(0, v.cell * BoardView.LIFT_CELLS)
				v._gui_input(mm)
				var up := InputEventMouseButton.new()
				up.button_index = MOUSE_BUTTON_LEFT
				up.pressed = false
				up.position = mm.position
				v._gui_input(up)
				eq(s.moves, before + 1, "drag and drop placed the piece")
	# invalid drop outside board does not change state
	if not s.game_over:
		var v2: BoardView = game.view
		var moves_before := s.moves
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		for i in 3:
			if s.tray[i] != null:
				down.position = v2._slot_rects[i].get_center()
				break
		v2._gui_input(down)
		var up2 := InputEventMouseButton.new()
		up2.button_index = MOUSE_BUTTON_LEFT
		up2.pressed = false
		up2.position = Vector2(-500, -500)
		v2._gui_input(up2)
		eq(s.moves, moves_before, "invalid drop rejected")
	main.queue_free()
	await _frames(2)
