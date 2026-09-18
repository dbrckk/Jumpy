This file is a merged representation of a subset of the codebase, containing specifically included files and files not matching ignore patterns, combined into a single document by Repomix.
The content has been processed where content has been compressed (code blocks are separated by ⋮---- delimiter).

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: **/*.{py,js,mjs,cjs,ts,tsx,jsx,java,kt,kts,gd,groovy,gradle,toml,json,yaml,yml,sql,sh}, README.md, AGENTS.md, PROJECT_*.md
- Files matching these patterns are excluded: .ai/**, **/node_modules/**, **/.gradle/**, **/build/**, **/dist/**, **/.venv/**, **/__pycache__/**, **/.pytest_cache/**, **/.git/**, **/coverage/**, **/*.lock, **/*.min.js, **/*.map, assets/**, art/**, art_sources/**, marketing/**, colab/**, kaggle/**, discovery-cache.json, health-snapshot.json, history.json
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Content has been compressed - code blocks are separated by ⋮---- delimiter
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
```
.github/
  workflows/
    ai-repo-map.yml
    validate.yml
.serena/
  project.yml
scripts/
  integrations.gd
  main.gd
  profile.gd
.repo-standards.yml
AGENTS.md
README.md
```

# Files

## File: .github/workflows/ai-repo-map.yml
```yaml
name: Repository standards

on:
  push:
    branches: [main]
    paths-ignore:
      - ".ai/**"
  workflow_dispatch:

permissions:
  contents: write
  actions: read

concurrency:
  group: repo-standards-${{ github.repository }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  repository-standards:
    uses: dbrckk/repo-standards/.github/workflows/reusable-unified.yml@v6
```

## File: .github/workflows/validate.yml
```yaml
name: Validate Godot Project

on:
  push:
    branches: [main]
  pull_request:

permissions:
  contents: read

jobs:
  godot-parse:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262 # immutable SHA
        with:
          persist-credentials: false
      - name: Install Godot 4.7.2 stable
        run: |
          set -euo pipefail
          GODOT_URL='https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip'
          curl --fail --location \
            --retry 5 --retry-all-errors --retry-delay 3 --connect-timeout 15 --max-time 180 \
            --output godot.zip "$GODOT_URL"
          test -s godot.zip
          unzip -tq godot.zip >/dev/null
          rm -rf .godot-ci
          mkdir -p .godot-ci
          unzip -q godot.zip -d .godot-ci
          mv .godot-ci/Godot_v4.7.2-stable_linux.x86_64 .godot-ci/godot
          chmod +x .godot-ci/godot
      - name: Import and parse project
        run: |
          set -euo pipefail
          .godot-ci/godot --headless --path . --editor --quit 2>&1 | tee godot.log
          if grep -E "SCRIPT ERROR|Parse Error|Cannot parse|Failed loading resource" godot.log; then
            echo "Godot reported a blocking parse/load error"
            exit 1
          fi
      - name: Verify required production docs
        run: |
          set -euo pipefail
          test -f SETUP_REQUIRED.txt
          test -f docs/GAME_DESIGN.md
          test -f scripts/integrations.gd
```

## File: .serena/project.yml
```yaml
project_name: "Jumpy"
language_servers:
  - gdscript
ls_workspace_folders:
  - "."
ignore_all_files_in_gitignore: true
ignored_paths:
  - ".godot/**"
  - "**/build/**"
  - "**/.import/**"
  - "assets/**"
read_only: false
encoding: utf-8
symbol_info_budget: 8
initial_prompt: |
  Use Serena's symbol and reference tools before reading whole files. Start with symbol overviews, find_symbol and find_referencing_symbols; fetch full file bodies only when required for the task. Prefer targeted edits and preserve the existing architecture.
```

## File: scripts/integrations.gd
```
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
```

## File: scripts/main.gd
```
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
```

## File: scripts/profile.gd
```
extends Node

const SAVE_PATH: String = "user://jumpy_save.json"
const SAVE_VERSION: int = 1

const DEFAULT_DATA: Dictionary = {
	"version": SAVE_VERSION,
	"best_score": 0,
	"coins": 0,
	"runs": 0,
	"perfect_landings": 0,
	"total_score": 0,
	"selected_skin": 0,
	"unlocked_skins": [0],
	"daily_best": 0,
	"daily_key": "",
	"streak_days": 0,
	"last_play_date": "",
	"sound": true,
	"haptics": true,
	"reduced_motion": false,
	"high_contrast": false
}

var data: Dictionary = DEFAULT_DATA.duplicate(true)

func _save_integer(value: Variant, fallback: int = 0, maximum: int = 2147483647) -> int:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return fallback
	var number: float = float(value)
	if not is_finite(number) or number < 0.0 or number > maximum or number != floor(number):
		return fallback
	return int(number)

func _save_date(value: Variant) -> String:
	if not value is String or value.length() != 10:
		return ""
	var parts: PackedStringArray = value.split("-")
	if parts.size() != 3 or parts[0].length() != 4 or parts[1].length() != 2 or parts[2].length() != 2:
		return ""
	for part in parts:
		if not part.is_valid_int() or part.begins_with("+") or part.begins_with("-"):
			return ""
	var year: int = int(parts[0])
	var month: int = int(parts[1])
	var day: int = int(parts[2])
	if year < 1 or month < 1 or month > 12:
		return ""
	var days: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
		days[1] = 29
	return value if day >= 1 and day <= days[month - 1] else ""

func _validated_save(parsed: Dictionary) -> Dictionary:
	var clean: Dictionary = DEFAULT_DATA.duplicate(true)
	for key in ["best_score", "coins", "runs", "perfect_landings", "total_score", "daily_best", "streak_days"]:
		clean[key] = _save_integer(parsed.get(key, 0))
	for key in ["sound", "haptics", "reduced_motion", "high_contrast"]:
		if typeof(parsed.get(key)) == TYPE_BOOL:
			clean[key] = parsed[key]
	for key in ["daily_key", "last_play_date"]:
		clean[key] = _save_date(parsed.get(key))
	var unlocks: Array = [0]
	var saved_unlocks: Variant = parsed.get("unlocked_skins")
	if saved_unlocks is Array:
		for item in saved_unlocks:
			var index: int = _save_integer(item, -1, 5)
			if index >= 0 and not index in unlocks:
				unlocks.append(index)
	clean.unlocked_skins = unlocks
	var selected: int = _save_integer(parsed.get("selected_skin", 0), 0, 5)
	clean.selected_skin = selected if selected in unlocks else 0
	return clean

func _ready() -> void:
	load_data()
	_refresh_daily()

func load_data() -> void:
	data = DEFAULT_DATA.duplicate(true)
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("Jumpy: unable to open save file; defaults preserved.")
		return
	if file.get_length() > 262144:
		push_warning("Jumpy: save file too large; defaults preserved.")
		return
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		push_warning("Jumpy: save file is invalid; defaults preserved.")
		return
	data = _validated_save(parser.data)

func save() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Jumpy: unable to open save file for writing. Error %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))
	file.flush()
	var error: Error = file.get_error()
	if error != OK:
		push_warning("Jumpy: save write failed with error %s" % error)

func set_preference(key: String, value: bool) -> void:
	if key not in ["sound", "haptics", "reduced_motion", "high_contrast"]:
		push_warning("Jumpy: unknown preference %s" % key)
		return
	data[key] = value
	save()

func record_run(score: int, run_coins: int, perfects: int, daily: bool) -> Dictionary:
	data.runs = int(data.runs) + 1
	data.coins = int(data.coins) + run_coins
	data.total_score = int(data.total_score) + score
	data.perfect_landings = int(data.perfect_landings) + perfects
	data.best_score = maxi(int(data.best_score), score)
	if daily:
		data.daily_best = maxi(int(data.daily_best), score)
	_update_streak()
	_unlock_earned_skins()
	save()
	return get_mission_progress()

func spend_coins(amount: int) -> bool:
	if amount <= 0 or int(data.coins) < amount:
		return false
	data.coins = int(data.coins) - amount
	save()
	return true

func select_skin(index: int) -> void:
	if index in data.unlocked_skins:
		data.selected_skin = index
		save()

func get_mission_progress() -> Dictionary:
	return {
		"runs": mini(int(data.runs), 10),
		"runs_goal": 10,
		"perfects": mini(int(data.perfect_landings), 50),
		"perfects_goal": 50,
		"score": mini(int(data.total_score), 5000),
		"score_goal": 5000
	}

func daily_seed() -> int:
	_refresh_daily()
	return absi(hash(str(data.daily_key)))

func _refresh_daily() -> void:
	var date: Dictionary = Time.get_date_dict_from_system()
	var key: String = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	if str(data.daily_key) != key:
		data.daily_key = key
		data.daily_best = 0
		save()

func _update_streak() -> void:
	var date: Dictionary = Time.get_date_dict_from_system()
	var today: String = "%04d-%02d-%02d" % [date.year, date.month, date.day]
	if str(data.last_play_date) == today:
		return
	if str(data.last_play_date).is_empty():
		data.streak_days = 1
	else:
		var now_unix: int = int(Time.get_unix_time_from_system())
		var last_unix: int = int(Time.get_unix_time_from_datetime_string(str(data.last_play_date) + "T00:00:00"))
		var days: int = int((now_unix - last_unix) / 86400.0)
		data.streak_days = int(data.streak_days) + 1 if days <= 1 else 1
	data.last_play_date = today

func _unlock_earned_skins() -> void:
	var unlocks: Array = data.unlocked_skins
	var milestones: Array[int] = [0, 250, 900, 2200, 5000, 10000]
	for i: int in range(milestones.size()):
		if int(data.total_score) >= milestones[i] and not i in unlocks:
			unlocks.append(i)
	data.unlocked_skins = unlocks
```

## File: .repo-standards.yml
```yaml
source: dbrckk/repo-standards
ref: v6
version: 6
adopted: true
workflow_mode: unified-single-commit
ai_context:
  index: .ai/index.md
  project_state: .ai/project-state.md
  change_impact: .ai/change-impact.md
  architecture: .ai/architecture.json
  dependency_map: .ai/dependency-map.json
  commands: .ai/commands.json
  ci_status: .ai/ci-status.md
  security_signals: .ai/security-signals.json
  repo_health: .ai/repo-health.md
  repo_map: .ai/repo-map.md
  segmented_maps: .ai/maps/
workflow:
  file: .github/workflows/ai-repo-map.yml
  reusable_unified: .github/workflows/reusable-unified.yml
```

## File: AGENTS.md
```markdown
# Repository agent instructions

This repository adopts shared standards from `dbrckk/repo-standards` at the release recorded in `.repo-standards.yml`.

Before substantial work:
1. Read the central `AGENTS.md` and relevant files under `standards/` at the configured standards ref.
2. Read `.ai/project-state.md`.
3. Read `.ai/change-impact.md`.
4. Read `.ai/architecture.json`.
5. Read `.ai/dependency-map.json` when changes may cross module/package boundaries.
6. Read `.ai/commands.json`.
7. Read `.ai/ci-status.md`.
8. Read `.ai/security-signals.json` for release/security-sensitive work.
9. Read `.ai/repo-health.md`.
10. Read `.ai/index.md`.
11. Prefer the relevant file under `.ai/maps/` when present.
12. Read `.ai/repo-map.md` only when the smaller context is insufficient.
13. Fetch only task-relevant source files or symbols.

Repository-specific rules:
- Preserve the existing architecture and public interfaces unless the task requires a change.
- Prefer the smallest coherent change.
- Run the relevant tests, lint, build, or validation commands before declaring completion.
- Treat commands in `.ai/commands.json` as detected candidates; verify them when confidence is not high.
- Treat `.ai/security-signals.json` as heuristic evidence, never proof of a secret leak.
- Never reproduce suspected secret values.
- Update the manual parts of `.ai/project-state.md` when status, blockers, or next priority materially changes.
```

## File: README.md
```markdown
# Jumpy

Jumpy is a portrait-first one-touch hybrid-casual arcade game designed around instant comprehension, short replayable runs, skill expression, social competition, and long-term collection.

## Core loop

**Tap. Jump. Land perfectly. Keep the FLOW alive.**

The world scrolls continuously. Tap from a platform to jump; tap once in the air to spend a corrective pulse. Perfect landings build FLOW, which raises score gain and feedback intensity. Miss the world and restart instantly.

## Already implemented

- Endless procedural platform generation.
- Difficulty/speed escalation.
- One-touch jump + single airborne pulse.
- Perfect-landing zones, combo and FLOW multiplier.
- Coins, run score, best score and persistent profile.
- Daily deterministic seed and daily best score.
- Missions, streak tracking and cosmetic skin unlock milestones.
- Haptic abstraction with mobile support.
- Share fallback through clipboard.
- Leaderboard, analytics and rewarded-ad integration boundaries.
- Procedural neon rendering: no proprietary asset dependency.
- Portrait mobile layout with desktop controls for development.

## Engine

Godot 4.x / GDScript. Open `project.godot` and run `scenes/Main.tscn`.

Desktop controls: Space, Enter or left click.

## Product strategy

Jumpy is intentionally not pure hypercasual. The core interaction remains one-second-simple, while progression, daily competition, cosmetics, missions and future LiveOps create retention depth. See `docs/GAME_DESIGN.md`.

## External production setup

The game runs without external services. Optional production integrations are documented in `SETUP_REQUIRED.txt` so missing credentials never block development.
```
