class_name LevelDB
extends RefCounted
## Builds level configurations deterministically from data/chapters.json (chapter parameters +
## per-level seeded starting layouts). Pure logic, no autoload dependencies.
## Starting layouts are GRAVITY-SETTLED stacks (blocks resting on the floor) with one empty column,
## so a level never starts with a completed line.

static var _chapters: Array = []
static var _meta: Dictionary = {}

static func load_data() -> void:
	if not _chapters.is_empty(): return
	_chapters = _read("res://data/chapters.json").get("chapters", [])
	_meta = _read("res://data/meta.json")

static func _read(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if typeof(d) == TYPE_DICTIONARY else {}

static func meta() -> Dictionary:
	load_data()
	return _meta

static func chapters() -> Array:
	load_data()
	return _chapters

static func level_id(chapter: int, index: int) -> String:
	return "c%d_l%d" % [chapter, index]

static func pool_for(families: Array) -> Array:
	var ids: Array = []
	for p in PieceDB.all():
		if p.family in families: ids.append(p.id)
	return ids

## `count` blocks stacked on the floor in at most 7 columns (one column stays empty => no full row).
static func stack_layout(rng: RandomNumberGenerator, count: int) -> Array:
	var empty_col := rng.randi_range(0, Board.SIZE - 1)
	var heights: Array = []
	heights.resize(Board.SIZE)
	heights.fill(0)
	var placed := 0
	var guard := 0
	while placed < count and guard < 1000:
		guard += 1
		var c := rng.randi_range(0, Board.SIZE - 1)
		if c == empty_col or int(heights[c]) >= 6: continue
		heights[c] += 1
		placed += 1
	var cells: Array = []
	for c in Board.SIZE:
		for h in int(heights[c]):
			cells.append([Board.SIZE - 1 - h, c])
	return cells

## chapter is 1-based, index is 1-based.
static func get_level(chapter: int, index: int) -> Dictionary:
	load_data()
	var ch: Dictionary = {}
	for c in _chapters:
		if int(c.id) == chapter: ch = c
	if ch.is_empty() or index < 1 or index > int(ch.levels): return {}
	var target: int = int(ch.base_target) + int(ch.target_step) * (index - 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = chapter * 1000 + index
	# every level starts with at least a few stone blocks, so the shot ability (crack -> destroy)
	# is always available - even in the very first level.
	var prefill: int = maxi(4, int(round(minf(float(ch.prefill_max), 36.0) * float(index - 1) / maxf(1.0, float(ch.levels) - 1.0))))
	var cells := stack_layout(rng, prefill)
	return {
		"id": level_id(chapter, index), "chapter": chapter, "index": index, "name": "%s %d" % [ch.name, index],
		"goal": {"type": "score", "target": target},
		"stars": [target, int(target * 1.4), int(target * 1.9)],
		"difficulty": clampf(float(ch.difficulty) + 0.01 * (index - 1), 0.0, 1.0),
		"pool": pool_for(ch.families), "start_cells": cells, "seed": chapter * 7919 + index * 104729,
		"reward_coins": 20 + 5 * index + 10 * chapter,
	}

## Seeded daily challenge for a date string like "2026-11-15".
static func daily_level(date: String) -> Dictionary:
	load_data()
	var h := date.hash()
	var base: int = int(_meta.get("daily", {}).get("base_target", 600))
	var rng := RandomNumberGenerator.new()
	rng.seed = h
	var target := base + 50 * rng.randi_range(0, 6)
	var cells := stack_layout(rng, rng.randi_range(4, 12))
	return {"id": "daily_" + date, "name": "Daily " + date, "goal": {"type": "score", "target": target},
		"stars": [target, int(target * 1.4), int(target * 1.9)], "difficulty": 0.35,
		"pool": [], "start_cells": cells, "seed": h}

static func total_levels() -> int:
	load_data()
	var n := 0
	for c in _chapters: n += int(c.levels)
	return n
