class_name Switch
extends Control
## Small on/off switch built from the ON/OFF art. It scales to the space it is given, so it
## also fits the narrow phone layout (the settings sound row has three of them side by side).

signal toggled(on: bool)

var on := true

func _init() -> void:
	custom_minimum_size = Vector2(0, 52)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on = not on
		toggled.emit(on)
		queue_redraw()
		accept_event()

func _draw() -> void:
	var art_on := UIKit.tex("toggle_on")
	var art_off := UIKit.tex("toggle_off")
	var aspect := 2.55
	var w := size.x
	var h := w / aspect
	if h > size.y:
		h = size.y
		w = h * aspect
	var r := Rect2(Vector2((size.x - w) * 0.5, (size.y - h) * 0.5), Vector2(w, h))
	if art_on != null and art_off != null:
		draw_texture_rect(art_on if on else art_off, r, false)
		return
	# fallback: plain rounded switch
	var base := UIKit.c("accent") if on else Color(0, 0, 0, 0.4)
	draw_style_box(UIKit.style(base, int(h * 0.5)), r)
	var knob := Vector2(r.position.x + (h * 0.5 if not on else w - h * 0.5), r.position.y + h * 0.5)
	draw_circle(knob, h * 0.36, Color.WHITE)
