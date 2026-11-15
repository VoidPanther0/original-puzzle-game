class_name GameScreen
extends Control
## The play screen. Connects the GameState rules to views, handles drag and
## drop, and sequences the placement / clear / gravity animations.

signal menu_requested()

const SLOT_COUNT: int = 3

var state: GameState

var _board_holder: Control
var _board_view: BoardView
var _tray_row: HBoxContainer
var _slots: Array[PieceView] = []
var _drag_layer: Control
var _score_label: Label
var _best_label: Label
var _combo_label: Label
var _pause_button: Button
var _pause_dialog: OverlayDialog
var _over_dialog: OverlayDialog
var _margin: MarginContainer

var _drag_slot: int = -1
var _drag_view: PieceView = null
var _last_ghost_origin: Vector2i = Vector2i(-999, -999)
var _busy: bool = false
var _best_at_start: int = 0
var _settings_overlay: SettingsScreen = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	state = GameState.new()
	_build_ui()
	state.score_changed.connect(_on_score_changed)
	state.combo_changed.connect(_on_combo_changed)
	state.tray_changed.connect(_refresh_tray)
	state.game_over.connect(_on_game_over)
	Settings.changed.connect(_refresh_best)
	resized.connect(_relayout)
	_start_new_game(false)
	_relayout()
	UiTheme.fade_in(self)


# ------------------------------------------------------------------- build

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = SettingsScreen._background()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_margin = MarginContainer.new()
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	var inset: Vector4 = ScreenInsets.margins(self, 24)
	_margin.add_theme_constant_override("margin_left", int(inset.x))
	_margin.add_theme_constant_override("margin_top", int(inset.y))
	_margin.add_theme_constant_override("margin_right", int(inset.z))
	_margin.add_theme_constant_override("margin_bottom", int(inset.w))
	add_child(_margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	_margin.add_child(column)

	# Header: pause | score + combo | best
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)

	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.custom_minimum_size = Vector2(88, 88)
	_pause_button.add_theme_font_size_override("font_size", 36)
	_pause_button.pressed.connect(_open_pause)
	header.add_child(_pause_button)

	var score_box := VBoxContainer.new()
	score_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_box.add_theme_constant_override("separation", 0)
	header.add_child(score_box)
	_score_label = Label.new()
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 72)
	score_box.add_child(_score_label)
	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 28)
	_combo_label.add_theme_color_override("font_color", UiTheme.ACCENT)
	score_box.add_child(_combo_label)

	var best_box := VBoxContainer.new()
	best_box.custom_minimum_size = Vector2(120, 0)
	best_box.add_theme_constant_override("separation", 0)
	header.add_child(best_box)
	var best_title := Label.new()
	best_title.text = "BEST"
	best_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best_title.add_theme_font_size_override("font_size", 22)
	best_title.add_theme_color_override("font_color", UiTheme.TEXT_DIM)
	best_box.add_child(best_title)
	_best_label = Label.new()
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_best_label.add_theme_font_size_override("font_size", 38)
	_best_label.add_theme_color_override("font_color", UiTheme.GOLD)
	best_box.add_child(_best_label)

	# Board
	_board_holder = Control.new()
	_board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_holder.clip_contents = false
	_board_holder.resized.connect(_layout_board)
	column.add_child(_board_holder)

	_board_view = BoardView.new()
	_board_view.board_size = state.board.size
	_board_holder.add_child(_board_view)

	# Tray
	_tray_row = HBoxContainer.new()
	_tray_row.add_theme_constant_override("separation", 16)
	_tray_row.custom_minimum_size = Vector2(0, 170)
	column.add_child(_tray_row)
	for i: int in SLOT_COUNT:
		var slot := PieceView.new()
		slot.show_panel = true
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot.pressed.connect(_on_slot_pressed.bind(i))
		_tray_row.add_child(slot)
		_slots.append(slot)

	# Layers above everything
	_drag_layer = Control.new()
	_drag_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_drag_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_drag_layer)

	_pause_dialog = OverlayDialog.new()
	add_child(_pause_dialog)
	_over_dialog = OverlayDialog.new()
	add_child(_over_dialog)


func _relayout() -> void:
	# Taller tray on tall phones, but never more than a quarter of the screen.
	var tray_height: float = clampf(size.y * 0.16, 110.0, 230.0)
	_tray_row.custom_minimum_size = Vector2(0, tray_height)
	_layout_board()


func _layout_board() -> void:
	if _board_holder == null or _board_view == null:
		return
	var side: float = minf(_board_holder.size.x, _board_holder.size.y)
	_board_view.size = Vector2(side, side)
	_board_view.position = (_board_holder.size - Vector2(side, side)) / 2.0


# -------------------------------------------------------------- game flow

func _start_new_game(animate: bool) -> void:
	_cancel_drag()
	state.new_game()
	_best_at_start = Settings.best_score
	_board_view.display = state.board.cells.duplicate()
	_board_view.clear_ghost()
	_refresh_best()
	if animate:
		Sfx.play("click")


func _refresh_tray() -> void:
	for i: int in SLOT_COUNT:
		var piece: PieceData = state.tray[i] if i < state.tray.size() else null
		var slot: PieceView = _slots[i]
		var changed: bool = slot.piece != piece
		slot.piece = piece
		slot.hidden_piece = (i == _drag_slot and _drag_view != null)
		slot.blocked = piece != null and not state.board.can_fit_anywhere(piece.shape)
		if changed and piece != null:
			slot.pivot_offset = slot.size / 2.0
			slot.scale = Vector2(0.7, 0.7)
			var tween: Tween = slot.create_tween()
			tween.tween_property(slot, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_score_changed(score: int) -> void:
	_score_label.text = str(score)
	_score_label.pivot_offset = _score_label.size / 2.0
	var tween: Tween = _score_label.create_tween()
	_score_label.scale = Vector2(1.12, 1.12)
	tween.tween_property(_score_label, "scale", Vector2.ONE, 0.18)


func _on_combo_changed(combo: int) -> void:
	if combo >= 2:
		_combo_label.text = "COMBO x%d" % combo
	else:
		_combo_label.text = " "


func _refresh_best() -> void:
	_best_label.text = str(maxi(Settings.best_score, state.score))


# ------------------------------------------------------------------- input

func _on_slot_pressed(global_point: Vector2, slot: int) -> void:
	if _busy or state.is_over or _pause_dialog.visible or _over_dialog.visible:
		return
	if slot >= state.tray.size() or state.tray[slot] == null:
		return
	_drag_slot = slot
	var piece: PieceData = state.tray[slot]
	_drag_view = PieceView.new()
	_drag_view.piece = piece
	_drag_view.fixed_cell = _board_view.cell_px()
	_drag_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_view.size = Vector2(piece.width, piece.height) * _board_view.cell_px()
	_drag_view.pivot_offset = _drag_view.size / 2.0
	_drag_view.scale = Vector2(0.6, 0.6)
	_drag_layer.add_child(_drag_view)
	_slots[slot].hidden_piece = true
	var tween: Tween = _drag_view.create_tween()
	tween.tween_property(_drag_view, "scale", Vector2.ONE, 0.1)
	_last_ghost_origin = Vector2i(-999, -999)
	_move_drag(global_point)
	Sfx.play("pick")
	Haptics.light()


func _input(event: InputEvent) -> void:
	if _drag_view == null:
		return
	if event is InputEventMouseMotion:
		_move_drag((event as InputEventMouseMotion).global_position)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_move_drag(mb.global_position)
			_drop()
			get_viewport().set_input_as_handled()


## Where the dragged piece's top-left lands, as a board cell.
func _drag_origin_cell() -> Vector2i:
	var rel: Vector2 = _board_view.global_to_cell(_drag_view.global_position)
	return Vector2i(roundi(rel.x), roundi(rel.y))


func _move_drag(pointer: Vector2) -> void:
	var cell: float = _board_view.cell_px()
	var lift: float = cell * 1.8
	_drag_view.position = _drag_layer.get_global_transform().affine_inverse() * (pointer - _drag_view.size / 2.0 - Vector2(0, lift))
	var origin: Vector2i = _drag_origin_cell()
	if origin == _last_ghost_origin:
		return
	_last_ghost_origin = origin
	var piece: PieceData = state.tray[_drag_slot]
	if state.can_place_piece(_drag_slot, origin) and Settings.ghost_preview:
		var preview: BoardModel = state.board.duplicate_model()
		preview.place(piece.shape, piece.color_id, origin)
		_board_view.set_ghost(piece.shape, origin, piece.color_id, preview.full_rows())
	else:
		_board_view.clear_ghost()


func _drop() -> void:
	var slot: int = _drag_slot
	var origin: Vector2i = _drag_origin_cell()
	if state.can_place_piece(slot, origin):
		var view: PieceView = _drag_view
		_drag_view = null
		_drag_slot = -1
		view.queue_free()
		_board_view.clear_ghost()
		_commit_placement(slot, origin)
	else:
		_return_drag()


func _return_drag() -> void:
	Sfx.play("invalid")
	Haptics.light()
	_board_view.clear_ghost()
	var view: PieceView = _drag_view
	var slot_index: int = _drag_slot
	_drag_view = null
	_drag_slot = -1
	var slot: PieceView = _slots[slot_index]
	var target: Vector2 = slot.global_position + slot.size / 2.0 - view.size / 2.0
	var tween: Tween = view.create_tween().set_parallel(true)
	tween.tween_property(view, "global_position", target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "scale", Vector2(0.5, 0.5), 0.16)
	await tween.finished
	view.queue_free()
	slot.hidden_piece = false


func _cancel_drag() -> void:
	if _drag_view != null:
		_drag_view.queue_free()
		_drag_view = null
	_drag_slot = -1
	if _board_view != null:
		_board_view.clear_ghost()
	for slot: PieceView in _slots:
		slot.hidden_piece = false


# --------------------------------------------------------------- placement

func _commit_placement(slot: int, origin: Vector2i) -> void:
	_busy = true
	var result: Dictionary = state.place_piece(slot, origin)
	if not result["ok"]:
		_busy = false
		return

	var cleared: Array[int] = result["cleared_rows"]
	var moves: Array[Vector2i] = result["moves"]

	# 1. Show the board with the piece placed, before any rows vanish.
	_board_view.display = result["board_before_clear"]
	Sfx.play("place")
	Haptics.light()
	await _board_view.animate_pop(result["cells"])

	# 2. Rows clear, then gravity.
	if not cleared.is_empty():
		var combo: int = result["combo"]
		Sfx.play("combo" if combo >= 2 else "clear")
		Haptics.medium()
		_spawn_popup("+%d" % result["points"], combo)
		await _board_view.animate_clear(cleared)
		_board_view.display = state.board.cells.duplicate()
		await _board_view.animate_gravity(moves)
	else:
		_board_view.display = state.board.cells.duplicate()

	Settings.submit_score(state.score)
	_refresh_best()
	_busy = false

	if result["game_over"]:
		await get_tree().create_timer(0.35).timeout
		_show_game_over()


func _spawn_popup(text: String, combo: int) -> void:
	var label := Label.new()
	label.text = text if combo < 2 else "%s  x%d" % [text, combo]
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", UiTheme.GOLD if combo >= 2 else UiTheme.TEXT)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.15))
	label.add_theme_constant_override("outline_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drag_layer.add_child(label)
	var center: Vector2 = _board_view.global_position + _board_view.size / 2.0
	label.size = Vector2(500, 90)
	label.global_position = center - label.size / 2.0
	var tween: Tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 110.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


# --------------------------------------------------------------- dialogs

func _open_pause() -> void:
	if _busy or state.is_over or _over_dialog.visible:
		return
	_cancel_drag()
	Sfx.play("click")
	_pause_dialog.reset("Paused")
	_pause_dialog.add_line("Score  %d" % state.score)
	_pause_dialog.add_button("Resume", _close_pause, "PrimaryButton")
	_pause_dialog.add_button("Restart", func() -> void:
		_pause_dialog.close()
		_start_new_game(true))
	_pause_dialog.add_button("Settings", _open_settings)
	_pause_dialog.add_button("Main menu", func() -> void:
		Sfx.play("click")
		menu_requested.emit())
	_pause_dialog.open()


func _close_pause() -> void:
	Sfx.play("click")
	_pause_dialog.close()


func _open_settings() -> void:
	Sfx.play("click")
	_settings_overlay = SettingsScreen.new()
	_settings_overlay.back_pressed.connect(func() -> void:
		_settings_overlay.queue_free()
		_settings_overlay = null)
	add_child(_settings_overlay)


func _show_game_over() -> void:
	Sfx.play("gameover")
	Haptics.heavy()
	var is_new_best: bool = state.score > _best_at_start and state.score > 0
	_over_dialog.reset("Game over", UiTheme.DANGER)
	_over_dialog.add_line("Score", 26)
	_over_dialog.add_line(str(state.score), 76, UiTheme.TEXT)
	if is_new_best:
		_over_dialog.add_line("New best score!", 34, UiTheme.GOLD)
	else:
		_over_dialog.add_line("Best  %d" % Settings.best_score, 30, UiTheme.GOLD)
	_over_dialog.add_button("Play again", func() -> void:
		_over_dialog.close()
		_start_new_game(true), "PrimaryButton")
	_over_dialog.add_button("Main menu", func() -> void:
		Sfx.play("click")
		menu_requested.emit())
	_over_dialog.open()


func _on_game_over() -> void:
	# The dialog appears after the last animation (see _commit_placement).
	pass


## Android back button / Escape.
func handle_back() -> void:
	if _settings_overlay != null:
		_settings_overlay.queue_free()
		_settings_overlay = null
	elif _pause_dialog.visible:
		_close_pause()
	elif _over_dialog.visible:
		menu_requested.emit()
	else:
		_open_pause()
