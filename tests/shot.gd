extends Node
## Dev helper: renders the menu and a mid-game board to PNG files.
## Run (not headless): godot --path . res://tests/shot.tscn -- <output_dir>

func _ready() -> void:
	var out: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "user://"
	await get_tree().process_frame
	get_window().size = Vector2i(540, 960)
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	for _i in 8:
		await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	_save(out + "/menu.png")
	main.get("_current").play_pressed.emit()
	await get_tree().create_timer(0.6).timeout
	var game: GameScreen = main.get("_current")
	var rows := ["........", "........", "........", "..11....", "..1.55..", "3344.5..", "334466.7", "2.446677"]
	for y in 8:
		for x in 8:
			game.state.board.cells[y * 8 + x] = 0 if rows[y][x] == "." else int(rows[y][x])
	game.get("_board_view").display = game.state.board.cells.duplicate()
	game.state.score = 245
	game.call("_on_score_changed", 245)
	game.call("_on_combo_changed", 3)
	game.call("_refresh_tray")
	await get_tree().create_timer(0.6).timeout
	_save(out + "/game.png")
	game.call("_open_pause")
	await get_tree().create_timer(0.5).timeout
	_save(out + "/pause.png")
	get_tree().quit()

func _save(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
