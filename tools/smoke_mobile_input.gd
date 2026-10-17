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
	game.platforms.append({"id": 901, "x": game.PLAYER_X + game.PLAYER_R * 0.6, "w": 200.0, "y": 1200.0, "passed": false})
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

	game.queue_free()
	await process_frame
	print("PASS: mobile input, coyote grace, backup recovery, FLOW, frame diagnostics and stable edge landings")
	quit(0)


func _fail(message: String) -> void:
	push_error("Mobile input smoke failed: " + message)
	quit(1)
