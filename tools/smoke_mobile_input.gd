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
	game._unhandled_input(physical_touch)
	if game.state != "READY" or not game.settings_open:
		_fail("Touch outside Settings started a run")
		return
	game.settings_pressed()
	if game.settings_open or game.state != "READY":
		_fail("Settings BACK did not return to the READY menu")
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

	game.queue_free()
	await process_frame
	print("PASS: HUD, direct mode starts, touch input, desktop mouse, ledge jump grace and expiry")
	quit(0)


func _fail(message: String) -> void:
	push_error("Mobile input smoke failed: " + message)
	quit(1)
