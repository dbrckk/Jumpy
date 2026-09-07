extends Node2D

const W: float = 1080.0
const H: float = 1920.0
const PLAYER_X: float = 270.0
const PLAYER_R: float = 42.0
const GRAVITY: float = 2550.0
const JUMP_V: float = -1080.0
const PULSE_V: float = -620.0
const FLOOR_LIMIT: float = 1820.0

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
var last_platform_id: int = -1
var next_platform_id: int = 1
var ui: Dictionary = {}
var settings_open: bool = false

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
	layer.add_child(root)

	ui.score = make_label(root, "0", 80, Vector2(0, 90), Vector2(W, 110), HORIZONTAL_ALIGNMENT_CENTER)
	ui.flow = make_label(root, "FLOW x1.0", 30, Vector2(0, 180), Vector2(W, 50), HORIZONTAL_ALIGNMENT_CENTER)
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
	show_menu(true)

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
	reset_run(value)
	ui.subtitle.text = "DAILY SEED • DAILY BEST %d" % int(Profile.data.daily_best) if value else "TAP • LAND • FLOW"

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
	jump()
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
	var tapped: bool = false
	if event.is_action_pressed("tap"):
		tapped = true
	elif event is InputEventScreenTouch and event.pressed:
		tapped = true
	if not tapped:
		return
	if state == "READY":
		start_run()
	elif state == "PLAYING":
		if on_ground:
			jump()
		elif pulse_available:
			pulse()
	elif state == "DEAD":
		restart_pressed()

func jump() -> void:
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

func _physics_process(delta: float) -> void:
	if state != "PLAYING":
		animate_particles(delta)
		queue_redraw()
		return
	elapsed += delta
	speed = minf(970.0, 470.0 + elapsed * 7.5 + float(score) * 0.42)
	move_world(delta)
	update_player(delta)
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
		if PLAYER_X + PLAYER_R < px or PLAYER_X - PLAYER_R > px + pw:
			continue
		if old_bottom <= py + 8.0 and new_bottom >= py:
			player_y = py - PLAYER_R
			player_vy = 0.0
			on_ground = true
			pulse_available = true
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
	if perfect:
		combo += 1
		perfects += 1
		flow = minf(5.0, 1.0 + float(combo) * 0.25)
		score += int(18.0 * flow)
		camera_kick = 9.0 * feedback_scale
		flash = 0.24 * feedback_scale
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), Color("ffffff"), maxi(4, int(22.0 * feedback_scale)), 420.0 * feedback_scale)
		Integrations.haptic(32)
	elif clutch:
		combo += 1
		flow = minf(5.0, 1.0 + float(combo) * 0.18)
		score += int(12.0 * flow)
		camera_kick = 12.0 * feedback_scale
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), Color("ffe66d"), maxi(4, int(18.0 * feedback_scale)), 360.0 * feedback_scale)
		Integrations.haptic(26)
	else:
		combo = maxi(0, combo - 1)
		flow = maxf(1.0, 1.0 + float(combo) * 0.25)
		var ordinary_feedback_scale: float = 0.45 if bool(Profile.data.reduced_motion) else 1.0
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), skin_color(), maxi(3, int(6.0 * ordinary_feedback_scale)), 180.0 * ordinary_feedback_scale)
	Integrations.event("landing", {"perfect": perfect, "clutch": clutch, "combo": combo, "score": score})

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
	Profile.record_run(score, run_coins, perfects, daily_mode)
	Integrations.leaderboard_submit(score, daily_mode)
	Integrations.event("run_end", {"score": score, "coins": run_coins, "perfects": perfects, "daily": daily_mode})
	ui.gameover.text = "SCORE %d\nBEST %d\nPERFECT %d  •  COINS %d\n%s" % [score, int(Profile.data.best_score), perfects, run_coins, "NEW BEST" if score >= int(Profile.data.best_score) and score > 0 else "FLOW BROKEN"]
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
	var gap: float = level_rng.randf_range(145.0, gap_max)
	var width: float = level_rng.randf_range(230.0, width_max)
	var previous_y: float = 1490.0
	if not platforms.is_empty():
		previous_y = float(platforms[-1].y)
	var y: float = clampf(previous_y + level_rng.randf_range(-165.0, 165.0), 980.0, 1560.0)
	var platform: Dictionary = make_platform(right_edge + gap, y, width, next_platform_id)
	next_platform_id += 1
	platforms.append(platform)
	return float(platform.x) + float(platform.w)

func update_ui() -> void:
	ui.score.text = str(score)
	ui.flow.text = "FLOW x%.2f  •  %d" % [flow, combo]
	ui.best.text = "BEST %d" % int(Profile.data.best_score)
	ui.coins.text = "◇ %d  +%d" % [int(Profile.data.coins), run_coins]
	ui.score.visible = state != "READY"
	ui.flow.visible = state == "PLAYING"

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
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color("070814"))
	for i: int in range(9):
		var yy: float = 180.0 + float(i) * 205.0 + fmod(elapsed * speed * (0.015 + float(i) * 0.002), 205.0)
		draw_line(Vector2(0, yy), Vector2(W, yy), Color(0.18, 0.25, 0.42, 0.10), 2.0)
	for i: int in range(18):
		var star_x: float = fmod(float(i * 173) - elapsed * speed * 0.08, W + 220.0) - 110.0
		var star_y: float = 240.0 + fmod(float(i * 127), 1180.0)
		draw_circle(Vector2(star_x, star_y), 2.5 + float(i % 3), Color(0.42, 0.78, 1.0, 0.22))
	var high_contrast_enabled: bool = bool(Profile.data.high_contrast)
	var platform_fill_color: Color = Color("2c3d70") if high_contrast_enabled else Color("17213d")
	var platform_edge_color: Color = Color("ffffff") if high_contrast_enabled else Color("65eaff")
	var perfect_zone_color: Color = Color("ffe66d") if high_contrast_enabled else Color("ffffff")
	for p: Dictionary in platforms:
		var rect: Rect2 = Rect2(Vector2(float(p.x), float(p.y)) + shake, Vector2(float(p.w), float(p.h)))
		draw_rect(rect, platform_fill_color, true)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), platform_edge_color, 9.0 if high_contrast_enabled else 7.0)
		var perfect_w: float = minf(160.0, float(p.w) * 0.44)
		draw_line(Vector2(float(p.x) + float(p.w) * 0.5 - perfect_w * 0.5, float(p.y) - 2.0) + shake, Vector2(float(p.x) + float(p.w) * 0.5 + perfect_w * 0.5, float(p.y) - 2.0) + shake, perfect_zone_color, 5.0 if high_contrast_enabled else 3.0)
		if bool(p.coin) and not bool(p.coin_taken):
			var coin_pos: Vector2 = Vector2(float(p.x) + float(p.w) * 0.5, float(p.y) - 105.0) + shake
			draw_circle(coin_pos, 25.0, Color("ffe66d"))
			draw_circle(coin_pos, 11.0, Color("070814"))
	var player_color: Color = skin_color()
	var player_pos: Vector2 = Vector2(PLAYER_X, player_y) + shake
	var trail_steps: int = 1 if bool(Profile.data.reduced_motion) else 4
	for i: int in range(trail_steps, 0, -1):
		draw_circle(player_pos + Vector2(-float(i) * 22.0, 0), PLAYER_R * (0.62 + float(i) * 0.06), Color(player_color.r, player_color.g, player_color.b, 0.035 * float(5 - i)))
	draw_circle(player_pos, PLAYER_R + 11.0 if high_contrast_enabled else PLAYER_R + 9.0, Color("ffffff") if high_contrast_enabled else Color(player_color.r, player_color.g, player_color.b, 0.18))
	draw_circle(player_pos, PLAYER_R, player_color)
	draw_circle(player_pos + Vector2(14, -8), 7.0, Color("07101c"))
	if pulse_available and not on_ground and state == "PLAYING":
		draw_arc(player_pos, PLAYER_R + 18.0, 0.0, TAU, 32, Color("ffffff"), 3.0)
	for item: Dictionary in particles:
		var alpha: float = clampf(float(item.life) / float(item.max), 0.0, 1.0)
		var particle_color: Color = Color(item.c)
		draw_circle(Vector2(item.p) + shake, 5.0 + 6.0 * alpha, Color(particle_color.r, particle_color.g, particle_color.b, alpha))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(1, 1, 1, flash * 0.34), true)
