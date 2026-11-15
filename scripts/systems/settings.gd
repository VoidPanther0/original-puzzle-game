extends Node
## Autoload "Settings": player preferences and best score, saved to user://.
## Works fully offline. Nothing is sent anywhere.

signal changed()

const DEFAULT_PATH: String = "user://settings.cfg"
const SECTION: String = "player"

var save_path: String = DEFAULT_PATH
var best_score: int = 0
var sound_enabled: bool = true
var vibration_enabled: bool = true
var ghost_preview: bool = true
var volume: float = 0.8  # 0.0 - 1.0


func _ready() -> void:
	load_settings()
	apply_volume()


## Loads from disk. Missing or corrupt values fall back to defaults.
## Returns true if a file was read.
func load_settings() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return false
	best_score = maxi(0, int(cfg.get_value(SECTION, "best_score", 0)))
	sound_enabled = bool(cfg.get_value(SECTION, "sound_enabled", true))
	vibration_enabled = bool(cfg.get_value(SECTION, "vibration_enabled", true))
	ghost_preview = bool(cfg.get_value(SECTION, "ghost_preview", true))
	volume = clampf(float(cfg.get_value(SECTION, "volume", 0.8)), 0.0, 1.0)
	return true


func save_settings() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "best_score", best_score)
	cfg.set_value(SECTION, "sound_enabled", sound_enabled)
	cfg.set_value(SECTION, "vibration_enabled", vibration_enabled)
	cfg.set_value(SECTION, "ghost_preview", ghost_preview)
	cfg.set_value(SECTION, "volume", volume)
	return cfg.save(save_path)


## Records a finished or in-progress score. Returns true if it is a new best.
func submit_score(score: int) -> bool:
	if score <= best_score:
		return false
	best_score = score
	save_settings()
	changed.emit()
	return true


func reset_best_score() -> void:
	best_score = 0
	save_settings()
	changed.emit()


func set_sound_enabled(value: bool) -> void:
	sound_enabled = value
	apply_volume()
	save_settings()
	changed.emit()


func set_vibration_enabled(value: bool) -> void:
	vibration_enabled = value
	save_settings()
	changed.emit()


func set_ghost_preview(value: bool) -> void:
	ghost_preview = value
	save_settings()
	changed.emit()


func set_volume(value: float) -> void:
	volume = clampf(value, 0.0, 1.0)
	apply_volume()
	save_settings()
	changed.emit()


func apply_volume() -> void:
	var bus: int = AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, not sound_enabled)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
