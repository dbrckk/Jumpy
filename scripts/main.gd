extends Node2D

const W: float = 1080.0
const H: float = 1920.0
const PLAYER_X: float = 270.0
const PLAYER_R: float = 42.0
const GRAVITY: float = 2550.0
const JUMP_V: float = -1080.0
const PULSE_V: float = -620.0
const FLOOR_LIMIT: float = 1820.0
const LANDING_CUE_DURATION: float = 0.72
const COYOTE_TIME: float = 0.09
const JUMP_BUFFER_TIME: float = 0.10
const QA_SAMPLE_INTERVAL: float = 1.0
const MAX_RUN_SPEED: float = 970.0
const PLATFORM_SPEED_LOOKAHEAD: float = 35.0
const PLATFORM_TAKEOFF_WINDOW: float = 140.0
const PLATFORM_GAP_VARIATION: float = 120.0

const SKINS: Array[Color] = [
	Color("62f7ff"), Color("ff5fd2"), Color("ffe66d"),
	Color("8aff80"), Color("a88bff"), Color("ff8f5f")
]

var state: String = "READY"
var daily_mode: bool = false
var level_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var fx_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var platforms: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var player_y: float = 1448.0
var player_vy: float = 0.0
var on_ground: bool = true
var pulse_available: bool = true
var speed: float = 470.0
var score: int = 0
var run_coins: int = 0
var combo: int = 0
var flow: float = 1.0
var perfects: int = 0
var elapsed: float = 0.0
var camera_kick: float = 0.0
var flash: float = 0.0
var landing_cue_remaining: float = 0.0
var coyote_remaining: float = 0.0
var jump_buffer_remaining: float = 0.0
var last_platform_id: int = -1
var next_platform_id: int = 1
var ui: Dictionary = {}
var settings_open: bool = false
var pending_restore_code: String = ""
var qa_sample_elapsed: float = 0.0
var qa_worst_frame_ms: float = 0.0

# Keep unchanged HUD labels out of the 60 Hz physics hot path.
var hud_score_seen: int = -1
var hud_best_seen: int = -1
var hud_bank_seen: int = -1
var hud_run_coins_seen: int = -1
var hud_flow_seen: float = -1.0
var hud_combo_seen: int = -1
var hud_mode_seen: int = -1
var hud_pulse_seen: int = -1
var hud_contrast_seen: bool = false

func _ready() -> void:
	fx_rng.randomize()
	build_ui()
	reset_run(false)
	Integrations.event("game_open")

func build_ui() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# The fullscreen HUD must not swallow gameplay taps outside actual buttons.
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	ui.score = make_label(root, "0", 80, Vector2(0, 90), Vector2(W, 110), HORIZONTAL_ALIGNMENT_CENTER)
	ui.flow = make_label(root, "FLOW x1.0", 30, Vector2(0, 180), Vector2(W, 50), HORIZONTAL_ALIGNMENT_CENTER)
	ui.pulse = make_label(root, "", 26, Vector2(0, 235), Vector2(W, 40), HORIZONTAL_ALIGNMENT_CENTER)
	ui.pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.landing = make_label(root, "", 44, Vector2(100, 295), Vector2(880, 88), HORIZONTAL_ALIGNMENT_CENTER)
	ui.landing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.landing.visible = false
	# Diagnostic-only performance readout; never shown in release exports.
	ui.qa_perf = make_label(root, "QA FPS --  |  WORST -- ms", 24, Vector2(600, 410), Vector2(430, 55), HORIZONTAL_ALIGNMENT_RIGHT)
	ui.qa_perf.visible = false
	ui.best = make_label(root, "BEST 0", 28, Vector2(42, 44), Vector2(360, 50))
	ui.coins = make_label(root, "◇ 0", 28, Vector2(700, 44), Vector2(330, 50), HORIZONTAL_ALIGNMENT_RIGHT)
	ui.title = make_label(root, "JUMPY", 124, Vector2(0, 390), Vector2(W, 150), HORIZONTAL_ALIGNMENT_CENTER)
	ui.subtitle = make_label(root, "TAP • LAND • FLOW", 34, Vector2(0, 545), Vector2(W, 70), HORIZONTAL_ALIGNMENT_CENTER)
	ui.hint = make_label(root, "TAP TO JUMP\nTAP ONCE IN AIR TO PULSE", 30, Vector2(120, 690), Vector2(840, 120), HORIZONTAL_ALIGNMENT_CENTER)
	ui.mission = make_label(root, "", 25, Vector2(90, 900), Vector2(900, 120), HORIZONTAL_ALIGNMENT_CENTER)
	ui.daily = make_button(root, "DAILY", Vector2(170, 1110), Vector2(330, 96), func() -> void: set_daily(true))
	ui.normal = make_button(root, "ENDLESS", Vector2(580, 1110), Vector2(330, 96), func() -> void: set_daily(false))
	ui.skin = make_button(root, "SKIN", Vector2(375, 1240), Vector2(330, 82), cycle_skin)
	ui.settings = make_button(root, "SETTINGS", Vector2(375, 1340), Vector2(330, 82), settings_pressed)
	ui.setting_sound = make_button(root, "", Vector2(120, 1450), Vector2(390, 82), func() -> void: toggle_preference("sound"))
	ui.setting_haptics = make_button(root, "", Vector2(570, 1450), Vector2(390, 82), func() -> void: toggle_preference("haptics"))
	ui.setting_motion = make_button(root, "", Vector2(120, 1550), Vector2(390, 82), func() -> void: toggle_preference("reduced_motion"))
	ui.setting_contrast = make_button(root, "", Vector2(570, 1550), Vector2(390, 82), func() -> void: toggle_preference("high_contrast"))
	ui.backup = make_button(root, "COPY BACKUP", Vector2(120, 1660), Vector2(390, 82), copy_save_backup)
	ui.restore = make_button(root, "RESTORE SAVE", Vector2(570, 1660), Vector2(390, 82), restore_save_backup)
	ui.backup_notice = make_label(root, "", 23, Vector2(120, 1760), Vector2(840, 96), HORIZONTAL_ALIGNMENT_CENTER)
	ui.gameover = make_label(root, "", 58, Vector2(80, 580), Vector2(920, 280), HORIZONTAL_ALIGNMENT_CENTER)
	ui.retry = make_button(root, "RETRY", Vector2(280, 940), Vector2(520, 110), restart_pressed)
	ui.share = make_button(root, "SHARE", Vector2(330, 1080), Vector2(420, 86), func() -> void: Integrations.share_score(score, daily_mode))

func make_label(parent: Control, text: String, size: int, pos: Vector2, dim: Vector2, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = pos
	label.size = dim
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Read-only labels never consume tap / mouse input on top of the playfield.
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("f4f7ff"))
	parent.add_child(label)
	return label

func make_button(parent: Control, text: String, pos: Vector2, dim: Vector2, pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = pos
	button.size = dim
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(pressed)
	parent.add_child(button)
	return button

func settings_pressed() -> void:
	if state != "READY":
		return
	settings_open = not settings_open
	pending_restore_code = ""
	ui.backup_notice.text = ""
	show_menu(true)


func copy_save_backup() -> void:
	if state != "READY" or not settings_open:
		return
	pending_restore_code = ""
	if not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		ui.backup_notice.text = "CLIPBOARD UNAVAILABLE ON THIS DEVICE"
		return
	DisplayServer.clipboard_set(Profile.export_backup_code())
	ui.backup_notice.text = "COPIED. PASTE INTO NOTES BEFORE UNINSTALLING."


func restore_save_backup() -> void:
	if state != "READY" or not settings_open:
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		ui.backup_notice.text = "CLIPBOARD UNAVAILABLE ON THIS DEVICE"
		return
	var code: String = DisplayServer.clipboard_get().strip_edges()
	if not Profile.is_valid_backup_code(code):
		pending_restore_code = ""
		ui.backup_notice.text = "INVALID BACKUP. YOUR SAVE IS UNCHANGED."
		return
	if code != pending_restore_code:
		pending_restore_code = code
		ui.backup_notice.text = "TAP RESTORE AGAIN TO REPLACE CURRENT PROGRESS."
		return
	pending_restore_code = ""
	if not Profile.restore_backup_code(code):
		ui.backup_notice.text = "RESTORE FAILED. YOUR SAVE IS UNCHANGED."
		return
	show_menu(true)
	update_ui()
	queue_redraw()
	ui.backup_notice.text = "SAVE RESTORED. PROGRESS AND SETTINGS UPDATED."


func toggle_preference(key: String) -> void:
	if state != "READY":
		return
	Profile.set_preference(key, not bool(Profile.data.get(key, false)))
	refresh_settings_ui()
	queue_redraw()

func refresh_settings_ui() -> void:
	if not ui.has("settings"):
		return
	ui.settings.text = "BACK" if settings_open else "SETTINGS"
	var show_settings: bool = state == "READY" and settings_open
	ui.setting_sound.visible = show_settings
	ui.setting_haptics.visible = show_settings
	ui.setting_motion.visible = show_settings
	ui.setting_contrast.visible = show_settings
	ui.backup.visible = show_settings
	ui.restore.visible = show_settings
	ui.backup_notice.visible = show_settings
	ui.setting_sound.text = "SOUND  %s" % ("ON" if bool(Profile.data.sound) else "OFF")
	ui.setting_haptics.text = "HAPTICS  %s" % ("ON" if bool(Profile.data.haptics) else "OFF")
	ui.setting_motion.text = "REDUCED MOTION  %s" % ("ON" if bool(Profile.data.reduced_motion) else "OFF")
	ui.setting_contrast.text = "HIGH CONTRAST  %s" % ("ON" if bool(Profile.data.high_contrast) else "OFF")

func reset_run(use_daily: bool) -> void:
	daily_mode = use_daily
	state = "READY"
	score = 0
	run_coins = 0
	combo = 0
	flow = 1.0
	perfects = 0
	elapsed = 0.0
	speed = 470.0
	player_y = 1490.0 - PLAYER_R
	player_vy = 0.0
	on_ground = true
	pulse_available = true
	landing_cue_remaining = 0.0
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0
	qa_sample_elapsed = 0.0
	qa_worst_frame_ms = 0.0
	ui.qa_perf.visible = false
	ui.qa_perf.text = "QA FPS --  |  WORST -- ms"
	camera_kick = 0.0
	flash = 0.0
	ui.landing.visible = false
	last_platform_id = 0
	next_platform_id = 1
	particles.clear()
	platforms.clear()
	if daily_mode:
		level_rng.seed = Profile.daily_seed()
	else:
		level_rng.randomize()
	platforms.append(make_platform(0.0, 1490.0, 560.0, 0))
	var x: float = 560.0
	while x < 1500.0:
		x = spawn_platform_after(x)
	show_menu(true)
	update_ui()
	queue_redraw()

func set_daily(value: bool) -> void:
	# DAILY and ENDLESS are direct play actions, not hidden mode selectors.
	reset_run(value)
	start_run()

func cycle_skin() -> void:
	var unlocked: Array = Profile.data.unlocked_skins
	if unlocked.is_empty():
		return
	var current: int = unlocked.find(int(Profile.data.selected_skin))
	var next_skin: int = int(unlocked[(current + 1) % unlocked.size()])
	Profile.select_skin(next_skin)
	Integrations.haptic(12)
	queue_redraw()

func restart_pressed() -> void:
	reset_run(daily_mode)
	start_run()

func start_run() -> void:
	if state == "PLAYING":
		return
	state = "PLAYING"
	show_menu(false)
	ui.qa_perf.visible = OS.is_debug_build()
	jump()
	# Display the active mode, pulse status and score immediately on the first frame.
	update_ui()
	Integrations.event("run_start", {"daily": daily_mode})

func show_menu(value: bool) -> void:
	if not value:
		settings_open = false
	var show_main: bool = value and not settings_open
	ui.title.visible = show_main
	ui.subtitle.visible = show_main
	ui.hint.visible = show_main
	ui.mission.visible = show_main
	ui.daily.visible = show_main
	ui.normal.visible = show_main
	ui.skin.visible = show_main
	ui.settings.visible = value
	refresh_settings_ui()
	ui.gameover.visible = false
	ui.retry.visible = false
	ui.share.visible = false
	if value:
		var mission_data: Dictionary = Profile.get_mission_progress()
		ui.mission.text = "STREAK %d  •  MISSIONS  •  RUNS %d/%d  •  PERFECT %d/%d\nTOTAL SCORE %d/%d" % [int(Profile.data.streak_days), mission_data.runs, mission_data.runs_goal, mission_data.perfects, mission_data.perfects_goal, mission_data.score, mission_data.score_goal]

func _unhandled_input(event: InputEvent) -> void:
	# One physical touch may also produce a synthetic mouse click in Godot.
	# Handle the real event once; never turn a single tap into jump + air pulse.
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	# Only the primary finger controls gameplay; additional simultaneous fingers
	# must not accidentally start a run, spend an air pulse or trigger retry.
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null and touch.index != 0:
		return
	var tapped: bool = false
	if event.is_action_pressed("tap"):
		tapped = true
	elif event is InputEventScreenTouch and event.pressed:
		tapped = true
	if not tapped:
		return
	if state == "READY" and not settings_open:
		start_run()
	elif state == "PLAYING":
		if on_ground or coyote_remaining > 0.0:
			jump()
		elif pulse_available:
			pulse()
		elif player_vy > 0.0:
			# A late press after spending the pulse can chain into the next landing.
			jump_buffer_remaining = JUMP_BUFFER_TIME
	elif state == "DEAD":
		restart_pressed()

func jump() -> void:
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0
	player_vy = JUMP_V
	on_ground = false
	pulse_available = true
	var burst_count = 8
	var burst_power = 230.0
	if Profile.data.reduced_motion:
		burst_count = int(burst_count * 0.5)
		burst_power *= 0.5
	burst(Vector2(PLAYER_X, player_y + PLAYER_R), skin_color(), burst_count, burst_power)
	Integrations.haptic(14)

func pulse() -> void:
	jump_buffer_remaining = 0.0
	pulse_available = false
	player_vy = minf(player_vy, PULSE_V)
	var burst_count = 14
	var burst_power = 320.0
	if Profile.data.reduced_motion:
		burst_count = int(burst_count * 0.5)
		burst_power *= 0.5
	flash = 0.18 * (0.5 if Profile.data.reduced_motion else 1.0)
	burst(Vector2(PLAYER_X, player_y), Color("ffffff"), burst_count, burst_power)
	Integrations.haptic(20)

func _process(delta: float) -> void:
	# Debug templates only: sample actual rendered-frame spacing instead of
	# the fixed physics delta. Keep the profiler out of release exports.
	if not OS.is_debug_build() or state != "PLAYING":
		return
	qa_worst_frame_ms = maxf(qa_worst_frame_ms, delta * 1000.0)
	qa_sample_elapsed += delta
	if qa_sample_elapsed >= QA_SAMPLE_INTERVAL:
		ui.qa_perf.text = "QA FPS %d  |  WORST %.0f ms" % [Engine.get_frames_per_second(), qa_worst_frame_ms]
		qa_sample_elapsed = 0.0
		qa_worst_frame_ms = 0.0


func _physics_process(delta: float) -> void:
	if state != "PLAYING":
		# Finish death VFX even after gameplay stops. When idle and settled,
		# avoid issuing needless 60 Hz redraws on battery-powered devices.
		var effects_active: bool = not particles.is_empty() or camera_kick > 0.0 or flash > 0.0
		if not particles.is_empty():
			animate_particles(delta)
		camera_kick = move_toward(camera_kick, 0.0, delta * 5.0)
		flash = move_toward(flash, 0.0, delta * 2.8)
		if effects_active:
			queue_redraw()
		return
	elapsed += delta
	# Retain a short jump window after stepping off a ledge; not after a jump.
	coyote_remaining = maxf(0.0, coyote_remaining - delta)
	jump_buffer_remaining = maxf(0.0, jump_buffer_remaining - delta)
	speed = minf(MAX_RUN_SPEED, 470.0 + elapsed * 7.5 + float(score) * 0.42)
	move_world(delta)
	update_player(delta)
	# Consume a buffered pre-landing tap only on a real supported landing.
	# A successful landing is still scored before this new jump begins.
	if state == "PLAYING" and on_ground and jump_buffer_remaining > 0.0:
		jump()
	if landing_cue_remaining > 0.0:
		landing_cue_remaining = maxf(0.0, landing_cue_remaining - delta)
		ui.landing.visible = landing_cue_remaining > 0.0
		if ui.landing.visible:
			var alpha: float = 1.0 if bool(Profile.data.reduced_motion) else clampf(landing_cue_remaining / 0.16, 0.0, 1.0)
			ui.landing.modulate = Color(1.0, 1.0, 1.0, alpha)
	animate_particles(delta)
	camera_kick = move_toward(camera_kick, 0.0, delta * 5.0)
	flash = move_toward(flash, 0.0, delta * 2.8)
	update_ui()
	queue_redraw()

func move_world(delta: float) -> void:
	var dx: float = speed * delta
	for p: Dictionary in platforms:
		p.x = float(p.x) - dx
		if not bool(p.passed) and float(p.x) + float(p.w) < PLAYER_X - PLAYER_R:
			p.passed = true
			score += int(10.0 * flow)
	for i: int in range(platforms.size() - 1, -1, -1):
		if float(platforms[i].x) + float(platforms[i].w) < -140.0:
			platforms.remove_at(i)
	var rightmost: float = -100.0
	for p: Dictionary in platforms:
		rightmost = maxf(rightmost, float(p.x) + float(p.w))
	while rightmost < 1450.0:
		rightmost = spawn_platform_after(rightmost)

func update_player(delta: float) -> void:
	var old_y: float = player_y
	if not on_ground:
		player_vy += GRAVITY * delta
		player_y += player_vy * delta
		if player_vy > 0.0:
			try_land(old_y)
	elif not has_support():
		on_ground = false
		player_vy = 40.0
		coyote_remaining = COYOTE_TIME
	collect_coin()
	if player_y - PLAYER_R > FLOOR_LIMIT:
		die()

func try_land(old_y: float) -> void:
	var old_bottom: float = old_y + PLAYER_R
	var new_bottom: float = player_y + PLAYER_R
	for p: Dictionary in platforms:
		var px: float = float(p.x)
		var pw: float = float(p.w)
		var py: float = float(p.y)
		# A landing must have enough horizontal overlap to remain supported
		# on the next physics tick; a mere sprite-edge graze is not stable.
		if PLAYER_X <= px - PLAYER_R * 0.3 or PLAYER_X >= px + pw + PLAYER_R * 0.3:
			continue
		if old_bottom <= py + 8.0 and new_bottom >= py:
			player_y = py - PLAYER_R
			player_vy = 0.0
			on_ground = true
			pulse_available = true
			coyote_remaining = 0.0
			on_landed(p)
			return

func has_support() -> bool:
	for p: Dictionary in platforms:
		var px: float = float(p.x)
		var pw: float = float(p.w)
		var py: float = float(p.y)
		if absf((player_y + PLAYER_R) - py) < 12.0 and PLAYER_X > px - PLAYER_R * 0.3 and PLAYER_X < px + pw + PLAYER_R * 0.3:
			return true
	return false

func on_landed(p: Dictionary) -> void:
	if int(p.id) == last_platform_id:
		return
	last_platform_id = int(p.id)
	var center: float = float(p.x) + float(p.w) * 0.5
	var perfect_zone: float = minf(80.0, float(p.w) * 0.22)
	var perfect: bool = absf(PLAYER_X - center) <= perfect_zone
	var left_edge: float = float(p.x)
	var right_edge: float = float(p.x) + float(p.w)
	var edge_distance: float = minf(absf(PLAYER_X - left_edge), absf(right_edge - PLAYER_X))
	var clutch: bool = not perfect and edge_distance <= PLAYER_R * 0.72
	var feedback_scale: float = 0.35 if bool(Profile.data.reduced_motion) else 1.0
	var score_before_landing: int = score
	var judgement: String = "LANDED"
	var judgement_color: Color = skin_color()
	if perfect:
		judgement = "PERFECT"
		judgement_color = Color("ffe66d")
		combo += 1
		perfects += 1
		# A successful landing must never reduce FLOW earned by a prior streak.
		flow = minf(5.0, maxf(flow, 1.0 + float(combo) * 0.25))
		score += int(18.0 * flow)
		camera_kick = 9.0 * feedback_scale
		flash = 0.24 * feedback_scale
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), Color("ffffff"), maxi(4, int(22.0 * feedback_scale)), 420.0 * feedback_scale)
		Integrations.haptic(32)
	elif clutch:
		judgement = "CLUTCH"
		judgement_color = Color("ffb46a")
		combo += 1
		# A clutch recovery keeps momentum rather than downgrading a perfect streak.
		flow = minf(5.0, maxf(flow, 1.0 + float(combo) * 0.18))
		score += int(12.0 * flow)
		camera_kick = 12.0 * feedback_scale
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), Color("ffe66d"), maxi(4, int(18.0 * feedback_scale)), 360.0 * feedback_scale)
		Integrations.haptic(26)
	else:
		combo = maxi(0, combo - 1)
		# Do not reconstruct FLOW from a different multiplier: ordinary
		# landings should never raise the reward after a clutch.
		flow = maxf(1.0, flow - 0.25)
		var ordinary_feedback_scale: float = 0.45 if bool(Profile.data.reduced_motion) else 1.0
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), skin_color(), maxi(3, int(6.0 * ordinary_feedback_scale)), 180.0 * ordinary_feedback_scale)
	var awarded: int = score - score_before_landing
	var cue_text: String = "%s  +%d" % [judgement, awarded] if awarded > 0 else judgement
	show_landing_cue(cue_text, judgement_color)
	Integrations.event("landing", {"perfect": perfect, "clutch": clutch, "combo": combo, "score": score})

func show_landing_cue(message: String, color: Color) -> void:
	landing_cue_remaining = LANDING_CUE_DURATION
	ui.landing.text = message
	ui.landing.add_theme_color_override("font_color", Color("ffffff") if bool(Profile.data.high_contrast) else color)
	ui.landing.modulate = Color.WHITE
	ui.landing.visible = true

func collect_coin() -> void:
	for p: Dictionary in platforms:
		if not bool(p.coin) or bool(p.coin_taken):
			continue
		var cx: float = float(p.x) + float(p.w) * 0.5
		var cy: float = float(p.y) - 105.0
		if Vector2(PLAYER_X, player_y).distance_to(Vector2(cx, cy)) < 78.0:
			p.coin_taken = true
			run_coins += 1
			score += int(5.0 * flow)
			var coin_feedback_scale: float = 0.45 if bool(Profile.data.reduced_motion) else 1.0
			burst(Vector2(cx, cy), Color("ffe66d"), maxi(4, int(14.0 * coin_feedback_scale)), 300.0 * coin_feedback_scale)
			Integrations.haptic(10)

func die() -> void:
	if state != "PLAYING":
		return
	state = "DEAD"
	coyote_remaining = 0.0
	jump_buffer_remaining = 0.0
	landing_cue_remaining = 0.0
	ui.landing.visible = false
	# Compare against records from *before* committing this run. Comparing to
	# the updated best incorrectly called every tied score a "NEW BEST".
	var previous_best: int = int(Profile.data.best_score)
	var previous_daily_best: int = int(Profile.data.daily_best)
	Profile.record_run(score, run_coins, perfects, daily_mode)
	var result_label: String = "FLOW BROKEN"
	if score > previous_best:
		result_label = "NEW BEST"
	elif daily_mode and score > previous_daily_best:
		result_label = "NEW DAILY BEST"
	Integrations.leaderboard_submit(score, daily_mode)
	Integrations.event("run_end", {"score": score, "coins": run_coins, "perfects": perfects, "daily": daily_mode})
	ui.gameover.text = "SCORE %d\nBEST %d\nPERFECT %d  •  COINS %d\n%s" % [score, int(Profile.data.best_score), perfects, run_coins, result_label]
	ui.gameover.visible = true
	ui.retry.visible = true
	ui.share.visible = true
	ui.title.visible = false
	ui.subtitle.visible = false
	ui.hint.visible = false
	ui.mission.visible = false
	ui.daily.visible = false
	ui.normal.visible = false
	ui.skin.visible = false
	ui.settings.visible = false
	refresh_settings_ui()
	var death_feedback_scale: float = 0.3 if bool(Profile.data.reduced_motion) else 1.0
	camera_kick = 18.0 * death_feedback_scale
	flash = 0.35 * death_feedback_scale
	burst(Vector2(PLAYER_X, player_y), skin_color(), maxi(5, int(35.0 * death_feedback_scale)), 520.0 * death_feedback_scale)
	Integrations.haptic(70)

func make_platform(x: float, y: float, width: float, id_value: int) -> Dictionary:
	return {
		"x": x, "y": y, "w": width, "h": 46.0,
		"id": id_value, "passed": false,
		"coin": level_rng.randf() < 0.42, "coin_taken": false
	}

func spawn_platform_after(right_edge: float) -> float:
	var difficulty: float = clampf(elapsed / 70.0, 0.0, 1.0)
	var gap_max: float = lerpf(285.0, 350.0, difficulty)
	var width_max: float = lerpf(430.0, 290.0, difficulty)
	var width: float = level_rng.randf_range(230.0, width_max)
	var previous_y: float = 1490.0
	var previous_width: float = 300.0
	if not platforms.is_empty():
		previous_y = float(platforms[-1].y)
		previous_width = float(platforms[-1].w)
	var y: float = clampf(previous_y + level_rng.randf_range(-165.0, 165.0), 980.0, 1560.0)

	# At high scrolling speeds a fixed short gap can make the next platform
	# disappear *before* a normal jump descends to its height. Account for
	# travel during the exact ballistic descent (including elevation change).
	# Use a small speed lookahead for acceleration while the route approaches.
	var projected_speed: float = minf(MAX_RUN_SPEED, speed + PLATFORM_SPEED_LOOKAHEAD)
	var height_delta: float = y - previous_y
	var descending_time: float = (-JUMP_V + sqrt(JUMP_V * JUMP_V + 2.0 * GRAVITY * height_delta)) / GRAVITY
	var jump_travel: float = projected_speed * descending_time

	# The takeoff position can vary across the preceding platform. Keeping
	# 140 world units of timing space at either bound avoids both premature
	# arrival (too-wide gap) and overshoot (too-short gap). The resulting
	# wider late-game gaps replace impossible fast, narrow-platform routes.
	var safe_gap_min: float = maxf(145.0, jump_travel - previous_width - width + PLATFORM_TAKEOFF_WINDOW)
	var safe_gap_max: float = jump_travel - PLATFORM_TAKEOFF_WINDOW
	var sampled_gap_max: float = minf(safe_gap_max, maxf(gap_max, safe_gap_min + PLATFORM_GAP_VARIATION))
	var gap: float = level_rng.randf_range(safe_gap_min, sampled_gap_max)
	var platform: Dictionary = make_platform(right_edge + gap, y, width, next_platform_id)
	next_platform_id += 1
	platforms.append(platform)
	return float(platform.x) + float(platform.w)

func update_ui() -> void:
	# Only assign text/theme when the underlying gameplay values change.
	# Visibility remains correct on reset, start, landing and death.
	if score != hud_score_seen:
		ui.score.text = str(score)
		hud_score_seen = score
	var best_score: int = int(Profile.data.best_score)
	if best_score != hud_best_seen:
		ui.best.text = "BEST %d" % best_score
		hud_best_seen = best_score
	var bank: int = int(Profile.data.coins)
	if bank != hud_bank_seen or run_coins != hud_run_coins_seen:
		ui.coins.text = "◇ %d  +%d" % [bank, run_coins]
		hud_bank_seen = bank
		hud_run_coins_seen = run_coins
	var mode_id: int = 1 if daily_mode else 0
	if flow != hud_flow_seen or combo != hud_combo_seen or mode_id != hud_mode_seen:
		ui.flow.text = "%s  FLOW x%.2f  •  %d" % ["DAILY" if daily_mode else "ENDLESS", flow, combo]
		hud_flow_seen = flow
		hud_combo_seen = combo
		hud_mode_seen = mode_id
	var score_visible: bool = state != "READY"
	if ui.score.visible != score_visible:
		ui.score.visible = score_visible
	var flow_visible: bool = state == "PLAYING"
	if ui.flow.visible != flow_visible:
		ui.flow.visible = flow_visible
	var pulse_state: int = 0
	if flow_visible and not on_ground:
		pulse_state = 1 if pulse_available else (3 if jump_buffer_remaining > 0.0 else 2)
	var high_contrast: bool = bool(Profile.data.high_contrast)
	if pulse_state != hud_pulse_seen or (pulse_state != 0 and high_contrast != hud_contrast_seen):
		ui.pulse.visible = pulse_state != 0
		if pulse_state != 0:
			ui.pulse.text = "AIR PULSE READY" if pulse_state == 1 else ("JUMP QUEUED" if pulse_state == 3 else "AIR PULSE USED")
			var cue_color: Color = Color("62f7ff") if pulse_state == 1 else (Color("ffe66d") if pulse_state == 3 else Color("9ba5bd"))
			ui.pulse.add_theme_color_override("font_color", Color("ffffff") if high_contrast else cue_color)
		hud_pulse_seen = pulse_state
		hud_contrast_seen = high_contrast

func burst(pos: Vector2, color: Color, count: int, power: float) -> void:
	for _i: int in range(count):
		var angle: float = fx_rng.randf_range(0.0, TAU)
		var particle_speed: float = fx_rng.randf_range(power * 0.35, power)
		particles.append({"p": pos, "v": Vector2(cos(angle), sin(angle)) * particle_speed, "life": fx_rng.randf_range(0.28, 0.68), "max": 0.68, "c": color})

func animate_particles(delta: float) -> void:
	for item: Dictionary in particles:
		item.p = Vector2(item.p) + Vector2(item.v) * delta
		item.v = Vector2(item.v) * pow(0.04, delta)
		item.life = float(item.life) - delta
	for i: int in range(particles.size() - 1, -1, -1):
		if float(particles[i].life) <= 0.0:
			particles.remove_at(i)

func skin_color() -> Color:
	return SKINS[int(Profile.data.selected_skin) % SKINS.size()]

func _draw() -> void:
	var shake: Vector2 = Vector2(fx_rng.randf_range(-camera_kick, camera_kick), fx_rng.randf_range(-camera_kick, camera_kick)) if camera_kick > 0.2 else Vector2.ZERO
	var high_contrast_enabled: bool = bool(Profile.data.high_contrast)
	var reduced_motion_enabled: bool = bool(Profile.data.reduced_motion)

	# Layered dark-space atmosphere uses a fixed number of cheap canvas draws.
	# No textures, shaders, new dependencies, or animated full-screen overlays.
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color("070814"))
	if not high_contrast_enabled:
		draw_circle(Vector2(930.0, 330.0), 340.0, Color(0.16, 0.22, 0.48, 0.07))
		draw_circle(Vector2(100.0, 1420.0), 380.0, Color(0.10, 0.32, 0.46, 0.055))
	for i: int in range(9):
		var yy: float = 180.0 + float(i) * 205.0 + fposmod(elapsed * speed * (0.015 + float(i) * 0.002), 205.0)
		draw_line(Vector2(0.0, yy), Vector2(W, yy), Color(0.18, 0.25, 0.42, 0.10), 2.0)
	for i: int in range(18):
		# Positive wrapping keeps stars in motion when elapsed increases.
		var star_x: float = fposmod(float(i * 173) - elapsed * speed * 0.08, W + 220.0) - 110.0
		var star_y: float = 240.0 + fposmod(float(i * 127), 1180.0)
		var star_radius: float = 2.3 + float(i % 3)
		var star_color: Color = Color(0.42, 0.78, 1.0, 0.27) if not high_contrast_enabled else Color(1.0, 1.0, 1.0, 0.38)
		draw_circle(Vector2(star_x, star_y), star_radius, star_color)
		if i % 5 == 0:
			draw_line(Vector2(star_x - 9.0, star_y), Vector2(star_x + 9.0, star_y), Color(star_color.r, star_color.g, star_color.b, 0.17), 1.5)
			draw_line(Vector2(star_x, star_y - 9.0), Vector2(star_x, star_y + 9.0), Color(star_color.r, star_color.g, star_color.b, 0.17), 1.5)

	var platform_fill_color: Color = Color("2c3d70") if high_contrast_enabled else Color("17213d")
	var platform_edge_color: Color = Color("ffffff") if high_contrast_enabled else Color("65eaff")
	var platform_bevel_color: Color = Color("8299d0") if high_contrast_enabled else Color("31517c")
	var perfect_zone_color: Color = Color("ffe66d") if high_contrast_enabled else Color("ffffff")
	for p: Dictionary in platforms:
		var rect: Rect2 = Rect2(Vector2(float(p.x), float(p.y)) + shake, Vector2(float(p.w), float(p.h)))
		# Avoid drawing platforms that have already left the portrait viewport.
		if rect.end.x < -50.0 or rect.position.x > W + 50.0:
			continue
		# Subtle extrusion and lit beveled lip give flat blocks legible depth,
		# without moving the physical landing surface or widening collision.
		draw_rect(Rect2(rect.position + Vector2(0.0, 15.0), rect.size + Vector2(0.0, 20.0)), Color(0.0, 0.0, 0.0, 0.35), true)
		draw_rect(rect, platform_fill_color, true)
		draw_rect(Rect2(rect.position + Vector2(8.0, 11.0), Vector2(maxf(0.0, rect.size.x - 16.0), 12.0)), platform_bevel_color, true)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), Color(platform_edge_color.r, platform_edge_color.g, platform_edge_color.b, 0.12), 20.0)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), platform_edge_color, 9.0 if high_contrast_enabled else 6.0)
		draw_line(rect.position + Vector2(0.0, rect.size.y - 3.0), rect.position + Vector2(rect.size.x, rect.size.y - 3.0), Color(0.38, 0.53, 0.8, 0.23), 2.0)
		var perfect_w: float = minf(160.0, float(p.w) * 0.44)
		var zone_start: Vector2 = Vector2(float(p.x) + float(p.w) * 0.5 - perfect_w * 0.5, float(p.y) - 2.0) + shake
		var zone_end: Vector2 = zone_start + Vector2(perfect_w, 0.0)
		draw_line(zone_start, zone_end, Color(perfect_zone_color.r, perfect_zone_color.g, perfect_zone_color.b, 0.22), 16.0)
		draw_line(zone_start, zone_end, perfect_zone_color, 5.0 if high_contrast_enabled else 4.0)
		if bool(p.coin) and not bool(p.coin_taken):
			var coin_pos: Vector2 = Vector2(float(p.x) + float(p.w) * 0.5, float(p.y) - 105.0) + shake
			var coin_width: float = 1.0 if reduced_motion_enabled else 0.82 + 0.18 * absf(cos(elapsed * 4.1 + float(p.id)))
			# Layered collectible with a solid gold silhouette and inner cutout.
			draw_circle(coin_pos, 34.0, Color(1.0, 0.81, 0.21, 0.12))
			draw_circle(coin_pos, 25.0 * coin_width, Color("ffe66d"))
			draw_circle(coin_pos, 19.0 * coin_width, Color("d7a43f"))
			draw_circle(coin_pos, 13.0 * coin_width, Color("100f20"))
			draw_circle(coin_pos + Vector2(-7.0 * coin_width, -9.0), 3.8, Color(1.0, 1.0, 1.0, 0.65))

	var player_color: Color = skin_color()
	var player_pos: Vector2 = Vector2(PLAYER_X, player_y) + shake
	var trail_steps: int = 1 if reduced_motion_enabled else 4
	for i: int in range(trail_steps, 0, -1):
		draw_circle(player_pos + Vector2(-float(i) * 22.0, 0.0), PLAYER_R * (0.62 + float(i) * 0.06), Color(player_color.r, player_color.g, player_color.b, 0.035 * float(5 - i)))
	# The hero remains a high-contrast round silhouette, with glossy material
	# and rim lighting that does not affect its physical radius.
	draw_circle(player_pos, PLAYER_R + 20.0, Color(player_color.r, player_color.g, player_color.b, 0.08) if not high_contrast_enabled else Color(1.0, 1.0, 1.0, 0.13))
	draw_circle(player_pos, PLAYER_R + 9.0, Color("ffffff") if high_contrast_enabled else Color(player_color.r, player_color.g, player_color.b, 0.24))
	draw_circle(player_pos, PLAYER_R, player_color)
	draw_circle(player_pos + Vector2(10.0, 13.0), 22.0, Color(0.04, 0.08, 0.18, 0.16))
	draw_arc(player_pos, PLAYER_R - 5.0, PI + 0.12, TAU - 0.45, 26, Color(1.0, 1.0, 1.0, 0.20), 3.0)
	draw_circle(player_pos + Vector2(-12.0, -15.0), 14.0, Color(1.0, 1.0, 1.0, 0.22))
	draw_circle(player_pos + Vector2(-16.0, -19.0), 4.0, Color(1.0, 1.0, 1.0, 0.42))
	draw_circle(player_pos + Vector2(14.0, -8.0), 7.0, Color("07101c"))
	draw_circle(player_pos + Vector2(16.0, -10.0), 2.0, Color("ffffff"))
	if pulse_available and not on_ground and state == "PLAYING":
		draw_arc(player_pos, PLAYER_R + 18.0, 0.0, TAU, 32, Color(0.39, 0.97, 1.0, 0.20), 9.0)
		draw_arc(player_pos, PLAYER_R + 18.0, 0.0, TAU, 32, Color("ffffff"), 3.0)
	for item: Dictionary in particles:
		var alpha: float = clampf(float(item.life) / float(item.max), 0.0, 1.0)
		var particle_color: Color = Color(item.c)
		draw_circle(Vector2(item.p) + shake, 5.0 + 6.0 * alpha, Color(particle_color.r, particle_color.g, particle_color.b, alpha))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(1.0, 1.0, 1.0, flash * 0.34), true)
