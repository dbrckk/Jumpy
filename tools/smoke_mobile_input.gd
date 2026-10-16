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

	# Avoid audio/haptics side effects during the headless integration smoke.
	Profile.data.sound = false
	Profile.data.haptics = false

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
	game._unhandled_input(physical_touch)
	if game.state != "PLAYING" or not game.pulse_available or game.player_vy != game.JUMP_V:
		_fail("One physical touch must start a run with a single jump")
		return

	game._unhandled_input(emulated_mouse)
	if not game.pulse_available or game.player_vy != game.JUMP_V:
		_fail("Emulated duplicate incorrectly consumed the air pulse")
		return
	game._unhandled_input(physical_touch)
	if game.pulse_available:
		_fail("A second real touch must use the single available air pulse")
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

	print("PASS: fullscreen HUD, menu buttons, physical touch, duplicate suppression, desktop mouse")
	quit(0)


func _fail(message: String) -> void:
	push_error("Mobile input smoke failed: " + message)
	quit(1)
