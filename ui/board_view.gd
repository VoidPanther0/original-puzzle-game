class_name BoardView
extends Control
## Renders the 8x8 board + 3-piece tray and handles mouse/touch drag & drop. Pointer events are
## mouse events on every platform (Android touch is emulated as mouse by the engine), so one input
## path serves Android, Windows and Web. All rules live in GameSession; this is presentation only.

signal moved(result: Dictionary)
signal cell_tapped(row: int, col: int)

const LIFT_CELLS := 1.7
const FALL_TIME := 0.34     # seconds for a gravity fall     # dragged piece floats above the finger so it stays visible

var session: GameSession
var hammer_mode := false
var input_enabled := true

var cell := 40.0
var board_rect := Rect2()
var _slot_rects: Array = []
var _tray_cs := 20.0

var _drag := -1
var _drag_pos := Vector2.ZERO
var _snap := Vector2i(-1, -1)
var _preview_cells := {}
var _return_from := Vector2.ZERO
var _return_slot := -1
var _return_t0 := -1.0

var _pop := {}              # cell idx -> t0 (sec)
var _clearing: Array = []   # {idx, color, t0}
var _particles: Array = []  # {p, v, color, t0, life, size}
var _popups: Array = []     # {text, pos, t0, color, size}
var _falls: Array = []      # gravity: {from, to, color, t0}
var _fall_to := {}          # destination idx -> true while its block is still falling
var _cracks := {}           # cell idx -> crack lines (normalised 0..1 cell space), drawn by hand
var _tray_t0 := 0.0
var _shake_t0 := -10.0
var _sb := StyleBoxFlat.new()
var _gloss := StyleBoxFlat.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_gloss.bg_color = Color(1, 1, 1, 0.28)
	resized.connect(_relayout)
	_relayout()
	set_process(false)

func bind(s: GameSession) -> void:
	session = s
	_tray_t0 = _now()
	_kick()
	queue_redraw()

static func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _relayout() -> void:
	var side := minf(size.x, size.y * 0.66) * 0.97
	cell = floorf(side / 8.0)
	side = cell * 8.0
	board_rect = Rect2(Vector2((size.x - side) / 2.0, 6.0), Vector2(side, side))
	_slot_rects.clear()
	var tray_top := board_rect.end.y + cell * 0.45
	var slot_w := side / 3.0
	var slot_h := maxf(cell * 3.2, size.y - tray_top)
	for i in 3:
		_slot_rects.append(Rect2(Vector2(board_rect.position.x + i * slot_w, tray_top), Vector2(slot_w, slot_h)))
	_tray_cs = minf(cell * 0.72, slot_w / 5.2)
	var r := int(cell * 0.2)
	_sb.set_corner_radius_all(r)
	_sb.set_border_width_all(maxi(2, int(cell * 0.05)))
	_gloss.set_corner_radius_all(maxi(2, int(cell * 0.12)))
	queue_redraw()

# ---------------------------------------------------------------- input
func _gui_input(event: InputEvent) -> void:
	if session == null or not input_enabled: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _press(event.position)
		else: _release(event.position)
	elif event is InputEventMouseMotion and _drag >= 0:
		_drag_pos = event.position
		_update_snap()
		queue_redraw()

func _press(pos: Vector2) -> void:
	if hammer_mode:
		var rc := _cell_at(pos)
		if rc.x >= 0: cell_tapped.emit(rc.y, rc.x)   # row, col
		return
	# tapping a block on the board shoots it (1st hit cracks it, 2nd hit destroys it)
	var bc := _cell_at(pos)
	if bc.x >= 0:
		cell_tapped.emit(bc.y, bc.x)
		return
	for i in 3:
		if session.tray[i] != null and _slot_rects[i].grow(cell * 0.2).has_point(pos):
			_drag = i
			_drag_pos = pos
			AudioManager.play("pickup")
			Platform.vibrate(8)
			_update_snap()
			queue_redraw()
			return

func _release(pos: Vector2) -> void:
	if _drag < 0: return
	_drag_pos = pos
	_update_snap()
	var idx := _drag
	var piece: Dictionary = session.tray[idx]
	if _snap.x >= 0:
		var anchor := _snap
		_drag = -1
		_snap = Vector2i(-1, -1)
		_preview_cells.clear()
		_commit(idx, piece, anchor.y, anchor.x)
	else:
		AudioManager.play("invalid")
		Platform.vibrate(25)
		_shake_t0 = _now()
		_return_from = _piece_top_left(piece)
		_return_slot = idx
		_return_t0 = _now()
		_drag = -1
		_preview_cells.clear()
		_kick()
	queue_redraw()

func _cell_at(pos: Vector2) -> Vector2i:
	if not board_rect.has_point(pos): return Vector2i(-1, -1)
	return Vector2i(int((pos.x - board_rect.position.x) / cell), int((pos.y - board_rect.position.y) / cell))

func _piece_top_left(piece: Dictionary) -> Vector2:
	var px := Vector2(piece.w, piece.h) * cell
	return _drag_pos - px / 2.0 - Vector2(0, cell * LIFT_CELLS)

func _update_snap() -> void:
	if _drag < 0 or session.tray[_drag] == null: return
	var piece: Dictionary = session.tray[_drag]
	var tl := _piece_top_left(piece)
	var fr := (tl.y - board_rect.position.y) / cell
	var fc := (tl.x - board_rect.position.x) / cell
	var snap := PlacementValidator.snap(session.board, piece, fr, fc, 1.25)
	if snap != _snap:
		_snap = snap
		_preview_cells.clear()
		if snap.x >= 0:
			for i in LineClearManager.preview(session.board, piece, snap.y, snap.x).cells:
				_preview_cells[i] = true

func _commit(idx: int, piece: Dictionary, row: int, col: int) -> void:
	var res := session.place(idx, row, col)
	if not res.ok: return
	var now := _now()
	for p in piece.cells:
		_pop[Board.idx(row + p.y, col + p.x)] = now
	var lines: int = res.clear.lines
	if lines > 0:
		for i in res.clear.cells:
			_clearing.append({"idx": i, "color": res.clear.colors[i], "t0": now})
			_burst(i, int(res.clear.colors[i]), 3)
		var gained: int = res.score.gained
		var ctr := board_rect.get_center()
		_popups.append({"text": "+%d" % gained, "pos": ctr, "t0": now, "color": Color("ffe066"), "size": int(cell * 0.9)})
		var combo: int = res.score.combo
		if combo >= 2:
			_popups.append({"text": "COMBO x%d" % combo, "pos": ctr + Vector2(0, -cell * 1.1), "t0": now, "color": Color("ff9ff3"), "size": int(cell * 0.8)})
		if lines >= 2:
			_popups.append({"text": ["", "", "DOUBLE!", "TRIPLE!", "QUAD!", "AMAZING!"][mini(lines, 5)], "pos": ctr + Vector2(0, cell * 1.1), "t0": now, "color": Color("74f0ff"), "size": int(cell * 0.75)})
		AudioManager.play("combo" if combo >= 2 or lines >= 2 else "clear")
		Platform.vibrate(40 if lines < 2 else 70)
		if res.board_cleared:
			_popups.append({"text": "PERFECT CLEAR!", "pos": ctr + Vector2(0, cell * 2.3), "t0": now, "color": Color("69f0ae"), "size": int(cell * 0.8)})
	else:
		AudioManager.play("place")
		Platform.vibrate(12)
	if lines > 0: fx_falls(res.clear.falls)
	if res.tray_refreshed: _tray_t0 = now
	_kick()
	moved.emit(res)
	queue_redraw()

## Called by the game screen after the hammer / other board edits.
func fx_cell_removed(row: int, col: int, color: int) -> void:
	_burst(Board.idx(row, col), color, 6)
	_clearing.append({"idx": Board.idx(row, col), "color": color, "t0": _now()})
	_kick()

## A stone block was hit once: it now shows hand-drawn cracks (1st shot of the 2).
func fx_cell_cracked(row: int, col: int) -> void:
	var idx := Board.idx(row, col)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9000 + idx * 7919
	var lines: Array = []
	for k in 3:
		var a := rng.randf() * TAU
		var p := Vector2(0.5, 0.5)
		var pts := PackedVector2Array([p])
		for st in 3:
			a += rng.randf_range(-0.9, 0.9)
			p += Vector2(cos(a), sin(a)) * (0.13 + rng.randf() * 0.09)
			pts.append(p)
		lines.append(pts)
	_cracks[idx] = lines
	_shake_t0 = _now()
	_kick()

## Cracks of a destroyed block are not drawn any more.
func fx_cell_destroyed(row: int, col: int) -> void:
	_cracks.erase(Board.idx(row, col))

## Draws the crack overlay of a cell (hand made, no extra art needed).
func _draw_cracks(idx: int, rect: Rect2) -> void:
	if not _cracks.has(idx): return
	var w := maxf(2.0, rect.size.x * 0.055)
	for pts in _cracks[idx]:
		var out := PackedVector2Array()
		for p in pts: out.append(rect.position + p * rect.size)
		draw_polyline(out, Color(0.04, 0.04, 0.08, 0.9), w, true)
		draw_polyline(out, Color(1, 1, 1, 0.35), maxf(1.0, w * 0.35), true)

## Gravity animation: blocks glide down after the clear flash (starts 0.28 s later).
func fx_falls(falls: Array) -> void:
	var t0 := _now() + 0.28
	for f in falls:
		_falls.append({"from": int(f.from), "to": int(f.to), "color": int(f.color), "t0": t0})
		_fall_to[int(f.to)] = true
	if not falls.is_empty():
		AudioManager.play("place")
		_kick()

func fx_tray_refreshed() -> void:
	_tray_t0 = _now()
	_kick()

func _burst(idx: int, color_idx: int, n: int) -> void:
	if _particles.size() > 220: return
	var r := idx / Board.SIZE
	var c := idx % Board.SIZE
	var ctr := board_rect.position + Vector2((c + 0.5) * cell, (r + 0.5) * cell)
	var col: Color = UIKit.BLOCK_COLORS[clampi(color_idx, 1, 9)]
	for i in n:
		var ang := randf() * TAU
		var spd := cell * (2.0 + randf() * 4.0)
		_particles.append({"p": ctr, "v": Vector2(cos(ang), sin(ang)) * spd, "color": col, "t0": _now(),
			"life": 0.45 + randf() * 0.35, "size": cell * (0.07 + randf() * 0.1)})

func _kick() -> void:
	set_process(true)

func _process(delta: float) -> void:
	var now := _now()
	var busy := false
	for k in _pop.keys():
		if now - _pop[k] > 0.25: _pop.erase(k)
		else: busy = true
	_clearing = _clearing.filter(func(c): return now - c.t0 < 0.38)
	_popups = _popups.filter(func(p): return now - p.t0 < 1.1)
	_falls = _falls.filter(func(f): return now < f.t0 + FALL_TIME)
	if _falls.is_empty(): _fall_to.clear()
	else: busy = true
	for p in _particles:
		p.p += p.v * delta
		p.v.y += cell * 9.0 * delta
	_particles = _particles.filter(func(p): return now - p.t0 < p.life)
	if not _clearing.is_empty() or not _popups.is_empty() or not _particles.is_empty(): busy = true
	if _return_t0 >= 0.0:
		if now - _return_t0 > 0.18: _return_t0 = -1.0
		else: busy = true
	if now - _tray_t0 < 0.3 or now - _shake_t0 < 0.3: busy = true
	queue_redraw()
	if not busy and _drag < 0: set_process(false)

# ---------------------------------------------------------------- drawing
func block(r: Rect2, color_idx: int, alpha: float = 1.0, lighten: float = 0.0) -> void:
	var gem := UIKit.tex("gem_%d" % color_idx) if color_idx <= 9 else null
	if gem != null:
		var m := Color(1, 1, 1, alpha)
		if lighten > 0.0: m = Color(1 + lighten, 1 + lighten, 1 + lighten, alpha)
		draw_texture_rect(gem, r.grow(-r.size.x * 0.02), false, m)
		return
	var base: Color = UIKit.BLOCK_COLORS[clampi(color_idx, 1, 9)]
	base = base.lightened(lighten)
	base.a = alpha
	_sb.bg_color = base
	var edge := base.darkened(0.25)
	edge.a = alpha
	_sb.border_color = edge
	var rr := r.grow(-r.size.x * 0.04)
	draw_style_box(_sb, rr)
	var g := Rect2(rr.position + Vector2(rr.size.x * 0.14, rr.size.y * 0.1), Vector2(rr.size.x * 0.72, rr.size.y * 0.3))
	_gloss.bg_color = Color(1, 1, 1, 0.3 * alpha)
	draw_style_box(_gloss, g)

func _draw_piece(piece: Dictionary, top_left: Vector2, cs: float, alpha: float = 1.0) -> void:
	for p in piece.cells:
		block(Rect2(top_left + Vector2(p.x, p.y) * cs, Vector2(cs, cs)), piece.color, alpha)

func _draw() -> void:
	if session == null: return
	var now := _now()
	var shake := Vector2.ZERO
	if now - _shake_t0 < 0.25:
		shake = Vector2(sin((now - _shake_t0) * 70.0) * cell * 0.08, 0)
	# board background
	var bb := UIKit.style(UIKit.c("board"), int(cell * 0.35))
	var bbr := board_rect.grow(cell * 0.14)
	draw_style_box(bb, Rect2(bbr.position + shake, bbr.size))
	var slot := UIKit.style(UIKit.c("cell"), int(cell * 0.18))
	for r in Board.SIZE:
		for c in Board.SIZE:
			var rect := Rect2(board_rect.position + Vector2(c, r) * cell + shake, Vector2(cell, cell)).grow(-cell * 0.04)
			var v := session.board.get_cell(r, c)
			if v == 0 or _fall_to.has(Board.idx(r, c)):
				draw_style_box(slot, rect)
			else:
				var i := Board.idx(r, c)
				var rr := Rect2(board_rect.position + Vector2(c, r) * cell + shake, Vector2(cell, cell))
				if _pop.has(i):
					var t := clampf((now - _pop[i]) / 0.22, 0.0, 1.0)
					var s := 1.0 + 0.22 * sin(t * PI)
					rr = Rect2(rr.get_center() - rr.size * s / 2.0, rr.size * s)
				var lighten := 0.35 if _preview_cells.has(i) else 0.0
				block(rr, v, 1.0, lighten)
				if _cracks.has(i):
					_draw_cracks(i, Rect2(rr.position + shake, rr.size))
	# preview highlight for lines that would clear (empty cells in those lines glow)
	if _drag >= 0 and _snap.x >= 0:
		var piece: Dictionary = session.tray[_drag]
		var pulse := 0.25 + 0.15 * sin(now * 10.0)
		for p in piece.cells:
			var rect := Rect2(board_rect.position + Vector2(_snap.x + p.x, _snap.y + p.y) * cell, Vector2(cell, cell))
			block(rect, piece.color, 0.45 + pulse)
		for i in _preview_cells:
			var rect2 := Rect2(board_rect.position + Vector2(i % Board.SIZE, i / Board.SIZE) * cell, Vector2(cell, cell)).grow(-cell * 0.04)
			draw_rect(rect2, Color(1, 1, 1, pulse), false, 3.0)
	# clearing ghosts
	for g in _clearing:
		var t: float = clampf((now - g.t0) / 0.38, 0.0, 1.0)
		var r := int(g.idx) / Board.SIZE
		var c := int(g.idx) % Board.SIZE
		var base := Rect2(board_rect.position + Vector2(c, r) * cell, Vector2(cell, cell))
		var s := 1.0 - t * 0.9
		var rr := Rect2(base.get_center() - base.size * s / 2.0, base.size * s)
		block(rr, int(g.color), 1.0 - t * 0.5, 0.5 * (1.0 - t))
	# falling blocks (gravity)
	for f in _falls:
		var k := clampf((now - float(f.t0)) / FALL_TIME, 0.0, 1.0)
		k = k * k                      # accelerate like real falling
		var a := Vector2(int(f.from) % Board.SIZE, int(f.from) / Board.SIZE)
		var b := Vector2(int(f.to) % Board.SIZE, int(f.to) / Board.SIZE)
		var pos := board_rect.position + a.lerp(b, k) * cell + shake
		block(Rect2(pos, Vector2(cell, cell)), int(f.color))
	# tray
	var tray_t := clampf((now - _tray_t0) / 0.28, 0.0, 1.0)
	for i in 3:
		var piece = session.tray[i]
		if piece == null or i == _drag: continue
		var sr: Rect2 = _slot_rects[i]
		var cs := _tray_cs * (0.55 + 0.45 * tray_t)
		var tl := sr.position + Vector2((sr.size.x - piece.w * cs) / 2.0, cell * 1.6 - piece.h * cs / 2.0)
		var playable := PlacementValidator.can_place_anywhere(session.board, piece)
		var a := (1.0 if playable else 0.35) * tray_t
		if _return_slot == i and _return_t0 >= 0.0:
			var k := clampf((now - _return_t0) / 0.18, 0.0, 1.0)
			var cs2 := lerpf(cell, cs, k)
			tl = _return_from.lerp(tl, k)
			_draw_piece(piece, tl, cs2, a)
		else:
			_draw_piece(piece, tl, cs, a)
	# dragged piece
	if _drag >= 0 and session.tray[_drag] != null:
		_draw_piece(session.tray[_drag], _piece_top_left(session.tray[_drag]), cell, 0.95)
	# particles
	for p in _particles:
		var k: float = 1.0 - (now - float(p.t0)) / float(p.life)
		var col: Color = p.color
		col.a = clampf(k, 0.0, 1.0)
		draw_circle(p.p, p.size * (0.4 + k), col)
	# popups
	var font := ThemeDB.fallback_font
	for p in _popups:
		var t: float = (now - float(p.t0)) / 1.1
		var col: Color = p.color
		col.a = 1.0 - clampf((t - 0.5) * 2.0, 0.0, 1.0)
		var sz: int = maxi(8, int(p.size))
		var w := font.get_string_size(p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x
		var pos: Vector2 = p.pos + Vector2(-w / 2.0, -t * cell * 1.5)
		draw_string_outline(font, pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, 8, Color(0, 0, 0, col.a * 0.7))
		draw_string(font, pos, p.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	if hammer_mode:
		draw_rect(board_rect.grow(cell * 0.14), Color("ffb84d"), false, 4.0)
