class_name ScreenInsets
extends RefCounted
## Margins that keep UI clear of notches and system bars.


## Returns Vector4(left, top, right, bottom) in this control's coordinates,
## never smaller than `minimum`.
static func margins(control: Control, minimum: float) -> Vector4:
	var result := Vector4(minimum, minimum, minimum, minimum)
	var window: Window = control.get_window()
	if window == null:
		return result
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.screen_get_size()
	if safe.size.x <= 0 or safe.size.y <= 0 or screen_size.x <= 0 or screen_size.y <= 0:
		return result
	if not OS.has_feature("mobile"):
		return result
	# Convert physical pixels to the stretched viewport's units.
	var view_size: Vector2 = window.get_visible_rect().size
	var sx: float = view_size.x / float(screen_size.x)
	var sy: float = view_size.y / float(screen_size.y)
	result.x = maxf(minimum, float(safe.position.x) * sx)
	result.y = maxf(minimum, float(safe.position.y) * sy)
	result.z = maxf(minimum, float(screen_size.x - safe.end.x) * sx)
	result.w = maxf(minimum, float(screen_size.y - safe.end.y) * sy)
	return result
