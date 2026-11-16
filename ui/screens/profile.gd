extends Screen

var _name: LineEdit
var _mail: LineEdit
var _pass: LineEdit

func build() -> void:
	begin_page("Profile")
	var pr: Dictionary = GameState.d().profile
	add_heading("Player")
	_name = LineEdit.new()
	_name.text = str(pr.name)
	_name.max_length = 16
	_name.custom_minimum_size = Vector2(0, 64)
	_name.add_theme_font_size_override("font_size", 28)
	_name.text_submitted.connect(func(_t): _save_name())
	list.add_child(_name)
	add_button("Save name", _save_name, "secondary")
	add_heading("Stats")
	var st: Dictionary = GameState.d().stats
	add_text("Best score: %d\nGames played: %d\nLines cleared: %d\nBest combo: x%d\nLevels completed: %d\nPerfect clears: %d\nBest streak: %d days" % [
		int(GameState.d().best_score), int(st.games), int(st.lines), int(st.best_combo), int(st.levels_done), int(st.boards_cleared), int(GameState.d().streak.best)], 26, "text", HORIZONTAL_ALIGNMENT_LEFT, false)
	add_button("Achievements", func(): main.go("achievements"), "accent")
	add_heading("Account & cloud save")
	if not BackendService.is_configured():
		add_text("Online features are not configured in this build. Your progress is saved on this device. See SUPABASE_SETUP.md to enable accounts and cloud save.", 22, "text_dim")
	elif BackendService.is_signed_in():
		add_text("Signed in as %s" % (BackendService.email if BackendService.email != "" else "guest"), 24, "good", HORIZONTAL_ALIGNMENT_LEFT, false)
		add_button("Upload progress to cloud", _push, "primary")
		add_button("Download cloud progress", _pull, "secondary")
		add_button("Sign out", func(): BackendService.sign_out(); refresh(), "danger")
	else:
		_mail = LineEdit.new()
		_mail.placeholder_text = "Email"
		_mail.custom_minimum_size = Vector2(0, 64)
		_pass = LineEdit.new()
		_pass.placeholder_text = "Password (min 8)"
		_pass.secret = true
		_pass.custom_minimum_size = Vector2(0, 64)
		list.add_child(_mail)
		list.add_child(_pass)
		add_button("Sign in", func(): await _auth(false), "primary")
		add_button("Create account", func(): await _auth(true), "secondary")
		add_button("Play as guest (anonymous)", _guest, "secondary")

func _save_name() -> void:
	GameState.d().profile["name"] = _name.text.strip_edges() if _name.text.strip_edges() != "" else "Player"
	SaveManager.mark_dirty()
	toast("Saved")
	if BackendService.is_signed_in(): BackendService.call_deferred("update_profile", GameState.d().profile.name, int(GameState.d().profile.avatar))

func _auth(sign_up: bool) -> void:
	if _mail.text.strip_edges() == "" or _pass.text.length() < 8:
		toast("Enter an email and a password of 8+ characters")
		return
	var ok: bool
	if sign_up: ok = await BackendService.sign_up(_mail.text.strip_edges(), _pass.text)
	else: ok = await BackendService.sign_in(_mail.text.strip_edges(), _pass.text)
	toast("Signed in" if ok else "Authentication failed")
	if ok: refresh()

func _guest() -> void:
	var ok: bool = await BackendService.sign_in_anonymous()
	toast("Signed in as guest" if ok else "Guest sign-in unavailable")
	if ok: refresh()

func _push() -> void:
	var r: Dictionary = await BackendService.cloud_push()
	toast("Cloud save uploaded" if r.ok else "Upload failed")

func _pull() -> void:
	var r: Dictionary = await BackendService.cloud_pull()
	if r.ok and typeof(r.body) == TYPE_DICTIONARY and typeof(r.body.get("data")) == TYPE_DICTIONARY:
		var remote: Dictionary = r.body.data
		# Conservative merge: keep the larger of progress-like numbers, never lower anything.
		if int(remote.get("best_score", 0)) > int(GameState.d().best_score): GameState.d().best_score = int(remote.best_score)
		var rl: Dictionary = remote.get("progress", {}).get("levels", {})
		for k in rl:
			if int(rl[k]) > GameState.level_stars(k): GameState.d().progress.levels[k] = int(rl[k])
		SaveManager.mark_dirty()
		toast("Cloud progress merged")
	else:
		toast("No cloud save found")
