extends Node
## Headless UI test. Run with:
##   godot --headless --path . res://tests/ui_tests.tscn
## Drives the real game screen: drag and drop, invalid drops, restart, pause,
## game over, and layout at several screen sizes.

var _passed: int = 0
var _failed: int = 0

const SIZES: Array[Vector2i] = [
	Vector2i(720, 1280),   # reference portrait
	Vector2i(1080, 2400),  # tall modern phone
	Vector2i(540, 960),    # small phone
	Vector2i(1200, 1920),  # tablet portrait
	Vector2i(1600, 720),   # landscape desktop window
	Vector2i(600, 600),    # square
]


func check(condition: bool, message: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		print("FAIL ", message)


func _frames(count: int = 3) -> void:
	for _i: int in count:
		await get_tree().process_frame


func _ready() -> void:
	await _run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://ui_test_settings.cfg"))
	print("")
	print("UI checks passed: %d   failed: %d" % [_passed, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _run() -> void:
	# Never touch the real save file from tests.
	var app_settings: Node = get_tree().root.get_node("Settings")
	app_settings.save_path = "user://ui_test_settings.cfg"
	app_settings.best_score = 0
	await get_tree().process_frame
	var main: Control = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(main)
	await _frames()

	# ---- menu -> game
	var menu: Node = main.get("_current")
	check(menu is MenuScreen, "app starts on the menu")
	menu.play_pressed.emit()
	await _frames(4)
	var game: GameScreen = main.get("_current")
	check(game is GameScreen, "Play opens the game screen")
	if not game is GameScreen:
		return

	await _test_layouts(game)
	await _test_drag_and_place(game)
	await _test_invalid_drop(game)
	await _test_row_clear_animation(game)
	await _test_column_clear_animation(game)
	await _test_pause_and_restart(game)
	await _test_game_over(game)

	# ---- back to menu and into settings
	game.menu_requested.emit()
	await _frames(4)
	var menu2: Node = main.get("_current")
	check(menu2 is MenuScreen, "menu reachable from game")
	menu2.settings_pressed.emit()
	await _frames(4)
	var settings: Node = main.get("_current")
	check(settings is SettingsScreen, "settings screen opens")
	settings.back_pressed.emit()
	await _frames(4)
	check(main.get("_current") is MenuScreen, "settings returns to menu")


# ------------------------------------------------------------------ layout

func _test_layouts(game: GameScreen) -> void:
	for s: Vector2i in SIZES:
		get_tree().root.size = s
		await _frames(4)
		var screen: Rect2 = game.get_global_rect()
		var board: BoardView = game.get("_board_view")
		var tray: Control = game.get("_tray_row")
		var board_rect: Rect2 = board.get_global_rect()
		var tray_rect: Rect2 = tray.get_global_rect()
		var label: String = "%dx%d" % [s.x, s.y]
		check(screen.encloses(board_rect), "board inside screen at " + label)
		check(screen.encloses(tray_rect), "tray inside screen at " + label)
		check(board_rect.end.y <= tray_rect.position.y + 1.0, "board above tray at " + label)
		check(absf(board_rect.size.x - board_rect.size.y) < 1.5, "board stays square at " + label)
		check(board_rect.size.x >= 200.0, "board is usable size at " + label)
		for slot: PieceView in game.get("_slots"):
			check(slot.get_global_rect().size.x > 60.0, "tray slot visible at " + label)
	get_tree().root.size = SIZES[0]
	await _frames(4)


# ------------------------------------------------------------ drag & drop

func _slot_center(game: GameScreen, slot: int) -> Vector2:
	var view: PieceView = game.get("_slots")[slot]
	return view.get_global_rect().get_center()


## Where the pointer must be so the dragged piece lands with top-left at `cell`.
func _pointer_for_cell(game: GameScreen, slot: int, cell: Vector2i) -> Vector2:
	var board: BoardView = game.get("_board_view")
	var piece: PieceData = game.state.tray[slot]
	var cell_px: float = board.cell_px()
	var size: Vector2 = Vector2(piece.width, piece.height) * cell_px
	var top_left: Vector2 = board.grid_origin_global() + Vector2(cell) * cell_px
	return top_left + size / 2.0 + Vector2(0, cell_px * 1.8)


func _drag_to(game: GameScreen, slot: int, cell: Vector2i) -> void:
	game.call("_on_slot_pressed", _slot_center(game, slot), slot)
	var motion := InputEventMouseMotion.new()
	motion.position = _pointer_for_cell(game, slot, cell)
	motion.global_position = motion.position
	game.call("_input", motion)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = motion.position
	release.global_position = motion.position
	game.call("_input", release)


func _test_drag_and_place(game: GameScreen) -> void:
	game.call("_start_new_game", false)
	game.state.tray = [PieceData.new(PieceDefs.parse("XX"), 2), PieceData.new(PieceDefs.parse("X"), 3), PieceData.new(PieceDefs.parse("XXX"), 4)]
	game.call("_refresh_tray")
	await _frames(2)
	_drag_to(game, 0, Vector2i(2, 3))
	await get_tree().create_timer(0.6).timeout
	check(game.state.board.get_cell(2, 3) == 2 and game.state.board.get_cell(3, 3) == 2, "dragged piece placed at the target cell")
	check(game.state.tray[0] == null, "placed piece leaves the tray")
	check(game.state.score == 2, "score updated after drop")
	var board: BoardView = game.get("_board_view")
	check(board.display == game.state.board.cells, "board view matches model after animation")
	check(game.get("_busy") == false, "input unlocked after animation")


func _test_invalid_drop(game: GameScreen) -> void:
	var before: PackedInt32Array = game.state.board.cells.duplicate()
	var score: int = game.state.score
	_drag_to(game, 1, Vector2i(2, 3))  # occupied
	await get_tree().create_timer(0.4).timeout
	check(game.state.board.cells == before, "overlapping drop changes nothing")
	check(game.state.score == score, "overlapping drop scores nothing")
	check(game.state.tray[1] != null, "rejected piece stays in the tray")
	_drag_to(game, 2, Vector2i(7, 7))  # off the board
	await get_tree().create_timer(0.4).timeout
	check(game.state.board.cells == before, "off-board drop changes nothing")
	check(game.state.tray[2] != null, "off-board piece stays in the tray")
	check((game.get("_slots")[2] as PieceView).hidden_piece == false, "slot shows the piece again after a rejected drop")


func _test_row_clear_animation(game: GameScreen) -> void:
	game.call("_start_new_game", false)
	for x: int in 7:
		game.state.board.cells[7 * 8 + x] = 1
	game.state.board.cells[6 * 8 + 0] = 5  # sits above the row that will clear
	game.call("_refresh_tray")
	game.get("_board_view").display = game.state.board.cells.duplicate()
	game.state.tray = [PieceData.new(PieceDefs.parse("X"), 3), PieceData.new(PieceDefs.parse("XX"), 3), PieceData.new(PieceDefs.parse("X"), 3)]
	game.call("_refresh_tray")
	await _frames(2)
	_drag_to(game, 0, Vector2i(7, 7))
	await get_tree().create_timer(1.6).timeout
	check(game.state.board.get_cell(0, 7) == 5, "block above the cleared row fell down")
	check(game.state.board.get_cell(1, 7) == 0, "cleared row is empty")
	check(game.get("_board_view").display == game.state.board.cells, "view synced after clear and gravity")
	check(game.get("_busy") == false, "input unlocked after clear animation")
	check(int(get_tree().root.get_node("Settings").get("best_score")) >= game.state.score, "best score tracks the live score")


func _test_column_clear_animation(game: GameScreen) -> void:
	game.call("_start_new_game", false)
	for y: int in range(1, 8):
		game.state.board.cells[y * 8 + 5] = 1  # column 5 misses its top cell
	game.state.board.cells[2 * 8 + 7] = 2      # falls to the bottom after the clear
	game.call("_refresh_tray")
	game.get("_board_view").display = game.state.board.cells.duplicate()
	game.state.tray = [PieceData.new(PieceDefs.parse("X"), 3), PieceData.new(PieceDefs.parse("XX"), 3), PieceData.new(PieceDefs.parse("X"), 3)]
	game.call("_refresh_tray")
	await _frames(2)
	_drag_to(game, 0, Vector2i(5, 0))
	await get_tree().create_timer(1.6).timeout
	check(game.state.board.get_cell(5, 4) == 0, "the cleared column is empty")
	check(game.state.board.get_cell(7, 7) == 2, "the surviving block falls to the bottom")
	check(game.get("_board_view").display == game.state.board.cells, "view synced after the column clear")
	check(game.get("_busy") == false, "input unlocked after the column clear")


# ------------------------------------------------------------- pause / over

func _test_pause_and_restart(game: GameScreen) -> void:
	game.call("_open_pause")
	await _frames(2)
	check((game.get("_pause_dialog") as Control).visible, "pause dialog opens")
	game.call("_close_pause")
	check(not (game.get("_pause_dialog") as Control).visible, "resume closes the pause dialog")
	game.call("handle_back")
	check((game.get("_pause_dialog") as Control).visible, "back button opens pause")
	game.call("handle_back")
	check(not (game.get("_pause_dialog") as Control).visible, "back button closes pause")
	game.call("_start_new_game", true)
	check(game.state.score == 0 and game.state.board.is_empty(), "restart resets the game")
	check(game.get("_board_view").display == game.state.board.cells, "view reset on restart")


func _test_game_over(game: GameScreen) -> void:
	game.call("_start_new_game", false)
	for y: int in 8:
		for x: int in 8:
			game.state.board.cells[y * 8 + x] = 1 if (x + y) % 2 == 1 else 0
	game.state.tray = [PieceData.new(PieceDefs.parse("X"), 2), PieceData.new(PieceDefs.parse("XX"), 2), PieceData.new(PieceDefs.parse("XX/XX"), 2)]
	game.get("_board_view").display = game.state.board.cells.duplicate()
	game.call("_refresh_tray")
	await _frames(2)
	_drag_to(game, 0, Vector2i(0, 0))
	await get_tree().create_timer(1.0).timeout
	check(game.state.is_over, "game over detected")
	check((game.get("_over_dialog") as Control).visible, "game-over dialog shown")
