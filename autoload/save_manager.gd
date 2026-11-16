extends Node
## Local persistence in user:// (IndexedDB on Web). Versioned, checksummed (tamper deterrent only,
## NOT security - authoritative validation happens on the server), with backup-file recovery.

signal saved
signal recovered_from_corruption

const CURRENT_VERSION := 1
const SALT := "bfb-local-integrity-v1"    # public; deters casual edits only

var save_path := "user://save.json"
var backup_path := "user://save.bak.json"
var data: Dictionary = {}
var recovered := false
var _dirty := false
var _timer: Timer

static func defaults() -> Dictionary:
	return {
		"coins": 300, "gems": 20,
		"boosters": {"hammer": 2, "refresh": 2, "shuffle": 2},
		"best_score": 0, "high_scores": [],
		"settings": {"music": true, "sfx": true, "music_vol": 0.7, "sfx_vol": 0.9, "haptics": true,
			"theme": "dark", "language": "en", "fullscreen": false, "resolution": 0, "consent": "unknown"},
		"progress": {"levels": {}},     # level id -> stars
		"daily": {"last_completed": "", "best": 0, "claimed": ""},
		"streak": {"count": 0, "last_day": -1, "best": 0},
		"season": {"id": 1, "xp": 0, "claimed": []},
		"events": {},                    # event id -> progress
		"achievements": {"claimed": []},
		"stats": {"games": 0, "lines": 0, "score_total": 0, "best_combo": 0, "blocks": 0,
			"levels_done": 0, "boards_cleared": 0},
		"purchases": {"ads_removed": false, "history": []},
		"profile": {"name": "Player", "avatar": 0, "id": ""},
		"cloud": {"last_sync": 0},
		"run": {},                       # auto-saved in-progress game
	}

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 2.0
	_timer.one_shot = true
	_timer.timeout.connect(_flush)
	add_child(_timer)
	load_data()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED \
			or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_now()

# ---- API ------------------------------------------------------------------------------------
func get_setting(key: String, fallback = null):
	return data.get("settings", {}).get(key, fallback)

func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	mark_dirty()

## Autosave: coalesces bursts of changes into one write.
func mark_dirty() -> void:
	_dirty = true
	if _timer and _timer.is_inside_tree() and _timer.is_stopped():
		_timer.start()

func save_now() -> void:
	if _dirty or not FileAccess.file_exists(save_path):
		_flush()

func _flush() -> void:
	_dirty = false
	write_file(data)
	saved.emit()

# ---- integrity ------------------------------------------------------------------------------
static func checksum(version: int, body: String) -> String:
	return (SALT + str(version) + body).sha256_text()

func write_file(payload: Dictionary) -> bool:
	var body := JSON.stringify(payload)
	var wrapper := {"version": CURRENT_VERSION, "data": body, "sig": checksum(CURRENT_VERSION, body)}
	var text := JSON.stringify(wrapper)
	var tmp := save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null: return false
	f.store_string(text)
	f.close()
	if FileAccess.file_exists(save_path):
		DirAccess.copy_absolute(save_path, backup_path)
	var ok := DirAccess.copy_absolute(tmp, save_path) == OK
	DirAccess.remove_absolute(tmp)
	return ok

## Returns {} when the file is missing or fails verification.
func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return {}
	var parser := JSON.new()
	if parser.parse(f.get_as_text()) != OK:   # damaged file - no error spam
		f.close()
		return {}
	var parsed = parser.data
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY: return {}
	if not parsed.has("version") or typeof(parsed.get("data")) != TYPE_STRING: return {}
	if str(parsed.get("sig", "")) != checksum(int(parsed.version), parsed.data): return {}
	var inner = JSON.parse_string(parsed.data)
	if typeof(inner) != TYPE_DICTIONARY: return {}
	return {"version": int(parsed.version), "data": inner}

func load_data() -> void:
	recovered = false
	var wrapper := read_file(save_path)
	if wrapper.is_empty():
		var had_file := FileAccess.file_exists(save_path)
		wrapper = read_file(backup_path)
		if not wrapper.is_empty():
			recovered = true
		elif had_file:
			recovered = true      # corrupted and no usable backup -> fresh start
	if wrapper.is_empty():
		data = defaults()
	else:
		data = migrate(wrapper.data, int(wrapper.version))
	if recovered:
		recovered_from_corruption.emit()
		mark_dirty()
	if str(data.profile.get("id", "")) == "":
		data.profile["id"] = "p" + str(randi()) + str(Time.get_ticks_usec())
		mark_dirty()

## Fills in any missing keys (forward compatible) and upgrades old versions.
func migrate(d: Dictionary, from_version: int) -> Dictionary:
	# if from_version < 2: ... future migrations go here, one block per version
	var base := defaults()
	return _merge_defaults(base, d)

func _merge_defaults(base: Dictionary, src: Dictionary) -> Dictionary:
	for k in src:
		if base.has(k) and typeof(base[k]) == TYPE_DICTIONARY and typeof(src[k]) == TYPE_DICTIONARY \
				and k not in ["levels", "boosters", "events"]:
			base[k] = _merge_defaults(base[k], src[k])
		else:
			base[k] = src[k]
	return base

func reset_all() -> void:
	data = defaults()
	data.profile["id"] = "p" + str(randi()) + str(Time.get_ticks_usec())
	_flush()
