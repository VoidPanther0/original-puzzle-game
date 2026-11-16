class_name MoveSolver
extends RefCounted
## Enumerates and ranks moves; checks whether a whole tray can still be played out.

## Every legal move: [{index, anchor:Vector2i(x=col,y=row), lines}]
static func all_moves(board: Board, pieces: Array) -> Array:
	var out: Array = []
	for i in pieces.size():
		var piece = pieces[i]
		if piece == null: continue
		for a in PlacementValidator.all_positions(board, piece):
			var pv := LineClearManager.preview(board, piece, a.y, a.x)
			out.append({"index": i, "anchor": a, "lines": pv.lines})
	return out

## Best move by (lines cleared, snugness, fewer holes). {} when no move exists.
static func best_move(board: Board, pieces: Array) -> Dictionary:
	var best := {}
	var best_s := -INF
	for m in all_moves(board, pieces):
		var piece: Dictionary = pieces[m.index]
		var b := board.copy()
		b.place(piece, m.anchor.y, m.anchor.x)
		LineClearManager.resolve(b)
		var s: float = m.lines * 20.0 + BoardEvaluator.fit_score(board, piece, m.anchor.y, m.anchor.x) \
			- BoardEvaluator.count_holes(b) * 5.0 - BoardEvaluator.fill_ratio(b) * 10.0
		if s > best_s:
			best_s = s
			best = m
	return best

## True if the remaining pieces can ALL be placed in some order (with line clears applied between).
static func tray_playable_in_full(board: Board, pieces: Array) -> bool:
	var remaining: Array = []
	for p in pieces:
		if p != null: remaining.append(p)
	return _dfs(board, remaining)

static func _dfs(board: Board, remaining: Array) -> bool:
	if remaining.is_empty(): return true
	for i in remaining.size():
		var piece: Dictionary = remaining[i]
		var rest := remaining.duplicate()
		rest.remove_at(i)
		for a in PlacementValidator.all_positions(board, piece):
			var b := board.copy()
			b.place(piece, a.y, a.x)
			LineClearManager.resolve(b)
			if _dfs(b, rest): return true
	return false
