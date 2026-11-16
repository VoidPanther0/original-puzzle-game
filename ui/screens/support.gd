extends Screen

var _msg: TextEdit

func build() -> void:
	begin_page("Support and Feedback", false)
	add_heading("FAQ")
	add_card("How do I clear lines?", "Fill an entire row or column of the 8x8 board. Clear several at once for bonus points; consecutive clears build a combo.", "", Callable(), true, "primary", false)
	add_card("The game ended but I had a move?", "Game over only happens when none of your remaining pieces fits anywhere. Pieces cannot be rotated.", "", Callable(), true, "primary", false)
	add_card("Is my progress saved?", "Yes, automatically on this device. Sign in from Profile to back it up to the cloud.", "", Callable(), true, "primary", false)
	add_heading("Send feedback")
	_msg = TextEdit.new()
	_msg.placeholder_text = I18n.t("Tell us what happened or what you'd like to see...")
	_msg.custom_minimum_size = Vector2(0, 200)
	_msg.add_theme_font_size_override("font_size", 24)
	list.add_child(_msg)
	add_button("Send", _send, "primary")
	var email := str(preload("res://ui/screens/settings.gd")._app_info().get("support_email", ""))
	if email != "":
		add_button("Email support", func(): Platform.open_url("mailto:" + email), "secondary")
	else:
		add_text("No support email is configured for this build (config/app.json).", 20, "text_dim")

func _send() -> void:
	var text := _msg.text.strip_edges()
	if text.length() < 5:
		toast("Please write a little more")
		return
	var r: Dictionary = await BackendService.submit_feedback(text)
	if r.ok:
		toast("Thanks! Feedback sent")
	else:
		# Fall back to a local file so nothing is lost when offline / not configured.
		var f := FileAccess.open("user://feedback.txt", FileAccess.READ_WRITE if FileAccess.file_exists("user://feedback.txt") else FileAccess.WRITE)
		if f:
			f.seek_end()
			f.store_line("[%s] %s" % [GameState.today(), text.replace("\n", " ")])
			f.close()
		toast("Saved on device (server not reachable)")
	_msg.text = ""
