extends Node

# Central integration boundary. Core gameplay never depends on an external SDK.
# Replace external-service internals when production plugins are installed;
# see SETUP_REQUIRED.txt. Audio is synthesized locally so the prototype ships
# with tactile feedback without third-party assets.

const AUDIO_POOL_SIZE: int = 4
const TONE_SAMPLE_RATE: int = 22050

# SFX are tiny PCM resources synthesized once, not rebuilt on every tap.
# A bounded set of players lets nearby jump/landing sounds overlap safely.
var tone_cache: Dictionary = {}
var tone_players: Array[AudioStreamPlayer] = []
var voice_to_steal: int = 0


func _ready() -> void:
	for i: int in range(AUDIO_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.name = "ArcadeSFX%d" % i
		add_child(player)
		tone_players.append(player)

	# Warm every shipped sound at startup to keep gameplay free of PCM
	# generation and node allocations, including the formerly silent CLUTCH.
	_get_tone(1250.0, 0.07, 0.16) # coin + skin selection
	_get_tone(560.0, 0.08, 0.18)  # jump
	_get_tone(760.0, 0.09, 0.15)  # air pulse
	_get_tone(880.0, 0.12, 0.17)  # clutch landing
	_get_tone(1040.0, 0.14, 0.18) # perfect landing
	_get_tone(150.0, 0.24, 0.20)  # death


func event(name: String, params: Dictionary = {}) -> void:
	print("[analytics] ", name, " ", params)


func haptic(duration_ms: int = 22) -> void:
	if bool(Profile.data.haptics) and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)
	if not bool(Profile.data.sound):
		return
	match duration_ms:
		10, 12:
			play_tone(1250.0, 0.07, 0.16)
		14:
			play_tone(560.0, 0.08, 0.18)
		20:
			play_tone(760.0, 0.09, 0.15)
		26:
			play_tone(880.0, 0.12, 0.17)
		32:
			play_tone(1040.0, 0.14, 0.18)
		70:
			play_tone(150.0, 0.24, 0.20)


func _get_tone(frequency: float, duration: float, volume: float) -> AudioStreamWAV:
	var key: Vector3 = Vector3(frequency, duration, volume)
	if tone_cache.has(key):
		return tone_cache[key] as AudioStreamWAV
	var sample_count: int = maxi(1, int(duration * float(TONE_SAMPLE_RATE)))
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(sample_count * 2)
	var fade_out_seconds: float = maxf(0.001, minf(0.025, duration * 0.4))
	for i: int in range(sample_count):
		var t: float = float(i) / float(TONE_SAMPLE_RATE)
		# A short attack/release removes hard PCM start/stop clicks.
		var attack: float = clampf(t / 0.003, 0.0, 1.0)
		var release: float = clampf((duration - t) / fade_out_seconds, 0.0, 1.0)
		var envelope: float = exp(-3.2 * t / duration) * attack * release
		var wave: float = sin(TAU * frequency * t)
		var sample: int = int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, sample)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TONE_SAMPLE_RATE
	wav.stereo = false
	wav.data = pcm
	tone_cache[key] = wav
	return wav


func play_tone(frequency: float, duration: float, volume: float) -> void:
	var wav: AudioStreamWAV = _get_tone(frequency, duration, volume)
	var selected: AudioStreamPlayer = null
	for player: AudioStreamPlayer in tone_players:
		if not player.playing:
			selected = player
			break
	if selected == null:
		# Bound the voices even when events happen in the same audio frame.
		selected = tone_players[voice_to_steal]
		voice_to_steal = (voice_to_steal + 1) % AUDIO_POOL_SIZE
		selected.stop()
	selected.stream = wav
	selected.play()


func rewarded_available(_placement: String) -> bool:
	return false

func show_rewarded(_placement: String, callback: Callable) -> void:
	# Development fallback deliberately grants nothing automatically.
	if callback.is_valid():
		callback.call(false)

func share_score(score: int, daily: bool = false) -> void:
	var mode: String = "DAILY" if daily else "RUN"
	var text: String = "JUMPY %s — %d. Beat me. #Jumpy" % [mode, score]
	if not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		event("share_unavailable", {"score": score, "daily": daily})
		return
	DisplayServer.clipboard_set(text)
	# Native Android/iOS share sheet is optional. Clipboard fallback always works.
	event("share_score", {"score": score, "daily": daily})

func leaderboard_submit(score: int, daily: bool = false) -> void:
	# No-op until Play Games/Game Center is configured.
	event("leaderboard_submit_local", {"score": score, "daily": daily})
