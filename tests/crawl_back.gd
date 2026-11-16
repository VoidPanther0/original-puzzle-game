extends SceneTree
## Opens every screen and triggers the Android-back / Escape handler on it.
func _initialize() -> void: call_deferred("_run")
func _w(s: float) -> void: await create_timer(s).timeout
func _run() -> void:
	var sm = root.get_node("SaveManager")
	await _w(0.3)
	sm.save_path = "user://crawl_save.json"
	sm.backup_path = "user://crawl_save.bak.json"
	sm.data = sm.defaults()
	sm.data.settings["consent"] = "granted"
	var main: Node = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	await _w(0.5)
	var gs = root.get_node("GameState")
	var n := 0
	for name in main.SCREENS:
		if name == "splash": continue
		gs.start_endless(false)
		if name == "level_complete":
			gs.start_level(1, 1)
			gs.session.level_complete = true
			gs.session.scoring.score = int(gs.session.level.stars[0])
			gs.finish_session()
		main.go(name, {"chapter": 1, "summary": gs.last_result}, false)
		await _w(0.3)
		var before: String = main.current_name
		main._back()
		await _w(0.4)
		n += 1
		print("back from %-15s -> %s" % [before, main.current_name])
	print("BACK TEST: %d screens, no errors" % n)
	quit()
