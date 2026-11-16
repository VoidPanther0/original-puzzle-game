extends Node
## Progression, economy and the active GameSession. UI talks to this; this talks to SaveManager.

signal changed
signal achievement_unlocked(id: String)

var session: GameSession
var current_level_id := ""        # "" for endless
var last_result := {}             # summary of the last finished game (for game-over/level screens)

func _ready() -> void:
	LevelDB.load_data()

# ---- helpers --------------------------------------------------------------------------------
func d() -> Dictionary:
	return SaveManager.data

func today() -> String:
	var t := Time.get_date_dict_from_system(true)
	return "%04d-%02d-%02d" % [t.year, t.month, t.day]

func day_number() -> int:
	return int(Time.get_unix_time_from_system() / 86400.0)

func _dirty() -> void:
	SaveManager.mark_dirty()
	changed.emit()

# ---- currency & boosters --------------------------------------------------------------------
func currency(kind: String) -> int:
	return int(d()[kind])

func add_currency(kind: String, n: int) -> void:
	d()[kind] = maxi(0, int(d()[kind]) + n)
	_dirty()

func spend(kind: String, n: int) -> bool:
	if int(d()[kind]) < n: return false
	d()[kind] = int(d()[kind]) - n
	_dirty()
	return true

func booster_count(name: String) -> int:
	return int(d().boosters.get(name, 0))

func add_booster(name: String, n: int = 1) -> void:
	d().boosters[name] = booster_count(name) + n
	_dirty()

func consume_booster(name: String) -> bool:
	if booster_count(name) <= 0: return false
	d().boosters[name] = booster_count(name) - 1
	_dirty()
	return true

## Buys a booster with coins at the session's configured price.
func buy_booster_with_coins(name: String) -> bool:
	var price: int = int(GameSession.BOOSTER_CFG[name].cost_coins)
	if not spend("coins", price): return false
	add_booster(name, 1)
	return true

## Grants a reward dictionary: {coins, gems, booster, n, hammer, refresh, shuffle, ads_removed}.
func apply_reward(r: Dictionary) -> void:
	if r.has("coins"): add_currency("coins", int(r.coins))
	if r.has("gems"): add_currency("gems", int(r.gems))
	if r.has("booster"): add_booster(str(r.booster), int(r.get("n", 1)))
	for k in ["hammer", "refresh", "shuffle"]:
		if r.has(k): add_booster(k, int(r[k]))
	if r.has("ads_removed"):
		d().purchases["ads_removed"] = bool(r.ads_removed)
		_dirty()

func reward_text(r: Dictionary) -> String:
	var parts: Array = []
	if r.has("coins"): parts.append("%d coins" % int(r.coins))
	if r.has("gems"): parts.append("%d gems" % int(r.gems))
	if r.has("booster"): parts.append("%d x %s" % [int(r.get("n", 1)), r.booster])
	for k in ["hammer", "refresh", "shuffle"]:
		if r.has(k): parts.append("%d x %s" % [int(r[k]), k])
	if r.has("ads_removed"): parts.append("no ads")
	return ", ".join(parts)

# ---- stats / streak -------------------------------------------------------------------------
func add_stat(key: String, n: int) -> void:
	d().stats[key] = int(d().stats.get(key, 0)) + n
	for ev in active_events():
		if ev.stat == key:
			d().events[ev.id] = int(d().events.get(ev.id, 0)) + n

func set_stat_max(key: String, v: int) -> void:
	if v > int(d().stats.get(key, 0)): d().stats[key] = v
	for ev in active_events():
		if ev.stat == key: d().events[ev.id] = maxi(int(d().events.get(ev.id, 0)), v)

func touch_streak() -> void:
	var s: Dictionary = d().streak
	var today_n := day_number()
	var last := int(s.last_day)
	if last == today_n: return
	s["count"] = int(s.count) + 1 if last == today_n - 1 else 1
	s["last_day"] = today_n
	s["best"] = maxi(int(s.best), int(s.count))
	_dirty()

## Streak shown to the player: broken if a whole day was missed.
func current_streak() -> int:
	var s: Dictionary = d().streak
	return int(s.count) if int(s.last_day) >= day_number() - 1 else 0

# ---- levels ---------------------------------------------------------------------------------
func level_stars(id: String) -> int:
	return int(d().progress.levels.get(id, 0))

func is_level_unlocked(chapter: int, index: int) -> bool:
	if index > 1: return level_stars(LevelDB.level_id(chapter, index - 1)) >= 1
	return is_chapter_unlocked(chapter)

func is_chapter_unlocked(chapter: int) -> bool:
	if chapter <= 1: return true
	var prev: Dictionary = {}
	for c in LevelDB.chapters():
		if int(c.id) == chapter - 1: prev = c
	return not prev.is_empty() and level_stars(LevelDB.level_id(chapter - 1, int(prev.levels))) >= 1

func chapter_stars(chapter: int) -> int:
	var n := 0
	for c in LevelDB.chapters():
		if int(c.id) == chapter:
			for i in range(1, int(c.levels) + 1): n += level_stars(LevelDB.level_id(chapter, i))
	return n

func next_level(chapter: int, index: int) -> Vector2i:
	for c in LevelDB.chapters():
		if int(c.id) == chapter:
			if index < int(c.levels): return Vector2i(chapter, index + 1)
			elif LevelDB.get_level(chapter + 1, 1).size() > 0: return Vector2i(chapter + 1, 1)
	return Vector2i(-1, -1)

## First level the player has not cleared yet (chapter, index). (-1,-1) when all are done.
func next_unfinished_level() -> Vector2i:
	for c in LevelDB.chapters():
		var ch: int = int(c.id)
		for i in range(1, int(c.levels) + 1):
			if level_stars(LevelDB.level_id(ch, i)) == 0 and is_level_unlocked(ch, i):
				return Vector2i(ch, i)
	return Vector2i(-1, -1)

# ---- starting sessions ----------------------------------------------------------------------
func start_endless(resume: bool = false) -> void:
	current_level_id = ""
	touch_streak()
	if resume and not d().run.is_empty():
		var s := GameSession.from_dict(d().run)
		if s != null:
			session = s
			if session.mode == "endless": return
	clear_run()
	session = GameSession.new(randi())

func start_level(chapter: int, index: int) -> bool:
	var lv := LevelDB.get_level(chapter, index)
	if lv.is_empty() or not is_level_unlocked(chapter, index): return false
	touch_streak()
	clear_run()
	current_level_id = lv.id
	session = GameSession.new(int(lv.seed), "level", lv)
	return true

func start_daily() -> void:
	touch_streak()
	clear_run()
	var lv := LevelDB.daily_level(today())
	current_level_id = lv.id
	session = GameSession.new(int(lv.seed), "daily", lv)

func daily_done_today() -> bool:
	return str(d().daily.last_completed) == today()

# ---- in-game hooks --------------------------------------------------------------------------
func on_move(res: Dictionary) -> void:
	if not res.get("ok", false): return
	add_stat("blocks", int(res.piece.size))
	add_stat("lines", int(res.clear.lines))
	set_stat_max("best_combo", int(res.score.combo))
	if res.board_cleared: add_stat("boards_cleared", 1)
	if session.mode == "endless": save_run()
	_dirty()

func save_run() -> void:
	if session and session.mode == "endless" and not session.game_over:
		d().run = session.to_dict()
		SaveManager.mark_dirty()

func clear_run() -> void:
	if not d().run.is_empty():
		d().run = {}
		SaveManager.mark_dirty()

func has_run() -> bool:
	return not d().run.is_empty()

## Call once when a game ends (game over or level complete). Returns the summary dictionary.
func finish_session() -> Dictionary:
	var s := session
	var score := s.scoring.score
	var res := {"score": score, "lines": s.scoring.lines_cleared, "best_combo": s.scoring.best_combo,
		"moves": s.moves, "mode": s.mode, "won": s.level_complete, "stars": s.stars(),
		"new_best": false, "reward": {}, "level_id": current_level_id}
	add_stat("games", 1)
	add_stat("score_total", score)
	if score > int(d().best_score):
		d().best_score = score
		res.new_best = true
	var hs: Array = d().high_scores
	hs.append({"score": score, "date": today(), "mode": s.mode})
	hs.sort_custom(func(a, b): return int(a.score) > int(b.score))
	d().high_scores = hs.slice(0, 10)
	add_season_xp(maxi(10, score / 10))
	if s.mode == "level" and s.level_complete:
		var old := level_stars(current_level_id)
		var st := s.stars()
		if st > old: d().progress.levels[current_level_id] = st
		if old == 0: add_stat("levels_done", 1)
		var reward := {"coins": int(s.level.get("reward_coins", 20)) + (st - 1) * 10}
		if old == 0: apply_reward(reward)
		else: reward = {}
		res.reward = reward
	elif s.mode == "daily" and s.level_complete and not daily_done_today():
		var dd: Dictionary = LevelDB.meta().get("daily", {})
		var reward := {"coins": int(dd.get("reward_coins", 100)), "gems": int(dd.get("reward_gems", 5))}
		apply_reward(reward)
		d().daily.last_completed = today()
		d().daily.best = maxi(int(d().daily.best), score)
		res.reward = reward
	if s.mode != "endless" or s.game_over: clear_run()
	last_result = res
	check_achievements()
	_dirty()
	SaveManager.save_now()
	return res

# ---- season ---------------------------------------------------------------------------------
func season() -> Dictionary:
	return LevelDB.meta().get("season", {})

func add_season_xp(n: int) -> void:
	d().season["xp"] = int(d().season.xp) + n

func season_tier_unlocked(i: int) -> bool:
	return int(d().season.xp) >= (i + 1) * int(season().get("xp_per_tier", 400))

func season_tier_claimed(i: int) -> bool:
	return i in d().season.claimed

func claim_season_tier(i: int) -> bool:
	var tiers: Array = season().get("tiers", [])
	if i < 0 or i >= tiers.size() or not season_tier_unlocked(i) or season_tier_claimed(i): return false
	d().season.claimed.append(i)
	apply_reward(tiers[i])
	_dirty()
	return true

# ---- events ---------------------------------------------------------------------------------
func active_events() -> Array:
	var out: Array = []
	var t := today()
	for ev in LevelDB.meta().get("events", []):
		if t >= str(ev.start) and t <= str(ev["end"]): out.append(ev)
	return out

func event_progress(id: String) -> int:
	return int(d().events.get(id, 0))

func event_claimed(id: String) -> bool:
	return bool(d().events.get(id + "_claimed", false))

func claim_event(ev: Dictionary) -> bool:
	if event_claimed(ev.id) or event_progress(ev.id) < int(ev.target): return false
	d().events[ev.id + "_claimed"] = true
	apply_reward(ev.reward)
	_dirty()
	return true

# ---- achievements ---------------------------------------------------------------------------
func achievements() -> Array:
	return LevelDB.meta().get("achievements", [])

func achievement_progress(a: Dictionary) -> int:
	return int(d().stats.get(a.stat, 0))

func achievement_done(a: Dictionary) -> bool:
	return achievement_progress(a) >= int(a.target)

func achievement_claimed(a: Dictionary) -> bool:
	return a.id in d().achievements.claimed

func check_achievements() -> void:
	for a in achievements():
		if achievement_done(a) and not achievement_claimed(a):
			achievement_unlocked.emit(a.id)

func claim_achievement(a: Dictionary) -> bool:
	if not achievement_done(a) or achievement_claimed(a): return false
	d().achievements.claimed.append(a.id)
	apply_reward(a.reward)
	_dirty()
	return true

# ---- shop -----------------------------------------------------------------------------------
## Soft-currency purchases only. Real-money items go through BillingService.
func buy_item(item: Dictionary) -> bool:
	match str(item.kind):
		"coins":
			if not spend("coins", int(item.cost)): return false
		"gems":
			if not spend("gems", int(item.cost)): return false
		_:
			return false
	apply_reward(item.give)
	return true

func ads_removed() -> bool:
	return bool(d().purchases.get("ads_removed", false))
