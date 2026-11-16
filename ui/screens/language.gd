extends Screen
## Language picker. English is the default and every other language falls back to English
## for text that has not been translated yet.

func on_back() -> void:
	main.go("settings")

func build() -> void:
	begin_page("Language", false, "settings")
	add_text("Untranslated text falls back to English.", 22, "text_dim")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(grid)
	for code in I18n.LANGUAGES:
		var cur: bool = code == I18n.current()
		var name := str(I18n.LANGUAGES[code])
		var b := UIKit.button(name, "primary" if cur else "secondary", Vector2(0, 68))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 22)
		if cur:
			b.text = "> " + name
		b.pressed.connect(func():
			SaveManager.set_setting("language", code)
			I18n.reload()
			refresh())
		grid.add_child(b)
