extends Node

# Central integration boundary. Core gameplay never depends on an external SDK.
# Replace external-service internals when production plugins are installed;
# see SETUP_REQUIRED.txt. Audio is synthesized locally so the prototype ships
# with tactile feedback without third-party assets.

func event(name: String, params: Dictionary = {}) -> void:
	print("[analytics] ", name, " ", params)

func haptic(duration_ms: int = 22) -> void:
	if bool(Profile.data.haptics) and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)
	if bool(Profile.data.sound):
		match duration_ms:
			10, 12:
				play_tone(1250.0, 0.07, 0.16)
			14:
				play_tone(560.0, 0.08, 0.18)
			20:
				play_tone(760.0, 0.09, 0.15)
			32:
				play_tone(1040.0, 0.14, 0.18)
			70:
				play_tone(150.0, 0.24, 0.20)
			_:
				pass

func play_tone(frequency: float, duration: float, volume: float) -> void:
	var mix_rate: int = 22050
	var sample_count: int = maxi(1, int(duration * float(mix_rate)))
	var pcm: PackedByteArray = PackedByteArray()
	pcm.resize(sample_count * 2)
	for i: int in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var envelope: float = exp(-8.0 * t)
		var wave: float = sin(TAU * frequency * t)
		var sample: int = int(clampf(wave * envelope * volume, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, sample)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = pcm
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = wav
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func rewarded_available(_placement: String) -> bool:
	return false

func show_rewarded(_placement: String, callback: Callable) -> void:
	# Development fallback deliberately grants nothing automatically.
	if callback.is_valid():
		callback.call(false)

func share_score(score: int, daily: bool = false) -> void:
	var mode: String = "DAILY" if daily else "RUN"
	var text: String = "JUMPY %s — %d. Beat me. #Jumpy" % [mode, score]
	DisplayServer.clipboard_set(text)
	# Native Android/iOS share sheet is optional. Clipboard fallback always works.
	event("share_score", {"score": score, "daily": daily})

func leaderboard_submit(score: int, daily: bool = false) -> void:
	# No-op until Play Games/Game Center is configured.
	event("leaderboard_submit_local", {"score": score, "daily": daily})
