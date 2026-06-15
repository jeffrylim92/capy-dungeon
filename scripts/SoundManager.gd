class_name SoundManager
extends Node

## Lightweight SFX cue player. Looks up wav/ogg/mp3 files in
## res://assets/sfx/<cue>.<ext>. If the file is missing, it generates a short
## procedural placeholder cue so skills still have immediate audio feedback.

const SFX_DIR := "res://assets/sfx/"
const POOL_SIZE := 6
const EXTS: Array[String] = [".wav", ".ogg", ".mp3"]
const GENERATED_MIX_RATE := 22050

const GENERATED_CUES: Dictionary = {
	"skill_pick": {"freq": 660.0, "duration": 0.12, "wave": "sine", "slide": 1.25},
	"skill_orb": {"freq": 420.0, "duration": 0.08, "wave": "triangle", "slide": 1.35},
	"skill_bolt": {"freq": 1120.0, "duration": 0.11, "wave": "electric", "slide": 0.55, "amp": 0.24},
	"skill_ice_orb": {"freq": 1320.0, "duration": 0.18, "wave": "ice", "slide": 0.36, "amp": 0.30},
	"skill_wave": {"freq": 210.0, "duration": 0.24, "wave": "sine", "slide": 0.52},
	"skill_aura": {"freq": 180.0, "duration": 0.12, "wave": "triangle", "slide": 0.82},
	"skill_regen": {"freq": 520.0, "duration": 0.18, "wave": "sine", "slide": 1.45},
	"skill_magnet": {"freq": 360.0, "duration": 0.10, "wave": "sine", "slide": 1.90},
	"skill_fireball": {"freq": 260.0, "duration": 0.16, "wave": "square", "slide": 0.72},
	"skill_elec_wave": {"freq": 980.0, "duration": 0.20, "wave": "electric", "slide": 0.42, "amp": 0.30},
	"skill_hurricane": {"freq": 300.0, "duration": 0.14, "wave": "noise", "slide": 1.0},
	"skill_blizzard": {"freq": 1180.0, "duration": 0.34, "wave": "ice", "slide": 0.30, "amp": 0.32},
	"skill_arrow": {"freq": 760.0, "duration": 0.08, "wave": "triangle", "slide": 1.35},
	"skill_split_arrow": {"freq": 690.0, "duration": 0.11, "wave": "triangle", "slide": 1.55},
	"skill_pierce_arrow": {"freq": 560.0, "duration": 0.12, "wave": "square", "slide": 1.25},
	"skill_sky_fall": {"freq": 420.0, "duration": 0.32, "wave": "noise", "slide": 1.20},
	"skill_star_knife": {"freq": 920.0, "duration": 0.08, "wave": "square", "slide": 0.78},
	"skill_knife_storm": {"freq": 620.0, "duration": 0.13, "wave": "noise", "slide": 1.0},
	"skill_boomerang": {"freq": 500.0, "duration": 0.15, "wave": "triangle", "slide": 1.85},
	"skill_seven_slash": {"freq": 980.0, "duration": 0.30, "wave": "square", "slide": 0.45},
	"skill_swirl_tangerine": {"freq": 330.0, "duration": 0.34, "wave": "triangle", "slide": 1.65},
}

var _players: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}  # cue -> AudioStream or null

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
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
	_cache[cue] = _make_generated_cue(cue)
	return _cache[cue] as AudioStream

func _make_generated_cue(cue: String) -> AudioStream:
	if not GENERATED_CUES.has(cue):
		return null
	var spec: Dictionary = GENERATED_CUES[cue]
	var duration: float = spec.get("duration", 0.12) as float
	var frame_count: int = max(1, int(duration * float(GENERATED_MIX_RATE)))
	var freq: float = spec.get("freq", 440.0) as float
	var slide: float = spec.get("slide", 1.0) as float
	var wave: String = spec.get("wave", "sine") as String
	var amp: float = spec.get("amp", 0.42) as float
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(int(cue.hash()))
	var phase: float = 0.0
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var write_i: int = 0
	for i in frame_count:
		var t: float = float(i) / float(max(frame_count - 1, 1))
		var env: float = sin(t * PI) * (1.0 - t * 0.35)
		var cur_freq: float = lerpf(freq, freq * slide, t)
		phase += TAU * cur_freq / float(GENERATED_MIX_RATE)
		var sample: float = _wave_sample(wave, phase, rng) * env * amp
		var pcm: int = int(clampi(int(sample * 32767.0), -32768, 32767))
		bytes[write_i] = pcm & 0xff
		bytes[write_i + 1] = (pcm >> 8) & 0xff
		write_i += 2
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = GENERATED_MIX_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func _wave_sample(wave: String, phase: float, rng: RandomNumberGenerator) -> float:
	match wave:
		"square":
			return 1.0 if sin(phase) >= 0.0 else -1.0
		"triangle":
			return asin(sin(phase)) * (2.0 / PI)
		"electric":
			var crackle: float = rng.randf_range(-1.0, 1.0)
			var snap: float = 1.0 if rng.randf() > 0.72 else 0.0
			return sin(phase * 1.7) * 0.35 + crackle * snap * 0.65
		"ice":
			return sin(phase) * 0.48 + sin(phase * 2.01) * 0.26 + asin(sin(phase * 3.07)) * 0.12
		"noise":
			return rng.randf_range(-1.0, 1.0) * 0.65 + sin(phase) * 0.35
		_:
			return sin(phase)

func _next_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]
