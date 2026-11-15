extends SceneTree
## Rasterises the SVG icons into the PNGs the Android export needs.
## Run: godot --headless --path . -s tools/gen_icons.gd

func _initialize() -> void:
	_render("res://icon.svg", "res://assets/icon_192.png", 192.0 / 512.0)
	_render("res://assets/icon_foreground.svg", "res://assets/icon_foreground_432.png", 1.0)
	_render("res://assets/icon_background.svg", "res://assets/icon_background_432.png", 1.0)
	_render("res://assets/icon_foreground.svg", "res://assets/icon_monochrome_432.png", 1.0, true)
	quit()

func _render(svg_path: String, png_path: String, scale: float, mono: bool = false) -> void:
	var text: String = FileAccess.get_file_as_string(svg_path)
	var img := Image.new()
	var err: Error = img.load_svg_from_string(text, scale)
	if err != OK:
		push_error("SVG failed: " + svg_path)
		return
	if mono:
		img.convert(Image.FORMAT_RGBA8)
		for y: int in img.get_height():
			for x: int in img.get_width():
				var c: Color = img.get_pixel(x, y)
				img.set_pixel(x, y, Color(1, 1, 1, c.a))
	img.save_png(png_path)
	print("wrote ", png_path, " ", img.get_size())
