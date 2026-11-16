class_name GameSession
extends RefCounted
## Pure game logic (no nodes, no platform calls). Everything the UI needs goes through here.

const TRAY_SIZE := 3

## Stone blocks (colour 9) are the pre-filled obstacles of a level. They can be shot away:
## the first shot cracks them, the second one destroys them (a charge is spent on the destroy).
const STONE := 9
const SHOTS_PER_GAME := 5          # level / daily
const SHOTS_PER_ENDLESS := 3       # endless has no stone blocks, so fewer charges

## Booster behaviour is data-driven so it can be tuned/overridden (e.g. by remote config).
## cost_coins: price in the shop; game_limit: max uses per game (0 = unlimited).
const BOOSTER_CFG := {
	"hammer": {"cost_coins": 150, "game_limit": 3, "ad_reward": 1},
	"refresh": {"cost_coins": 100, "game_limit": 3, "ad_reward": 1},
	"shuffle": {"cost_coins": 80, "game_limit": 3, "ad_reward": 1},
}

var board := Board.new()
var tray: Array = [null, null, null]
var scoring := ScoringManager.new()
var generator: PieceGenerator
var mode := "endless"                 # endless | level | daily
var level := {}                       # level config dict for mode == "level"
var seed_value := 0
var moves := 0
var game_over := false
var level_complete := false
var continues_used := 0
var booster_used := {"hammer": 0, "refresh": 0, "shuffle": 0}
var booster_cfg := BOOSTER_CFG.duplicate(true)
var gravity := true                  # rules v2: blocks fall after clears
var last_falls: Array = []            # falls caused by the most recent hammer (for animation)
var event_log: Array = []                   # replayable event log for server-side score validation
var shots := 0                          # remaining shots in this game
var cracked := {}                       # cell idx -> true : stone hit once, not destroyed yet

func _init(seed_in: int = 0, mode_in: String = "endless", level_in: Dictionary = {}) -> void:
	seed_value = seed_in
	mode = mode_in
	level = level_in
	shots = SHOTS_PER_ENDLESS if mode_in == "endless" else SHOTS_PER_GAME
	var pool: Array = level.get("pool", [])
	generator = PieceGenerator.new(seed_value, pool)
	generator.difficulty = float(level.get("difficulty", 0.2))
	_apply_start_layout()
	refill_tray()

func _apply_start_layout() -> void:
	var layout: Array = level.get("start_cells", [])
	for rc in layout:
		if rc.size() >= 2 and Board.in_bounds(int(rc[0]), int(rc[1])):
			board.set_cell(int(rc[0]), int(rc[1]), 9)
	if gravity: LineClearManager.gravity(board)

func refill_tray() -> void:
	tray = generator.generate_tray(board, TRAY_SIZE)
	_log_tray()
	_check_game_over()

func _log_tray() -> void:
	var ids: Array = []
	for p in tray: ids.append(p.id if p != null else "")
	event_log.append({"t": "tray", "ids": ids})

func remaining_pieces() -> Array:
	var out: Array = []
	for p in tray:
		if p != null: out.append(p)
	return out

func can_place(tray_index: int, row: int, col: int) -> bool:
	if game_over or tray_index < 0 or tray_index >= tray.size() or tray[tray_index] == null:
		return false
	return board.can_place(tray[tray_index], row, col)

## Places a tray piece. Returns a result dictionary; result.ok == false means nothing changed.
func place(tray_index: int, row: int, col: int) -> Dictionary:
	if not can_place(tray_index, row, col):
		return {"ok": false}
	var piece: Dictionary = tray[tray_index]
	event_log.append({"t": "p", "i": tray_index, "r": row, "c": col})
	board.place(piece, row, col)
	var clear := LineClearManager.resolve(board) if gravity else LineClearManager.clear(board)
	var board_cleared: bool = int(clear.lines) > 0 and board.is_empty()
	var sc := scoring.apply_move(piece.size, clear.lines, board_cleared)
	tray[tray_index] = null
	moves += 1
	var refreshed := false
	if remaining_pieces().is_empty():
		refill_tray()
		refreshed = true
	_check_level_goal()
	_check_game_over()
	return {"ok": true, "piece": piece, "row": row, "col": col, "clear": clear, "score": sc,
		"board_cleared": board_cleared, "tray_refreshed": refreshed,
		"game_over": game_over, "level_complete": level_complete}

func _check_game_over() -> void:
	if level_complete: return
	game_over = DeathDetector.is_dead(board, tray)

func _check_level_goal() -> void:
	if mode != "level" and mode != "daily": return
	var goal: Dictionary = level.get("goal", {})
	if goal.is_empty(): return
	match str(goal.get("type", "score")):
		"score": level_complete = scoring.score >= int(goal.target)
		"lines": level_complete = scoring.lines_cleared >= int(goal.target)
	if level_complete: game_over = false

## 0..3 stars for the current score on a level (thresholds in level.stars).
func stars() -> int:
	var th: Array = level.get("stars", [])
	var n := 0
	for t in th:
		if scoring.score >= int(t): n += 1
	return n if level_complete else 0

# ---- shooting (stone blocks) ------------------------------------------------------------------
## Only stone blocks can be shot: they are the obstacles that block a line.
func is_shootable(row: int, col: int) -> bool:
	if game_over or not Board.in_bounds(row, col): return false
	return board.get_cell(row, col) == STONE

## True when the board still holds stone blocks (the shot ability is only shown then).
func has_stone() -> bool:
	for v in board.cells:
		if v == STONE: return true
	return false

## Shot 1 cracks a stone block, shot 2 destroys it. A charge is only spent on the destroy.
## Returns {ok, cracked, destroyed, row, col, clear?}.
func shoot(row: int, col: int) -> Dictionary:
	if not is_shootable(row, col): return {"ok": false}
	if shots <= 0: return {"ok": false, "reason": "no_shots"}
	var idx := Board.idx(row, col)
	if not cracked.has(idx):
		cracked[idx] = true
		return {"ok": true, "cracked": true, "destroyed": false, "row": row, "col": col}
	shots -= 1
	cracked.erase(idx)
	board.set_cell(row, col, 0)
	event_log.append({"t": "s", "r": row, "c": col})
	var res := {"ok": true, "cracked": false, "destroyed": true, "row": row, "col": col}
	last_falls = []              # a broken block does not move the blocks above it
	_check_game_over()
	return res

# ---- boosters -------------------------------------------------------------------------------
func booster_remaining(name: String) -> int:
	var lim: int = int(booster_cfg[name].game_limit)
	return 999 if lim == 0 else maxi(0, lim - int(booster_used[name]))

func can_use_booster(name: String) -> bool:
	return not game_over and booster_cfg.has(name) and booster_remaining(name) > 0

## Hammer: breaks exactly ONE block. Nothing falls - the board keeps its shape.
func use_hammer(row: int, col: int) -> bool:
	if not can_use_booster("hammer") or not Board.in_bounds(row, col) or not board.is_occupied(row, col):
		return false
	board.set_cell(row, col, 0)
	event_log.append({"t": "h", "r": row, "c": col})
	last_falls = []              # a broken block does not move the blocks above it
	booster_used["hammer"] += 1
	_check_game_over()
	return true

## Refresh: discards the whole tray and deals three brand-new pieces.
func use_refresh() -> bool:
	if not can_use_booster("refresh"): return false
	booster_used["refresh"] += 1
	refill_tray()
	return true

## Shuffle: re-rolls only the pieces that are still unused (keeps empty slots empty).
func use_shuffle() -> bool:
	if not can_use_booster("shuffle"): return false
	var keep_empty: Array = []
	for i in tray.size():
		if tray[i] == null: keep_empty.append(i)
	if keep_empty.size() == tray.size(): return false
	var fresh := generator.generate_tray(board, TRAY_SIZE)
	for i in tray.size():
		tray[i] = null if i in keep_empty else fresh[i]
	_log_tray()
	booster_used["shuffle"] += 1
	_check_game_over()
	return true

## Revive after game over (rewarded ad / coins): clears the two fullest rows and deals a new tray.
func continue_game() -> bool:
	if not game_over: return false
	var counts: Array = []
	for r in Board.SIZE:
		var n := 0
		for c in Board.SIZE:
			if board.is_occupied(r, c): n += 1
		counts.append([n, r])
	# deterministic tie-break (lower row first) so the server can replay this exactly
	counts.sort_custom(func(a, b): return a[0] > b[0] or (a[0] == b[0] and a[1] < b[1]))
	for i in 2:
		for c in Board.SIZE: board.set_cell(counts[i][1], c, 0)
	if gravity: LineClearManager.resolve(board, true)
	event_log.append({"t": "c"})
	continues_used += 1
	game_over = false
	refill_tray()
	return not game_over

# ---- persistence ----------------------------------------------------------------------------
func to_dict() -> Dictionary:
	var t: Array = []
	for p in tray: t.append(p.id if p != null else "")
	return {"board": board.to_array(), "tray": t, "score": scoring.score, "combo": scoring.combo,
		"best_combo": scoring.best_combo, "lines": scoring.lines_cleared, "moves": moves, "mode": mode,
		"level": level, "seed": seed_value, "used": booster_used.duplicate(), "continues": continues_used,
		"rng_state": str(generator.rng.state), "log": event_log, "shots": shots, "cracked": cracked.keys()}

static func from_dict(d: Dictionary) -> GameSession:
	var s := GameSession.new(int(d.get("seed", 0)), str(d.get("mode", "endless")), d.get("level", {}))
	if not s.board.from_array(d.get("board", [])): return null
	s.tray = []
	for id in d.get("tray", []):
		s.tray.append(PieceDB.get_piece(str(id)) if str(id) != "" else null)
	while s.tray.size() < TRAY_SIZE: s.tray.append(null)
	s.scoring.score = int(d.get("score", 0))
	s.scoring.combo = int(d.get("combo", 0))
	s.scoring.best_combo = int(d.get("best_combo", 0))
	s.scoring.lines_cleared = int(d.get("lines", 0))
	s.moves = int(d.get("moves", 0))
	s.continues_used = int(d.get("continues", 0))
	var used: Dictionary = d.get("used", {})
	for k in used: s.booster_used[k] = int(used[k])
	s.generator.rng.state = str(d.get("rng_state", str(s.generator.rng.state))).to_int()
	s.event_log = d.get("log", [])
	s.shots = int(d.get("shots", SHOTS_PER_ENDLESS if s.mode == "endless" else SHOTS_PER_GAME))
	s.cracked = {}
	for i in d.get("cracked", []): s.cracked[int(i)] = true
	s._check_game_over()
	return s
