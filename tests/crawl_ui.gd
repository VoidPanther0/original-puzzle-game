extends SceneTree
## UI crawler: visits every screen, presses EVERY button/toggle/slider (and every button inside any
## dialog that opens), then goes Back. Run:  godot --headless --path godot -s res://tests/crawl_ui.gd
## Afterwards grep the output for "SCRIPT ERROR" / "ERROR:" - there must be none.

const SKIP_TEXT := ["Quit", "Full"]     # Quit would exit the crawler; Full toggles the OS window
var main: Node
var presses := 0
var screens_seen := 0

func _initialize() -> void:
	call_deferred("_run")

func _wait(s: float) -> void:
	await create_timer(s).timeout

func _buttons(n: Node, out: Array = []) -> Array:
	for c in n.get_children():
		if c is BaseButton and c.is_visible_in_tree() and not c.disabled: out.append(c)
		if c is HSlider and c.is_visible_in_tree(): out.append(c)
		_buttons(c, out)
	return out

func _label(b: Node) -> String:
	return b.text if b is Button else b.get_class()

func _press(b: Node) -> void:
	presses += 1
	if b is HSlider: b.value = (b.min_value + b.max_value) / 2.0 if b.value != b.max_value else b.min_value
	elif b is CheckButton or b is CheckBox: b.button_pressed = not b.button_pressed
	else: b.pressed.emit()

func _open(name: String, args: Dictionary) -> void:
	main.go(name, args, false)
	await _wait(0.25)

func _run() -> void:
	var sm = root.get_node("SaveManager")
	await _wait(0.3)
	sm.save_path = "user://crawl_save.json"
	sm.backup_path = "user://crawl_save.bak.json"
	sm.data = sm.defaults()
	sm.data.settings["consent"] = "granted"
	var gs = root.get_node("GameState")
	main = load("res://ui/main.tscn").instantiate()
	root.add_child(main)
	await _wait(0.5)
	main.go("home", {}, false)
	await _wait(0.3)
	var targets := [["home", {}], ["adventure", {}], ["levels", {"chapter": 1}], ["daily", {}], ["season", {}],
		["events", {}], ["shop", {}], ["inventory", {}], ["leaderboard", {}], ["profile", {}], ["achievements", {}],
		["settings", {}], ["language", {}], ["privacy", {}], ["terms", {}], ["support", {}]]
	for t in targets:
		await _crawl(t[0], t[1])
	# game screen (needs a session), then level-complete (needs a summary)
	gs.start_endless(false)
	await _crawl("game", {})
	gs.start_level(1, 1)
	gs.session.scoring.score = int(gs.session.level.stars[1])
	gs.session.level_complete = true
	var summary: Dictionary = gs.finish_session()
	await _crawl("level_complete", {"summary": summary})
	# back button on every screen (Android back / Escape)
	for t in targets:
		await _open(t[0], t[1])
		main._back()
		await _wait(0.3)
	print("CRAWL: %d screens, %d button presses" % [screens_seen, presses])
	quit()

func _crawl(name: String, args: Dictionary) -> void:
	await _open(name, args)
	screens_seen += 1
	var n := _buttons(main.current).size()
	print("crawl ", name, " buttons=", n, " presses so far=", presses)
	for i in n:
		await _open(name, args)
		var list := _buttons(main.current)
		if i >= list.size(): break
		var b: Node = list[i]
		var lbl := _label(b)
		print("  press [", i, "] ", lbl)
		if lbl.strip_edges() in SKIP_TEXT: continue
		var before := list.duplicate()
		_press(b)
		await _wait(0.35)
		if main.current == null: continue
		# any new buttons (dialog opened) get pressed too, each from a fresh state
		var after := _buttons(main.current)
		var fresh: Array = []
		for x in after:
			if x not in before: fresh.append(x)
		for j in fresh.size():
			await _open(name, args)
			var l2 := _buttons(main.current)
			if i >= l2.size(): break
			_press(l2[i])
			await _wait(0.35)
			var a2 := _buttons(main.current)
			var f2: Array = []
			for x in a2:
				if x not in l2: f2.append(x)
			if j < f2.size():
				var lb := _label(f2[j])
				if lb.strip_edges() in SKIP_TEXT: continue
				_press(f2[j])
				await _wait(0.4)
		main._back()
		await _wait(0.3)
	await _open(name, args)
