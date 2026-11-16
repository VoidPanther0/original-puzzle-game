extends Screen

var _global_box: VBoxContainer

func build() -> void:
	begin_page("Leaderboard")
	add_heading("Global")
	_global_box = VBoxContainer.new()
	list.add_child(_global_box)
	if not BackendService.is_configured():
		_global_box.add_child(UIKit.label("Online leaderboards are not configured in this build (see SUPABASE_SETUP.md).", 22, "text_dim"))
	elif not BackendService.is_signed_in():
		_global_box.add_child(UIKit.label("Sign in from your Profile to see and join global rankings.", 22, "text_dim"))
		var b := UIKit.button("Open Profile", "secondary", Vector2(0, 64))
		b.pressed.connect(func(): main.go("profile"))
		_global_box.add_child(b)
	else:
		_global_box.add_child(UIKit.label("Loading...", 24, "text_dim"))
		call_deferred("_load")
	add_heading("Your best scores (this device)")
	var hs: Array = GameState.d().high_scores
	if hs.is_empty(): add_text("Play a game to set a score!", 24, "text_dim")
	for i in hs.size():
		add_card("#%d   %d" % [i + 1, int(hs[i].score)], "%s - %s" % [hs[i].date, hs[i].mode], "", Callable(), true, "primary", false)

func _load() -> void:
	var r: Dictionary = await BackendService.get_leaderboard("endless", 50)
	if not is_instance_valid(_global_box): return
	for c in _global_box.get_children(): c.queue_free()
	if not r.ok or typeof(r.body) != TYPE_DICTIONARY:
		_global_box.add_child(UIKit.label("Could not load rankings.", 24, "danger"))
		return
	var rows: Array = r.body.get("rows", [])
	if rows.is_empty(): _global_box.add_child(UIKit.label("No scores yet - be the first!", 24, "text_dim"))
	for i in rows.size():
		var p := UIKit.panel()
		var l := UIKit.label("#%d   %s   -   %d" % [i + 1, str(rows[i].get("display_name", "Player")), int(rows[i].get("score", 0))], 26, "text", HORIZONTAL_ALIGNMENT_LEFT, false)
		p.add_child(l)
		_global_box.add_child(p)
