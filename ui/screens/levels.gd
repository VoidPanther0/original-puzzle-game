extends Screen

func on_back() -> void:
	main.go("adventure")

func build() -> void:
	var chapter: int = int(args.get("chapter", 1))
	var ch := {}
	for c in LevelDB.chapters():
		if int(c.id) == chapter: ch = c
	begin_page("%s" % ch.name, true, "adventure")
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(grid)
	for i in range(1, int(ch.levels) + 1):
		var unlocked := GameState.is_level_unlocked(chapter, i)
		var stars := GameState.level_stars(LevelDB.level_id(chapter, i))
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var b := UIKit.button(str(i), "primary" if stars == 0 else "good", Vector2(0, 110))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 40)
		b.disabled = not unlocked
		if not unlocked:
			b.text = ""
			if UIKit.tex("lock") != null:
				b.icon = UIKit.tex("lock")
				b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.pressed.connect(func(): _start(chapter, i))
		v.add_child(b)
		var sd := StarsDisplay.new(stars, 22.0)
		sd.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(sd)
		grid.add_child(v)

func _start(chapter: int, index: int) -> void:
	var lv := LevelDB.get_level(chapter, index)
	var goal: Dictionary = lv.goal
	dialog("Level %d" % index, "Reach %d points.\n3 stars at %d." % [int(goal.target), int(lv.stars[2])], [
		["Start", func():
			if GameState.start_level(chapter, index): main.go("game"), "primary"],
		["Cancel", Callable(), "secondary"]], false)
