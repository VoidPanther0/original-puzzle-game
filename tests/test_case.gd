class_name TestCase
extends RefCounted
## Minimal assertion base. Test methods are named test_* and report through check().

var failures: Array = []
var checks := 0
var tree: SceneTree

func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures.append(msg)

func eq(actual, expected, msg: String) -> void:
	checks += 1
	if actual != expected:
		failures.append("%s (expected %s, got %s)" % [msg, str(expected), str(actual)])

func piece(id: String) -> Dictionary:
	return PieceDB.get_piece(id)

func fill_row(b: Board, r: int, except_col: int = -1) -> void:
	for c in Board.SIZE:
		if c != except_col: b.set_cell(r, c, 1)

func fill_col(b: Board, c: int, except_row: int = -1) -> void:
	for r in Board.SIZE:
		if r != except_row: b.set_cell(r, c, 1)
