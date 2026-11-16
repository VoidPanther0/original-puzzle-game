extends SceneTree
## Dev tool: godot --path . --resolution 720x1280 -s res://tests/shot2.gd
func _initialize() -> void:
	call_deferred("_run")

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _run() -> void:
	var out := "C:/Users/This PC/AppData/Local/Temp/shots3"
	DirAccess.make_dir_recursive_absolute(out)
	var main: Node = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	root.get_node("SaveManager").set_setting("consent", "granted")
	print("fallback font: ", ThemeDB.fallback_font, " path=", ThemeDB.fallback_font.resource_path if ThemeDB.fallback_font else "")
	await _wait(1.0); await _snap(out, "1_logo")
	await _wait(2.2); await _snap(out, "2_studio")
	await _wait(1.6); await _snap(out, "3_loading")
	await _wait(3.2); await _snap(out, "4_home")
	var more: Button = null
	for b in _all_buttons(main.current):
		if b.text == "•••": more = b
	if more != null:
		more.pressed.emit()
		await _wait(0.4); await _snap(out, "5_more")
	main.go("adventure", {}, false); await _wait(0.5); await _snap(out, "6_adventure")
	main.go("settings", {}, false); await _wait(0.5); await _snap(out, "7_settings")
	main.go("levels", {"chapter": 1}, false); await _wait(0.5); await _snap(out, "8_levels")
	main.go("language", {}, false); await _wait(0.5); await _snap(out, "9_language")
	# game screen with a stone block that gets cracked
	var gs = root.get_node("GameState")
	gs.start_level(1, 3)
	main.go("game", {}, false)
	await _wait(0.6)
	var game = main.current
	var s: GameSession = gs.session
	var stone := Vector2i(-1, -1)
	for r in Board.SIZE:
		for c in Board.SIZE:
			if s.board.get_cell(r, c) == GameSession.STONE and stone.x < 0:
				stone = Vector2i(r, c)
	if stone.x >= 0:
		game._shot_at(stone.x, stone.y)
		await _wait(0.3); await _snap(out, "10_game_crack")
		game._shot_at(stone.x, stone.y)
		await _wait(0.3); await _snap(out, "11_game_destroyed")
	# other languages
	var i18n: GDScript = load("res://ui/i18n.gd")
	for code in ["hi", "ar", "vi", "ja", "ru"]:
		root.get_node("SaveManager").set_setting("language", code)
		i18n.reload()
		main.go("settings", {}, false)
		await _wait(0.45); await _snap(out, "12_lang_" + code)
	root.get_node("SaveManager").set_setting("language", "en")
	i18n.reload()
	quit()

func _all_buttons(n: Node, out: Array = []) -> Array:
	for c in n.get_children():
		if c is BaseButton: out.append(c)
		_all_buttons(c, out)
	return out

func _snap(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
