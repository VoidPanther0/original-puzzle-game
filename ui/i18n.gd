class_name I18n
extends RefCounted
## Language architecture: the English text IS the key. data/lang/<code>.json maps English -> translation.
## Missing keys fall back to English, so adding a language never breaks a screen.
## To add a language: create data/lang/<code>.json and add it to LANGUAGES.

const LANGUAGES := {
	"en": "English",
	"hi": "हिन्दी",
	"ja": "日本語",
	"zh": "中文",
	"es": "Español",
	"fr": "Français",
	"de": "Deutsch",
	"pt": "Português",
	"ru": "Русский",
	"ko": "한국어",
	"ar": "العربية",
	"it": "Italiano",
	"tr": "Türkçe",
	"id": "Bahasa Indonesia",
	"vi": "Tiếng Việt",
	"pl": "Polski",
}

static var _code := ""
static var _map: Dictionary = {}

static func current() -> String:
	return str(SaveManager.get_setting("language", "en"))

static func t(s: String) -> String:
	var code := current()
	if code != _code:
		_code = code
		_map = {}
		var f := FileAccess.open("res://data/lang/%s.json" % code, FileAccess.READ)
		if f:
			var p = JSON.parse_string(f.get_as_text())
			if typeof(p) == TYPE_DICTIONARY: _map = p
	return str(_map.get(s, s))

static func reload() -> void:
	_code = ""
