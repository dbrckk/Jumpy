extends SceneTree

# Integration smoke: exercise the real Main scene, autoloads and touch-routing
# contract without creating unit tests or relying on an Android emulator.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if packed == null:
		_fail("Main scene could not be loaded")
		return
	var game: Node2D = packed.instantiate()
	root.add_child(game)
	await process_frame
	if not is_instance_valid(game):
		_fail("Main scene was not instantiated")
		return
	var layer: CanvasLayer = game.get_child(0) as CanvasLayer
	if layer == null:
		_fail("HUD CanvasLayer missing")
		return
	var hud_root: Control = layer.get_child(0) as Control
	if hud_root == null or hud_root.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("Fullscreen HUD intercepts gameplay taps")
		return
	var labels: int = 0
	var buttons: int = 0
	for child: Node in hud_root.get_children():
		if child is Label:
			labels += 1
			if child.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				_fail("Noninteractive HUD label blocks gameplay taps: " + child.name)
				return
		elif child is Button:
			buttons += 1
			if child.mouse_filter != Control.MOUSE_FILTER_STOP:
				_fail("Interactive menu button must consume its own taps: " + child.name)
				return
	if labels < 7 or buttons < 5:
		_fail("Unexpected HUD content; input smoke coverage is incomplete")
		return

	# Keep the integration smoke silent; the real autoload is discovered at runtime.
	var profile: Node = root.get_node_or_null("Profile")
	if profile != null:
		var prefs: Dictionary = profile.get("data")
		prefs["sound"] = false
		prefs["haptics"] = false

	var emulated_mouse: InputEventMouseButton = InputEventMouseButton.new()
	emulated_mouse.button_index = MOUSE_BUTTON_LEFT
	emulated_mouse.pressed = true
	emulated_mouse.device = InputEvent.DEVICE_ID_EMULATION
	game._unhandled_input(emulated_mouse)
	if game.state != "READY":
		_fail("Emulated mouse event started a run")
		return

	var physical_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	physical_touch.pressed = true
	physical_touch.index = 0
	physical_touch.device = 0
	var secondary_touch: InputEventScreenTouch = InputEventScreenTouch.new()
	secondary_touch.pressed = true
	secondary_touch.index = 1
	secondary_touch.device = 0
	game._unhandled_input(secondary_touch)
	if game.state != "READY":
		_fail("Secondary finger must not start a run")
		return
	# Regression from canary #37: touching blank space while Settings is open
	# must not start a run, while BACK must still restore normal tap-to-start.
	game.settings_pressed()
	if not game.settings_open or game.state != "READY":
		_fail("Settings did not open from the READY menu")
		return
	if not game.ui.backup.visible or not game.ui.restore.visible:
		_fail("Settings must expose mobile backup and restore actions")
		return
	game._unhandled_input(physical_touch)
	if game.state != "READY" or not game.settings_open:
		_fail("Touch outside Settings started a run")
		return
	game.settings_pressed()
	if game.settings_open or game.state != "READY":
		_fail("Settings BACK did not return to the READY menu")
		return
	if game.ui.backup.visible or game.ui.restore.visible:
		_fail("Backup controls must not cover gameplay outside Settings")
		return
	game._unhandled_input(physical_touch)
	if game.state != "PLAYING" or not game.pulse_available or game.player_vy != game.JUMP_V:
		_fail("One physical touch must start a run with a single jump")
		return

	game._unhandled_input(secondary_touch)
	if not game.pulse_available or game.player_vy != game.JUMP_V:
		_fail("Secondary finger unexpectedly consumed the air pulse")
		return
	game._unhandled_input(emulated_mouse)
	if not game.pulse_available or game.player_vy != game.JUMP_V:
		_fail("Emulated duplicate incorrectly consumed the air pulse")
		return
	game._unhandled_input(physical_touch)
	if game.pulse_available:
		_fail("A second real touch must use the single available air pulse")
		return

	game.state = "DEAD"
	game._unhandled_input(secondary_touch)
	if game.state != "DEAD":
		_fail("Secondary finger must not trigger retry after death")
		return

	# The two prominent mode buttons must start a run immediately,
	# not just select a seed and leave the player on the READY screen.
	game.reset_run(false)
	game.ui.daily.emit_signal("pressed")
	if game.state != "PLAYING" or not game.daily_mode or game.player_vy != game.JUMP_V or not game.pulse_available:
		_fail("DAILY button failed to start a single daily jump")
		return
	if not game.ui.flow.text.begins_with("DAILY"):
		_fail("Active DAILY mode is missing from the run HUD")
		return
	game._unhandled_input(emulated_mouse)
	if not game.pulse_available:
		_fail("Synthetic event spent the pulse after DAILY start")
		return

	game.reset_run(false)
	game.ui.normal.emit_signal("pressed")
	if game.state != "PLAYING" or game.daily_mode or game.player_vy != game.JUMP_V or not game.pulse_available:
		_fail("ENDLESS button failed to start a single normal jump")
		return
	if not game.ui.flow.text.begins_with("ENDLESS"):
		_fail("Active ENDLESS mode is missing from the run HUD")
		return

	game.reset_run(false)
	var desktop_mouse: InputEventMouseButton = InputEventMouseButton.new()
	desktop_mouse.button_index = MOUSE_BUTTON_LEFT
	desktop_mouse.pressed = true
	desktop_mouse.device = InputEvent.DEVICE_ID_MOUSE
	game._unhandled_input(desktop_mouse)
	if game.state != "PLAYING" or not game.pulse_available:
		_fail("Genuine desktop mouse input must still start the game")
		return

	# Real scene-level gameplay acceptance: stepping off a ledge still permits
	# a short jump, but the grace ends once used or after the timer expires.
	game.reset_run(false)
	game.start_run()
	game.platforms.clear()
	game.on_ground = true
	game.update_player(1.0 / 60.0)
	if game.on_ground or game.coyote_remaining <= 0.0:
		_fail("Walking off a platform must open the jump grace window")
		return
	game._unhandled_input(physical_touch)
	if game.player_vy != game.JUMP_V or not game.pulse_available or game.coyote_remaining != 0.0:
		_fail("Grace tap must jump without spending the air pulse")
		return
	game._unhandled_input(physical_touch)
	if game.pulse_available:
		_fail("A subsequent airborne tap must still consume the pulse")
		return

	game.reset_run(false)
	game.start_run()
	game.platforms.clear()
	game.on_ground = true
	game.update_player(1.0 / 60.0)
	game.player_y = 300.0  # Avoid unintended landings during elapsed-time simulation.
	game._physics_process(game.COYOTE_TIME + 0.02)
	if game.coyote_remaining > 0.0 or game.on_ground:
		_fail("Expired ledge grace must no longer permit a ground jump")
		return
	game._unhandled_input(physical_touch)
	if game.pulse_available:
		_fail("An expired-grace touch must use the air pulse, not a second jump")
		return

	# Check real Profile serialization, persistent restore and invalid input
	# without relying on a system clipboard in headless CI.
	if profile == null:
		_fail("Profile autoload missing for backup integration smoke")
		return
	var previous_save: Dictionary = profile.data.duplicate(true)
	profile.data.runs = 17
	profile.data.best_score = 4242
	var backup_code: String = profile.export_backup_code()
	if not profile.is_valid_backup_code(backup_code):
		_fail("Exported progress must pass integrity and schema validation")
		return
	profile.data.runs = 0
	profile.data.best_score = 0
	if not profile.restore_backup_code(backup_code):
		_fail("Valid backup must be restored and saved")
		return
	if int(profile.data.runs) != 17 or int(profile.data.best_score) != 4242:
		_fail("Backup roundtrip lost player progress")
		return
	# Reload the actual user:// file, not just the in-memory dictionary.
	profile.load_data()
	if int(profile.data.runs) != 17 or int(profile.data.best_score) != 4242:
		_fail("Backup restore did not survive a profile reload from disk")
		return
	var chunks: PackedStringArray = backup_code.split(":")
	var changed_hash: String = "0" if not chunks[1].begins_with("0") else "1"
	var corrupted_code: String = chunks[0] + ":" + changed_hash + chunks[1].substr(1) + ":" + chunks[2]
	if profile.restore_backup_code(corrupted_code):
		_fail("Corrupted backup digest must be rejected")
		return
	if int(profile.data.runs) != 17:
		_fail("Invalid import must not destroy previous progress")
		return
	var insufficient_payload: String = JSON.stringify({"version": 1, "runs": 22})
	var partial_code: String = "JUMPY1:" + insufficient_payload.sha256_text() + ":" + Marshalls.utf8_to_base64(insufficient_payload)
	if profile.restore_backup_code(partial_code):
		_fail("A partial save document must not overwrite player progress")
		return
	# Local-calendar streak regression: the old calculation mixed today's
	# current UTC clock with the previous *date* at 00:00, accidentally
	# treating a two-day absence as one day near local midnight.
	profile.data.last_play_date = "2026-10-16"
	profile.data.streak_days = 5
	profile._apply_streak_for_date("2026-10-17")
	if int(profile.data.streak_days) != 6 or str(profile.data.last_play_date) != "2026-10-17":
		_fail("Playing on consecutive local dates must extend the streak")
		return
	profile._apply_streak_for_date("2026-10-17")
	if int(profile.data.streak_days) != 6:
		_fail("Two sessions on the same calendar day must not add another streak day")
		return
	profile.data.last_play_date = "2026-10-15"
	profile.data.streak_days = 9
	profile._apply_streak_for_date("2026-10-17")
	if int(profile.data.streak_days) != 1 or profile._calendar_day_difference("2026-10-15", "2026-10-17") != 2:
		_fail("Skipping a local calendar date must reset the streak regardless of clock hour")
		return
	profile.data.last_play_date = "2025-12-31"
	profile.data.streak_days = 12
	profile._apply_streak_for_date("2026-01-01")
	if int(profile.data.streak_days) != 13:
		_fail("A year boundary must preserve a legitimate consecutive-day streak")
		return
	profile.data.last_play_date = "2024-02-28"
	profile.data.streak_days = 3
	profile._apply_streak_for_date("2024-02-29")
	if int(profile.data.streak_days) != 4:
		_fail("Leap-day transitions must count as one calendar day")
		return
	profile.data.last_play_date = "2026-10-19"
	profile.data.streak_days = 99
	profile._apply_streak_for_date("2026-10-17")
	if int(profile.data.streak_days) != 1 or str(profile.data.last_play_date) != "2026-10-17":
		_fail("A future saved date must not extend a streak after clock rollback")
		return
	profile.data.last_play_date = "2026-02-30"
	profile.data.streak_days = 6
	profile._apply_streak_for_date("2026-03-01")
	if int(profile.data.streak_days) != 1:
		_fail("An invalid saved calendar date must not extend a streak")
		return
	profile.data = previous_save
	if not profile.save():
		_fail("Unable to restore original profile after integration smoke")
		return

	# Test full judgement scoring in the actual Main scene: PERFECT -> CLUTCH
	# must preserve FLOW, while ordinary landings only decrease it.
	game.reset_run(false)
	game.combo = 10
	game.flow = 3.5
	game.on_landed({"id": 501, "x": 120.0, "w": 300.0})
	var perfect_flow: float = game.flow
	if perfect_flow < 3.5 or game.perfects != 1:
		_fail("Perfect landing must advance FLOW and perfect count")
		return
	game.on_landed({"id": 502, "x": 250.0, "w": 300.0})
	var clutch_flow: float = game.flow
	if clutch_flow < perfect_flow or game.combo != 12:
		_fail("Clutch landing must not reduce existing FLOW")
		return
	game.on_landed({"id": 503, "x": 50.0, "w": 300.0})
	if game.combo != 11 or game.flow > clutch_flow or absf(game.flow - (clutch_flow - 0.25)) > 0.001:
		_fail("Ordinary landing must reduce FLOW smoothly without boosting it")
		return
	for landing_id: int in range(504, 524):
		game.on_landed({"id": landing_id, "x": 50.0, "w": 300.0})
	if game.flow < 1.0 or game.flow > 1.001 or game.combo != 0:
		_fail("Repeated ordinary landings must decay toward x1 with no underflow")
		return

	# Inspect diagnostic UI in the actual scene without inventing a new test suite.
	# Production templates must hide this readout; debug builds permit manual QA.
	game.reset_run(false)
	if game.ui.qa_perf.visible:
		_fail("QA HUD must be hidden on the title/settings screens")
		return
	game.start_run()
	if game.ui.qa_perf.visible != OS.is_debug_build():
		_fail("QA HUD visibility must match the runtime debug build")
		return
	if OS.is_debug_build():
		game._process(0.4)
		game._process(0.7)
		if not game.ui.qa_perf.text.begins_with("QA FPS ") or not game.ui.qa_perf.text.contains("WORST "):
			_fail("QA HUD did not publish the sampled render-frame metrics")
			return
		game.state = "DEAD"
		game._process(0.02)
		if not game.ui.qa_perf.visible:
			_fail("QA HUD must retain the final run measurements after death")
			return
	game.reset_run(false)
	if game.ui.qa_perf.visible:
		_fail("Reset must clear the debug performance readout")
		return

	# Edge grazes must not count as landings only to drop the player one
	# frame later: collision and grounded support share the same tolerance.
	game.reset_run(false)
	game.state = "PLAYING"
	game.platforms.clear()
	game.platforms.append(game.make_platform(game.PLAYER_X + game.PLAYER_R * 0.6, 1200.0, 200.0, 901))
	game.platforms[0].coin = false
	game.on_ground = false
	game.player_y = 1200.0 - game.PLAYER_R + 4.0
	game.player_vy = 300.0
	game.try_land(1200.0 - game.PLAYER_R - 4.0)
	if game.on_ground or game.last_platform_id == 901:
		_fail("A sprite-edge graze must not count as a supported landing")
		return
	game.platforms[0].x = game.PLAYER_X + game.PLAYER_R * 0.2
	game.player_y = 1200.0 - game.PLAYER_R + 4.0
	game.try_land(1200.0 - game.PLAYER_R - 4.0)
	if not game.on_ground or not game.has_support() or game.last_platform_id != 901:
		_fail("A genuinely supported edge landing must still be accepted")
		return

	# HUD integration regression: unchanged values must not rewrite label
	# text each physics frame; score, mode, pulse and contrast transitions must
	# still refresh immediately (without making a new unit-test suite).
	game.reset_run(false)
	game.start_run()
	var saved_best: int = int(profile.data.best_score)
	var saved_bank: int = int(profile.data.coins)
	var saved_contrast: bool = bool(profile.data.high_contrast)
	profile.data.best_score = 999
	profile.data.coins = 35
	profile.data.high_contrast = false
	game.score = 120
	game.flow = 2.25
	game.combo = 5
	game.run_coins = 3
	game.on_ground = false
	game.pulse_available = true
	game.update_ui()
	if game.ui.score.text != "120" or game.ui.best.text != "BEST 999":
		_fail("HUD must refresh changed score and lifetime best")
		return
	if game.ui.coins.text != "◇ 35  +3" or not game.ui.flow.text.contains("FLOW x2.25"):
		_fail("HUD must refresh changed coins and FLOW")
		return
	if not game.ui.pulse.visible or game.ui.pulse.text != "AIR PULSE READY":
		_fail("HUD must show the available pulse during flight")
		return
	game.ui.score.text = "CACHE PROBE"
	game.ui.pulse.text = "PULSE CACHE PROBE"
	game.update_ui()
	if game.ui.score.text != "CACHE PROBE" or game.ui.pulse.text != "PULSE CACHE PROBE":
		_fail("Unchanged HUD data must not reassign read-only labels")
		return
	game.score = 121
	game.pulse_available = false
	game.update_ui()
	if game.ui.score.text != "121" or game.ui.pulse.text != "AIR PULSE USED":
		_fail("Score and pulse changes must invalidate the HUD cache")
		return
	profile.data.high_contrast = true
	game.update_ui()
	if game.ui.pulse.get_theme_color("font_color") != Color("ffffff"):
		_fail("High-contrast preference must update pulse color")
		return
	game.state = "DEAD"
	game.update_ui()
	if game.ui.flow.visible or game.ui.pulse.visible or not game.ui.score.visible:
		_fail("Death must hide FLOW and pulse while retaining score")
		return
	game.reset_run(true)
	game.start_run()
	if not game.ui.flow.text.begins_with("DAILY") or game.ui.score.text != "0":
		_fail("Starting a new daily run must refresh mode and score")
		return
	profile.data.best_score = saved_best
	profile.data.coins = saved_bank
	profile.data.high_contrast = saved_contrast
	game.reset_run(false)

	# Late taps after the one air pulse was spent should queue a jump
	# only briefly, and only trigger it on an actual supported landing.
	game.reset_run(false)
	game.start_run()
	game.pulse()
	game.player_vy = 380.0
	game.player_y = 1150.0
	game.platforms.clear()
	game.platforms.append(game.make_platform(160.0, 1200.0, 260.0, 951))
	game.platforms[0].coin = false
	game._unhandled_input(physical_touch)
	if game.jump_buffer_remaining <= 0.0 or game.pulse_available:
		_fail("After spending the pulse, a descending tap must queue one jump")
		return
	game.update_ui()
	if game.ui.pulse.text != "JUMP QUEUED":
		_fail("Queued pre-landing jumps must be visible in the pulse HUD")
		return
	game._physics_process(0.02)
	if game.on_ground or game.player_vy != game.JUMP_V or game.jump_buffer_remaining != 0.0:
		_fail("Buffered tap must become a single jump after a supported landing")
		return
	if not game.pulse_available or game.last_platform_id != 951:
		_fail("Buffered landing must still score and restore the air pulse")
		return

	# An early descending tap must expire: it may not jump later on its own.
	game.reset_run(false)
	game.start_run()
	game.pulse()
	game.player_vy = 150.0
	game.player_y = 600.0
	game._unhandled_input(physical_touch)
	if game.jump_buffer_remaining <= 0.0:
		_fail("Descending tap did not queue the buffered jump")
		return
	game._physics_process(game.JUMP_BUFFER_TIME + 0.02)
	if game.jump_buffer_remaining > 0.0 or game.ui.pulse.text != "AIR PULSE USED":
		_fail("Expired buffered jump must restore the used-pulse HUD")
		return
	game.platforms.clear()
	game.platforms.append(game.make_platform(160.0, 1200.0, 260.0, 952))
	game.platforms[0].coin = false
	game.player_y = 1150.0
	game.player_vy = 380.0
	game._physics_process(0.02)
	if not game.on_ground or game.player_vy != 0.0:
		_fail("An expired buffered jump must not auto-launch on landing")
		return

	game.reset_run(false)
	game.start_run()
	game.pulse()
	game.player_vy = 150.0
	game._unhandled_input(physical_touch)
	game.reset_run(false)
	if game.jump_buffer_remaining != 0.0:
		_fail("Restart must clear pending buffered jump inputs")
		return

	# Idle/death rendering contract: post-death effects must finish instead of
	# leaving a permanent white flash and shaking screen.
	game.reset_run(false)
	game.state = "DEAD"
	game.camera_kick = 18.0
	game.flash = 0.35
	game.burst(Vector2(game.PLAYER_X, game.player_y), Color.WHITE, 5, 150.0)
	if game.particles.is_empty():
		_fail("Death-style burst must produce transient particles")
		return
	game._physics_process(0.05)
	if game.camera_kick >= 18.0 or game.flash >= 0.35:
		_fail("Camera shake and flash must decay after gameplay stops")
		return
	game._physics_process(5.0)
	if game.camera_kick != 0.0 or game.flash != 0.0 or not game.particles.is_empty():
		_fail("Death effects must reach a fully settled idle state")
		return
	if game.state != "DEAD":
		_fail("Finishing death effects must not restart gameplay")
		return
	game.reset_run(false)
	game._physics_process(0.1)
	if game.camera_kick != 0.0 or game.flash != 0.0 or game.state != "READY":
		_fail("Ready menu must stay static after idle processing")
		return

	# Verify the actual sound autoload uses bounded prebuilt audio resources,
	# not a newly generated PCM buffer and scene node on every jump/landing.
	var sfx: Node = root.get_node_or_null("Integrations")
	if sfx == null:
		_fail("Integrations autoload missing for audio smoke")
		return
	var voices: Array = sfx.get("tone_players")
	var cache: Dictionary = sfx.get("tone_cache")
	if voices.size() != 4 or cache.size() != 6:
		_fail("All six arcade SFX must be prebuilt with four pooled voices")
		return
	for voice: AudioStreamPlayer in voices:
		if voice.get_parent() != sfx:
			_fail("Pooled audio player is missing from the autoload")
			return
	var clutch_key: Vector3 = Vector3(880.0, 0.12, 0.17)
	if not cache.has(clutch_key):
		_fail("CLUTCH must have its own preloaded sound")
		return
	var clutch_tone: AudioStreamWAV = cache[clutch_key] as AudioStreamWAV
	if clutch_tone == null or clutch_tone.data.size() < 100:
		_fail("CLUTCH waveform was not synthesized")
		return
	if clutch_tone.data.decode_s16(0) != 0 or absi(clutch_tone.data.decode_s16(clutch_tone.data.size() - 2)) > 100:
		_fail("Tone samples must fade in and out without hard edges")
		return
	var initial_player_count: int = sfx.get_child_count()
	var original_sound_setting: bool = bool(profile.data.sound)
	profile.data.sound = true
	sfx.haptic(26)
	var clutch_played: bool = false
	for voice: AudioStreamPlayer in voices:
		if voice.stream == clutch_tone:
			clutch_played = true
	if not clutch_played:
		_fail("CLUTCH haptic must actually route to the new sound")
		return
	for _i: int in range(24):
		for duration_ms: int in [10, 12, 14, 20, 26, 32, 70]:
			sfx.haptic(duration_ms)
	profile.data.sound = original_sound_setting
	if sfx.get_child_count() != initial_player_count or cache.size() != 6:
		_fail("Repeated SFX must reuse the same voices and cached waveforms")
		return

	# Render-path integration check for the layered neon visuals. Exercise
	# offscreen culling, collectible highlights, pulse ring and accessibility
	# variants in the real scene; this cannot judge subjective visual quality.
	game.reset_run(false)
	game.start_run()
	game.platforms.clear()
	for i: int in range(16):
		var platform_visual: Dictionary = game.make_platform(-520.0 + float(i) * 195.0, 1200.0 + float(i % 4) * 60.0, 270.0, 1100 + i)
		platform_visual.coin = true
		game.platforms.append(platform_visual)
	var saved_motion: bool = bool(profile.data.reduced_motion)
	var saved_visual_contrast: bool = bool(profile.data.high_contrast)
	for contrast_enabled: bool in [false, true]:
		for motion_enabled: bool in [false, true]:
			profile.data.high_contrast = contrast_enabled
			profile.data.reduced_motion = motion_enabled
			game.on_ground = false
			game.pulse_available = true
			game.update_ui()
			game.queue_redraw()
			await process_frame
			if not is_instance_valid(game) or game.state != "PLAYING":
				_fail("Layered visual pass must retain the active game scene")
				return
	profile.data.high_contrast = saved_visual_contrast
	profile.data.reduced_motion = saved_motion
	game.reset_run(false)

	# Reproducible procedural fairness on the actual Main scene: generated
	# gaps must overlap the descending jump arc at every difficulty/speed,
	# leaving a material takeoff window on the preceding platform.
	var wide_late_gap_found: bool = false
	for generated_speed: float in [470.0, 600.0, 750.0, 900.0, 970.0]:
		for generator_elapsed: float in [0.0, 70.0]:
			game.reset_run(false)
			game.platforms.clear()
			game.level_rng.seed = 19717
			game.speed = generated_speed
			game.elapsed = generator_elapsed
			game.platforms.append(game.make_platform(0.0, 1250.0, 260.0, 0))
			var right_edge: float = 260.0
			for index: int in range(75):
				right_edge = game.spawn_platform_after(right_edge)
				var previous_platform: Dictionary = game.platforms[-2]
				var target_platform: Dictionary = game.platforms[-1]
				var generated_gap: float = float(target_platform.x) - float(previous_platform.x) - float(previous_platform.w)
				var height_delta: float = float(target_platform.y) - float(previous_platform.y)
				var flight_time: float = (-game.JUMP_V + sqrt(game.JUMP_V * game.JUMP_V + 2.0 * game.GRAVITY * height_delta)) / game.GRAVITY
				var flight_distance: float = flight_time * minf(game.MAX_RUN_SPEED, generated_speed + game.PLATFORM_SPEED_LOOKAHEAD)
				if generated_gap < 144.99:
					_fail("Procedural route produced an overlapping or undersized gap")
					return
				if flight_distance < generated_gap + game.PLATFORM_TAKEOFF_WINDOW - 0.01:
					_fail("Procedural gap is too wide to reach on the jump's descent")
					return
				if flight_distance > generated_gap + float(previous_platform.w) + float(target_platform.w) - game.PLATFORM_TAKEOFF_WINDOW + 0.01:
					_fail("Procedural gap is too short: next platform passes before descent")
					return
				if generated_speed >= 900.0 and generated_gap > 400.0:
					wide_late_gap_found = true
	if not wide_late_gap_found:
		_fail("Late-game generator did not expand short impossible gaps")
		return

	# Exercise one fast generated route through the actual player/world
	# integration, rather than trusting the preceding geometry alone.
	game.reset_run(false)
	game.platforms.clear()
	game.level_rng.seed = 77219
	game.speed = game.MAX_RUN_SPEED
	game.elapsed = 70.0
	game.platforms.append(game.make_platform(0.0, 1300.0, 230.0, 2201))
	game.spawn_platform_after(230.0)
	var sample_previous: Dictionary = game.platforms[0]
	var sample_next: Dictionary = game.platforms[1]
	var sample_gap: float = float(sample_next.x) - float(sample_previous.x) - float(sample_previous.w)
	var sample_height_delta: float = float(sample_next.y) - float(sample_previous.y)
	var sample_flight_time: float = (-game.JUMP_V + sqrt(game.JUMP_V * game.JUMP_V + 2.0 * game.GRAVITY * sample_height_delta)) / game.GRAVITY
	var travel: float = sample_flight_time * game.MAX_RUN_SPEED
	var remaining_width: float = clampf(travel - sample_gap - float(sample_next.w) * 0.5, 16.0, float(sample_previous.w) - 16.0)
	sample_previous.x = game.PLAYER_X + remaining_width - float(sample_previous.w)
	sample_next.x = game.PLAYER_X + remaining_width + sample_gap
	sample_previous.coin = false
	sample_next.coin = false
	game.state = "PLAYING"
	game.on_ground = true
	game.player_y = float(sample_previous.y) - game.PLAYER_R
	game.player_vy = 0.0
	game.last_platform_id = int(sample_previous.id)
	game.jump()
	for physics_step: int in range(95):
		game.move_world(1.0 / 60.0)
		game.update_player(1.0 / 60.0)
		if game.last_platform_id == int(sample_next.id):
			break
		if game.state == "DEAD":
			break
	if game.last_platform_id != int(sample_next.id) or not game.on_ground:
		_fail("A valid late-game generated route must accept a real supported jump landing")
		return
	game.reset_run(false)

	# Actual death-screen/Profile integration: a tied record is not a PB,
	# while the day's best is independent of the player's all-time best.
	# Restore the pre-test profile so this acceptance does not pollute saves.
	var pre_result_profile: Dictionary = profile.data.duplicate(true)
	profile.data.best_score = 500
	profile.data.daily_best = 125
	profile.data.daily_key = Time.get_date_string_from_system()
	game.reset_run(false)
	game.start_run()
	game.score = 500
	game.die()
	if not game.ui.gameover.text.ends_with("FLOW BROKEN") or int(profile.data.best_score) != 500:
		_fail("Tying the lifetime high score must not claim NEW BEST")
		return

	game.reset_run(true)
	game.start_run()
	game.score = 200
	game.die()
	if not game.ui.gameover.text.ends_with("NEW DAILY BEST") or int(profile.data.daily_best) != 200 or int(profile.data.best_score) != 500:
		_fail("Daily high score must be awarded independently of lifetime best")
		return

	game.reset_run(true)
	game.start_run()
	game.score = 200
	game.die()
	if not game.ui.gameover.text.ends_with("FLOW BROKEN"):
		_fail("Matching today's daily high score must not announce a new record")
		return

	game.reset_run(false)
	game.start_run()
	game.score = 600
	game.die()
	if not game.ui.gameover.text.ends_with("NEW BEST") or int(profile.data.best_score) != 600:
		_fail("Strict lifetime high score must show NEW BEST and persist it")
		return
	profile.load_data()
	if int(profile.data.best_score) != 600 or int(profile.data.daily_best) != 200:
		_fail("Lifetime and daily best scores must survive save reload")
		return
	profile.data = pre_result_profile
	if not profile.save():
		_fail("Could not restore profile after end-screen record smoke")
		return
	game.reset_run(false)

	game.queue_free()
	await process_frame
	print("PASS: input, backups, FLOW, pooled SFX, neon visuals, fair routes and honest PB cues")
	quit(0)


func _fail(message: String) -> void:
	push_error("Mobile input smoke failed: " + message)
	quit(1)
