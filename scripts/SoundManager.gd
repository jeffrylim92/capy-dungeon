class_name SoundManager
extends Node

## Lightweight SFX cue player. Looks up wav/ogg/mp3 files in
## res://assets/sfx/<cue>.<ext>. If the file is missing, the cue is silently
## skipped — handy while we're still in placeholder mode.

const SFX_DIR := "res://assets/sfx/"
const POOL_SIZE := 6
const EXTS: Array[String] = [".wav", ".ogg", ".mp3"]

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}  # cue -> AudioStream or null

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func play(cue: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var s: AudioStream = _load_cue(cue)
	if s == null:
		return
	var p := _next_player()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = pitch_scale
	p.play()

func _load_cue(cue: String) -> AudioStream:
	if _cache.has(cue):
		return _cache[cue] as AudioStream
	for ext in EXTS:
		var path: String = SFX_DIR + cue + ext
		if ResourceLoader.exists(path):
			var s: AudioStream = load(path)
			_cache[cue] = s
			return s
	_cache[cue] = null
	return null

func _next_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]
