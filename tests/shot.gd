extends SceneTree
## Dev tool: godot --path godot --resolution 450x800 -s res://tests/shot.gd
func _initialize() -> void:
	call_deferred("_run")

func _wait(sec: float) -> void:
	await create_timer(sec).timeout

func _run() -> void:
	var out := "C:/Users/This PC/AppData/Local/Temp/shots2"
	DirAccess.make_dir_recursive_absolute(out)
	var main: Node = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	root.get_node("SaveManager").set_setting("consent", "granted")
	await _wait(1.2); await _snap(out, "1_logo")
	await _wait(2.0); await _snap(out, "2_studio")
	await _wait(1.6); await _snap(out, "3_loading")
	await _wait(3.5); await _snap(out, "4_home")
	main.current.list.get_parent().scroll_vertical = 600
	await _wait(0.3); await _snap(out, "5_home_scrolled")
	main.go("adventure", {}, false); await _wait(0.5); await _snap(out, "6_adventure")
	quit()

func _snap(out: String, name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
