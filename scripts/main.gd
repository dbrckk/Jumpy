extends Node2D

const W := 1080.0
const H := 1920.0
const PLAYER_X := 270.0
const PLAYER_R := 42.0
const GRAVITY := 2550.0
const JUMP_V := -1080.0
const PULSE_V := -620.0
const FLOOR_LIMIT := 1820.0

const SKINS := [
	Color("62f7ff"), Color("ff5fd2"), Color("ffe66d"),
	Color("8aff80"), Color("a88bff"), Color("ff8f5f")
]

var state := "READY"
var daily_mode := false
var rng := RandomNumberGenerator.new()
var platforms: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var player_y := 1390.0
var player_vy := 0.0
var on_ground := true
var pulse_available := true
var speed := 470.0
var score := 0
var run_coins := 0
var combo := 0
var flow := 1.0
var perfects := 0
var elapsed := 0.0
var camera_kick := 0.0
var flash := 0.0
var last_platform_id := -1
var next_platform_id := 1

var ui := {}

func _ready() -> void:
	build_ui()
	reset_run(false)
	Integrations.event("game_open")

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
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
	ui.daily = make_button(root, "DAILY", Vector2(170, 1110), Vector2(330, 96), func(): set_daily(true))
	ui.normal = make_button(root, "ENDLESS", Vector2(580, 1110), Vector2(330, 96), func(): set_daily(false))
	ui.skin = make_button(root, "SKIN", Vector2(375, 1240), Vector2(330, 82), cycle_skin)
	ui.gameover = make_label(root, "", 58, Vector2(80, 580), Vector2(920, 280), HORIZONTAL_ALIGNMENT_CENTER)
	ui.retry = make_button(root, "RETRY", Vector2(280, 940), Vector2(520, 110), restart_pressed)
	ui.share = make_button(root, "SHARE", Vector2(330, 1080), Vector2(420, 86), func(): Integrations.share_score(score, daily_mode))

func make_label(parent: Control, text: String, size: int, pos: Vector2, dim: Vector2, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
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
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = dim
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 28)
	b.pressed.connect(pressed)
	parent.add_child(b)
	return b

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
	player_y = 1390.0
	player_vy = 0.0
	on_ground = true
	pulse_available = true
	last_platform_id = 0
	next_platform_id = 1
	particles.clear()
	platforms.clear()
	if daily_mode:
		rng.seed = Profile.daily_seed()
	else:
		rng.randomize()
	platforms.append(make_platform(0.0, 1490.0, 560.0, 0))
	var x := 560.0
	while x < 1500.0:
		x = spawn_platform_after(x)
	show_menu(true)
	update_ui()
	queue_redraw()

func set_daily(value: bool) -> void:
	reset_run(value)
	ui.subtitle.text = "DAILY SEED • SAME WORLD FOR EVERYONE" if value else "TAP • LAND • FLOW"

func cycle_skin() -> void:
	var unlocked: Array = Profile.data.unlocked_skins
	if unlocked.is_empty():
		return
	var current := unlocked.find(int(Profile.data.selected_skin))
	var next := unlocked[(current + 1) % unlocked.size()]
	Profile.select_skin(next)
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
	ui.title.visible = value
	ui.subtitle.visible = value
	ui.hint.visible = value
	ui.mission.visible = value
	ui.daily.visible = value
	ui.normal.visible = value
	ui.skin.visible = value
	ui.gameover.visible = false
	ui.retry.visible = false
	ui.share.visible = false
	if value:
		var m := Profile.get_mission_progress()
		ui.mission.text = "MISSIONS  •  RUNS %d/%d  •  PERFECT %d/%d\nTOTAL SCORE %d/%d" % [m.runs, m.runs_goal, m.perfects, m.perfects_goal, m.score, m.score_goal]

func _unhandled_input(event: InputEvent) -> void:
	var tapped := false
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
	burst(Vector2(PLAYER_X, player_y + PLAYER_R), skin_color(), 8, 230.0)
	Integrations.haptic(14)

func pulse() -> void:
	pulse_available = false
	player_vy = min(player_vy, PULSE_V)
	burst(Vector2(PLAYER_X, player_y), Color("ffffff"), 14, 320.0)
	flash = 0.18
	Integrations.haptic(20)

func _physics_process(delta: float) -> void:
	if state != "PLAYING":
		animate_particles(delta)
		queue_redraw()
		return
	elapsed += delta
	speed = min(970.0, 470.0 + elapsed * 7.5 + score * 0.42)
	move_world(delta)
	update_player(delta)
	animate_particles(delta)
	camera_kick = move_toward(camera_kick, 0.0, delta * 5.0)
	flash = move_toward(flash, 0.0, delta * 2.8)
	update_ui()
	queue_redraw()

func move_world(delta: float) -> void:
	var dx := speed * delta
	for p in platforms:
		p.x -= dx
		if not p.passed and p.x + p.w < PLAYER_X - PLAYER_R:
			p.passed = true
			var gain := int(10.0 * flow)
			score += gain
			if p.coin and not p.coin_taken:
				pass
	for i in range(platforms.size() - 1, -1, -1):
		if platforms[i].x + platforms[i].w < -140.0:
			platforms.remove_at(i)
	var rightmost := -100.0
	for p in platforms:
		rightmost = max(rightmost, p.x + p.w)
	while rightmost < 1450.0:
		rightmost = spawn_platform_after(rightmost)

func update_player(delta: float) -> void:
	var old_y := player_y
	if not on_ground:
		player_vy += GRAVITY * delta
		player_y += player_vy * delta
		if player_vy > 0.0:
			try_land(old_y)
	else:
		if not has_support():
			on_ground = false
			player_vy = 40.0
	collect_coin()
	if player_y - PLAYER_R > FLOOR_LIMIT:
		die()

func try_land(old_y: float) -> void:
	var old_bottom := old_y + PLAYER_R
	var new_bottom := player_y + PLAYER_R
	for p in platforms:
		if PLAYER_X + PLAYER_R < p.x or PLAYER_X - PLAYER_R > p.x + p.w:
			continue
		if old_bottom <= p.y + 8.0 and new_bottom >= p.y:
			player_y = p.y - PLAYER_R
			player_vy = 0.0
			on_ground = true
			pulse_available = true
			on_landed(p)
			return

func has_support() -> bool:
	for p in platforms:
		if abs((player_y + PLAYER_R) - p.y) < 12.0 and PLAYER_X > p.x - PLAYER_R * 0.3 and PLAYER_X < p.x + p.w + PLAYER_R * 0.3:
			return true
	return false

func on_landed(p: Dictionary) -> void:
	if int(p.id) == last_platform_id:
		return
	last_platform_id = int(p.id)
	var center := p.x + p.w * 0.5
	var perfect_zone := min(80.0, p.w * 0.22)
	var perfect := abs(PLAYER_X - center) <= perfect_zone
	if perfect:
		combo += 1
		perfects += 1
		flow = min(5.0, 1.0 + combo * 0.25)
		score += int(18.0 * flow)
		camera_kick = 9.0
		flash = 0.24
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), Color("ffffff"), 22, 420.0)
		Integrations.haptic(32)
	else:
		combo = max(0, combo - 1)
		flow = max(1.0, 1.0 + combo * 0.25)
		burst(Vector2(PLAYER_X, player_y + PLAYER_R), skin_color(), 6, 180.0)
	Integrations.event("landing", {"perfect": perfect, "combo": combo, "score": score})

func collect_coin() -> void:
	for p in platforms:
		if not p.coin or p.coin_taken:
			continue
		var cx := p.x + p.w * 0.5
		var cy := p.y - 105.0
		if Vector2(PLAYER_X, player_y).distance_to(Vector2(cx, cy)) < 78.0:
			p.coin_taken = true
			run_coins += 1
			score += int(5.0 * flow)
			burst(Vector2(cx, cy), Color("ffe66d"), 14, 300.0)
			Integrations.haptic(10)

func die() -> void:
	if state != "PLAYING":
		return
	state = "DEAD"
	var result := Profile.record_run(score, run_coins, perfects, daily_mode)
	Integrations.leaderboard_submit(score, daily_mode)
	Integrations.event("run_end", {"score": score, "coins": run_coins, "perfects": perfects, "daily": daily_mode})
	ui.gameover.text = "SCORE %d\nBEST %d\n%s" % [score, int(Profile.data.best_score), "NEW BEST" if score >= int(Profile.data.best_score) and score > 0 else "FLOW BROKEN"]
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
	camera_kick = 18.0
	flash = 0.35
	burst(Vector2(PLAYER_X, player_y), skin_color(), 35, 520.0)
	Integrations.haptic(70)

func make_platform(x: float, y: float, width: float, id_value: int) -> Dictionary:
	return {
		"x": x, "y": y, "w": width, "h": 46.0,
		"id": id_value, "passed": false,
		"coin": rng.randf() < 0.42, "coin_taken": false
	}

func spawn_platform_after(right_edge: float) -> float:
	var difficulty := clamp(elapsed / 70.0, 0.0, 1.0)
	var gap := rng.randf_range(145.0, lerp(285.0, 350.0, difficulty))
	var width := rng.randf_range(230.0, lerp(430.0, 290.0, difficulty))
	var previous_y := 1490.0
	if not platforms.is_empty():
		previous_y = float(platforms[-1].y)
	var y := clamp(previous_y + rng.randf_range(-165.0, 165.0), 980.0, 1560.0)
	var p := make_platform(right_edge + gap, y, width, next_platform_id)
	next_platform_id += 1
	platforms.append(p)
	return p.x + p.w

func update_ui() -> void:
	ui.score.text = str(score)
	ui.flow.text = "FLOW x%.2f  •  %d" % [flow, combo]
	ui.best.text = "BEST %d" % int(Profile.data.best_score)
	ui.coins.text = "◇ %d  +%d" % [int(Profile.data.coins), run_coins]
	ui.score.visible = state != "READY"
	ui.flow.visible = state == "PLAYING"

func burst(pos: Vector2, color: Color, count: int, power: float) -> void:
	for i in range(count):
		var a := rng.randf_range(0.0, TAU)
		var sp := rng.randf_range(power * 0.35, power)
		particles.append({"p": pos, "v": Vector2(cos(a), sin(a)) * sp, "life": rng.randf_range(0.28, 0.68), "max": 0.68, "c": color})

func animate_particles(delta: float) -> void:
	for item in particles:
		item.p += item.v * delta
		item.v *= pow(0.04, delta)
		item.life -= delta
	for i in range(particles.size() - 1, -1, -1):
		if particles[i].life <= 0.0:
			particles.remove_at(i)

func skin_color() -> Color:
	return SKINS[int(Profile.data.selected_skin) % SKINS.size()]

func _draw() -> void:
	var shake := Vector2(rng.randf_range(-camera_kick, camera_kick), rng.randf_range(-camera_kick, camera_kick)) if camera_kick > 0.2 else Vector2.ZERO
	draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color("070814"))
	# Parallax neon skyline / atmosphere.
	for i in range(9):
		var yy := 180.0 + i * 205.0 + fmod(elapsed * speed * (0.015 + i * 0.002), 205.0)
		draw_line(Vector2(0, yy), Vector2(W, yy), Color(0.18, 0.25, 0.42, 0.10), 2.0)
	for i in range(18):
		var x := fmod(float(i * 173) - elapsed * speed * 0.08, W + 220.0) - 110.0
		var y := 240.0 + fmod(float(i * 127), 1180.0)
		draw_circle(Vector2(x, y), 2.5 + (i % 3), Color(0.42, 0.78, 1.0, 0.22))
	for p in platforms:
		var rect := Rect2(Vector2(p.x, p.y) + shake, Vector2(p.w, p.h))
		draw_rect(rect, Color("17213d"), true)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color("65eaff"), 7.0)
		var perfect_w := min(160.0, p.w * 0.44)
		draw_line(Vector2(p.x + p.w * 0.5 - perfect_w * 0.5, p.y - 2) + shake, Vector2(p.x + p.w * 0.5 + perfect_w * 0.5, p.y - 2) + shake, Color("ffffff"), 3.0)
		if p.coin and not p.coin_taken:
			var coin_pos := Vector2(p.x + p.w * 0.5, p.y - 105.0) + shake
			draw_circle(coin_pos, 25.0, Color("ffe66d"))
			draw_circle(coin_pos, 11.0, Color("070814"))
	# Player body and motion echo.
	var pc := skin_color()
	var pp := Vector2(PLAYER_X, player_y) + shake
	for i in range(4, 0, -1):
		draw_circle(pp + Vector2(-i * 22.0, 0), PLAYER_R * (0.62 + i * 0.06), Color(pc.r, pc.g, pc.b, 0.035 * (5 - i)))
	draw_circle(pp, PLAYER_R + 9.0, Color(pc.r, pc.g, pc.b, 0.18))
	draw_circle(pp, PLAYER_R, pc)
	draw_circle(pp + Vector2(14, -8), 7.0, Color("07101c"))
	if pulse_available and not on_ground and state == "PLAYING":
		draw_arc(pp, PLAYER_R + 18.0, 0.0, TAU, 32, Color("ffffff"), 3.0)
	for item in particles:
		var alpha := clamp(float(item.life) / float(item.max), 0.0, 1.0)
		var c: Color = item.c
		draw_circle(item.p + shake, 5.0 + 6.0 * alpha, Color(c.r, c.g, c.b, alpha))
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(W, H)), Color(1, 1, 1, flash * 0.34), true)
