extends Screen
## Adventure: the level you are on right now, how to complete it, your overall progress
## and the chapter map. Header: back arrow, title, coins + gems.

func build() -> void:
	begin_page("Adventure", true, "home")
	var nxt := GameState.next_unfinished_level()
	_add_current_level(nxt)
	_add_how_to(nxt)
	_add_progress()
	_add_chapters()

# ---- current level ---------------------------------------------------------------------------
func _add_current_level(nxt: Vector2i) -> void:
	var card := UIKit.panel(UIKit.c("primary").darkened(0.12), 32)
	list.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UIKit.label("Current Level", 26, "accent", HORIZONTAL_ALIGNMENT_CENTER))
	if nxt.x <= 0:
		v.add_child(UIKit.label(I18n.t("All levels done!"), 44, "good", HORIZONTAL_ALIGNMENT_CENTER))
		v.add_child(UIKit.label("Replay any level from the chapters below.", 24, "text_dim", HORIZONTAL_ALIGNMENT_CENTER))
		return
	var lv := LevelDB.get_level(nxt.x, nxt.y)
	var goal: Dictionary = lv.get("goal", {})
	var stars := GameState.level_stars(str(lv.get("id", "")))
	v.add_child(UIKit.label(I18n.t("Level %d") % nxt.y, 52, "text", HORIZONTAL_ALIGNMENT_CENTER, false))
	v.add_child(UIKit.label(str(lv.get("name", "")), 24, "text_dim", HORIZONTAL_ALIGNMENT_CENTER, false))
	v.add_child(UIKit.label(I18n.t("Reach %d points") % int(goal.get("target", 0)), 28, "good", HORIZONTAL_ALIGNMENT_CENTER, false))
	var sd := StarsDisplay.new(stars, 40.0)
	sd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(sd)
	var b := UIKit.button(I18n.t("Play Level %d") % nxt.y, "accent", Vector2(0, 92))
	b.add_theme_font_size_override("font_size", 32)
	b.pressed.connect(func():
		if GameState.start_level(nxt.x, nxt.y): main.go("game"))
	v.add_child(b)

# ---- how to complete --------------------------------------------------------------------------
func _add_how_to(nxt: Vector2i) -> void:
	var card := UIKit.panel(UIKit.c("panel"), 28)
	list.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	card.add_child(v)
	v.add_child(UIKit.label("How to complete", 32, "accent"))
	v.add_child(UIKit.label(I18n.t("Drag a block from the tray onto the board. Fill a whole row or a whole column to clear it and score points."), 24, "text"))
	v.add_child(UIKit.label(I18n.t("Stone blocks cannot be moved - they block your lines. Tap a stone block once to crack it and once more to destroy it. You only have a few shots per game."), 24, "text_dim"))
	if nxt.x > 0:
		var lv := LevelDB.get_level(nxt.x, nxt.y)
		var goal: Dictionary = lv.get("goal", {})
		var thresholds: Array = lv.get("stars", [])
		if thresholds.size() == 3:
			v.add_child(UIKit.label(I18n.t("Stars: %d / %d / %d points") % [int(thresholds[0]), int(thresholds[1]), int(thresholds[2])], 24, "text_dim", HORIZONTAL_ALIGNMENT_LEFT, false))
			v.add_child(UIKit.label(I18n.t("Clear the level by reaching %d points.") % int(goal.get("target", 0)), 24, "text_dim", HORIZONTAL_ALIGNMENT_LEFT, false))

# ---- progress ---------------------------------------------------------------------------------
func _add_progress() -> void:
	var done := 0
	var stars := 0
	for k in GameState.d().progress.levels:
		var s := int(GameState.d().progress.levels[k])
		if s >= 1: done += 1
		stars += s
	var total := LevelDB.total_levels()
	var card := UIKit.panel(UIKit.c("panel"), 28)
	list.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	v.add_child(UIKit.label("Your progress", 32, "accent"))
	v.add_child(UIKit.label("%d / %d levels completed   -   %d / %d stars" % [done, total, stars, total * 3], 24, "text", HORIZONTAL_ALIGNMENT_LEFT, false))
	v.add_child(make_progress(done, total))
# ---- chapters ---------------------------------------------------------------------------------
func _add_chapters() -> void:
	add_heading("Chapters")
	for ch in LevelDB.chapters():
		var id: int = int(ch.id)
		var unlocked := GameState.is_chapter_unlocked(id)
		var cs := GameState.chapter_stars(id)
		var v := add_card("%d. %s" % [id, ch.name],
			"%d / %d stars  (levels %d-%d)" % [cs, int(ch.levels) * 3, (id - 1) * 10 + 1, id * 10] if unlocked else "Locked - finish the previous chapter",
			"Open" if unlocked else "Locked", func(): main.go("levels", {"chapter": id}), unlocked, "primary", false)
		v.add_child(make_progress(cs, int(ch.levels) * 3))
