extends Node
## Autoload "Sfx": original sound effects synthesised at start-up, so the
## project needs no audio files. Mute and volume are handled on the Master bus
## by the Settings autoload.

const MIX_RATE: int = 22050
const VOICES: int = 4

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	for _i: int in VOICES:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)
	_streams["pick"] = _tone([520.0, 660.0], 0.05, 0.35)
	_streams["place"] = _tone([180.0, 140.0], 0.09, 0.5)
	_streams["invalid"] = _tone([150.0, 110.0], 0.1, 0.4, true)
	_streams["click"] = _tone([700.0], 0.04, 0.3)
	_streams["clear"] = _tone([523.0, 659.0, 784.0, 1047.0], 0.08, 0.4)
	_streams["combo"] = _tone([659.0, 784.0, 988.0, 1319.0, 1568.0], 0.07, 0.4)
	_streams["gameover"] = _tone([392.0, 330.0, 262.0, 196.0], 0.18, 0.45)


func play(sound_name: String) -> void:
	if not Settings.sound_enabled or not _streams.has(sound_name):
		return
	var player: AudioStreamPlayer = _players[_next_voice]
	_next_voice = (_next_voice + 1) % _players.size()
	player.stream = _streams[sound_name]
	player.play()


## Builds a short mono 16-bit clip: one note per frequency in `notes`, each
## lasting `note_seconds`, with a quick decay envelope.
func _tone(notes: Array, note_seconds: float, volume: float, square: bool = false) -> AudioStreamWAV:
	var per_note: int = int(MIX_RATE * note_seconds)
	var data := PackedByteArray()
	data.resize(per_note * notes.size() * 2)
	var index: int = 0
	var phase: float = 0.0
	for freq: float in notes:
		for i: int in per_note:
			var t: float = float(i) / float(per_note)
			var envelope: float = pow(1.0 - t, 1.5) * minf(1.0, float(i) / 60.0)
			phase += TAU * freq / float(MIX_RATE)
			var wave: float = sin(phase)
			if square:
				wave = signf(wave) * 0.6
			var sample: int = int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
			data.encode_s16(index * 2, sample)
			index += 1
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav
