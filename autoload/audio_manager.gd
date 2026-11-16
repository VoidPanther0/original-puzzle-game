extends Node
## Procedural audio (no external assets needed): short synthesized tones for SFX and a simple
## generative ambient loop for music. Replace with real files by dropping .ogg into res://assets/audio
## and loading them in _ready (see docs).

const RATE := 22050
var _sfx := {}
var _players: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_stream: AudioStreamWAV

func _ready() -> void:
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_sfx["place"] = _tone([440.0, 330.0], 0.09, 0.5)
	_sfx["invalid"] = _tone([120.0, 90.0], 0.14, 0.5, true)
	_sfx["clear"] = _tone([523.0, 659.0, 784.0], 0.28, 0.55)
	_sfx["combo"] = _tone([659.0, 784.0, 988.0, 1318.0], 0.4, 0.55)
	_sfx["click"] = _tone([700.0], 0.04, 0.4)
	_sfx["pickup"] = _tone([520.0], 0.05, 0.35)
	_sfx["gameover"] = _tone([392.0, 330.0, 262.0, 196.0], 0.7, 0.55)
	_sfx["win"] = _tone([523.0, 659.0, 784.0, 1046.0], 0.6, 0.55)
	_sfx["booster"] = _tone([300.0, 600.0, 900.0], 0.25, 0.5)
	_sfx["crack"] = _tone([880.0, 520.0], 0.09, 0.45, true)
	_sfx["shot"] = _tone([1500.0, 800.0, 260.0], 0.26, 0.5)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_music_stream = _make_music()
	_music.stream = _music_stream
	apply_settings()

func _tone(freqs: Array, dur: float, vol: float, noisy: bool = false) -> AudioStreamWAV:
	var n := int(RATE * dur)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var seg := maxi(1, n / freqs.size())
	var phase := 0.0
	for i in n:
		var f: float = freqs[mini(i / seg, freqs.size() - 1)]
		phase += TAU * f / RATE
		var env := 1.0 - float(i) / n
		var s := sin(phase) * (0.6 if noisy else 1.0)
		if noisy: s += (randf() - 0.5) * 0.8
		var v := int(clampf(s * env * vol, -1.0, 1.0) * 32000.0)
		bytes.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	return w

func _make_music() -> AudioStreamWAV:
	var notes := [261.6, 329.6, 392.0, 329.6, 293.7, 349.2, 440.0, 349.2]
	var note_len := 0.5
	var n := int(RATE * note_len * notes.size())
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var per := int(RATE * note_len)
	for i in n:
		var f: float = notes[i / per]
		var t := float(i % per) / per
		var env := minf(t * 12.0, 1.0) * (1.0 - t * 0.7)
		var s := sin(TAU * f * i / RATE) * 0.6 + sin(TAU * f * 2.0 * i / RATE) * 0.15
		bytes.encode_s16(i * 2, int(s * env * 5000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w

func apply_settings() -> void:
	if _music == null: return
	_music.volume_db = linear_to_db(maxf(0.001, float(SaveManager.get_setting("music_vol", 0.7)) * 0.5))
	if bool(SaveManager.get_setting("music", true)):
		if not _music.playing and not DisplayServer.get_name() == "headless":
			_music.play()
	else:
		_music.stop()

func play(name: String) -> void:
	if not bool(SaveManager.get_setting("sfx", true)) or not _sfx.has(name): return
	if DisplayServer.get_name() == "headless": return
	for p in _players:
		if not p.playing:
			p.stream = _sfx[name]
			p.volume_db = linear_to_db(maxf(0.001, float(SaveManager.get_setting("sfx_vol", 0.9))))
			p.play()
			return
