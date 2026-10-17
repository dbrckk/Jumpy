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
    android-debug-apk.yml
    production-os-review-handoff.yml
    semantic-refresh.yml
    validate.yml
.serena/
  project.yml
scripts/
  integrations.gd
  main.gd
  profile.gd
tools/
  smoke_mobile_input.gd
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
    uses: dbrckk/repo-standards/.github/workflows/reusable-unified.yml@main
```

## File: .github/workflows/android-debug-apk.yml
```yaml
name: Android debug APK (device QA)

on:
  workflow_dispatch:
  pull_request:
    paths:
      - .github/workflows/android-debug-apk.yml
      - 'scripts/**'
      - 'scenes/**'
      - 'assets/**'
      - 'addons/**'
      - project.godot
      - export_presets.cfg
  push:
    branches: [main]
    paths:
      - .github/workflows/android-debug-apk.yml
      - 'scripts/**'
      - 'scenes/**'
      - 'assets/**'
      - 'addons/**'
      - project.godot
      - export_presets.cfg

permissions:
  contents: read

jobs:
  android-debug:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@11d5960a326750d5838078e36cf38b85af677262
        with:
          persist-credentials: false
      - name: Set up Java 17
        uses: actions/setup-java@cf277c60eb25467037889841efdb72551f06f6c3
        with:
          distribution: temurin
          java-version: '17'
      - name: Prepare Android SDK
        shell: bash
        run: |
          set -euo pipefail
          : "${ANDROID_HOME:?Android SDK missing from runner}"
          test -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
          "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
            --sdk_root="$ANDROID_HOME" \
            'platform-tools' 'platforms;android-36' 'build-tools;36.1.0'
          test -x "$ANDROID_HOME/platform-tools/adb"
      - name: Install pinned Godot 4.7.2 editor
        shell: bash
        run: |
          set -euo pipefail
          curl -fL --retry 5 --retry-all-errors --retry-delay 3 \
            --connect-timeout 15 --max-time 180 \
            -o godot.zip \
            https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
          echo 'cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4  godot.zip' | sha256sum -c -
          mkdir -p .godot-ci
          unzip -q godot.zip -d .godot-ci
          mv .godot-ci/Godot_v4.7.2-stable_linux.x86_64 .godot-ci/godot
          chmod +x .godot-ci/godot
          rm godot.zip
      - name: Cache pinned Android export templates
        id: templates-cache
        uses: actions/cache@0057852bfaa89a56745cba8c7296529d2fc39830
        with:
          path: ~/.local/share/godot/export_templates/4.7.2.stable
          key: godot-4.7.2-stable-android-templates-v1
      - name: Fetch verified Android templates on cache miss
        if: steps.templates-cache.outputs.cache-hit != 'true'
        shell: bash
        run: |
          set -euo pipefail
          curl -fL --retry 5 --retry-all-errors --retry-delay 3 \
            --connect-timeout 15 --max-time 900 \
            -o templates.tpz \
            https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
          echo 'f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011  templates.tpz' | sha256sum -c -
          target="$HOME/.local/share/godot/export_templates/4.7.2.stable"
          mkdir -p "$target"
          unzip -jo templates.tpz 'templates/android_debug.apk' 'templates/android_release.apk' -d "$target"
          printf '4.7.2.stable\n' > "$target/version.txt"
          rm templates.tpz
      - name: Configure Godot Android SDK and ephemeral debug signing
        shell: bash
        run: |
          set -euo pipefail
          test -s "$HOME/.local/share/godot/export_templates/4.7.2.stable/android_debug.apk"
          test -s "$HOME/.local/share/godot/export_templates/4.7.2.stable/android_release.apk"
          mkdir -p "$HOME/.config/godot"
          cat > "$HOME/.config/godot/editor_settings-4.tres" <<EOF
          [gd_resource type="EditorSettings" format=3]

          [resource]
          export/android/android_sdk_path = "$ANDROID_HOME"
          export/android/java_sdk_path = "$JAVA_HOME"
          EOF
          keytool -genkeypair -noprompt -keystore "$RUNNER_TEMP/jumpy-debug.keystore" \
            -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 365 \
            -storepass android -keypass android \
            -dname 'CN=Jumpy Debug,O=Device QA,C=FR'
      - name: Import Godot project and export installable APK
        shell: bash
        env:
          GODOT_ANDROID_KEYSTORE_DEBUG_PATH: ${{ runner.temp }}/jumpy-debug.keystore
          GODOT_ANDROID_KEYSTORE_DEBUG_USER: androiddebugkey
          GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD: android
        run: |
          set -euo pipefail
          mkdir -p build
          .godot-ci/godot --headless --path . --editor --quit 2>&1 | tee android-import.log
          .godot-ci/godot --headless --path . --export-debug 'Android' build/Jumpy-debug.apk 2>&1 | tee android-export.log
          test -s build/Jumpy-debug.apk
          unzip -tq build/Jumpy-debug.apk >/dev/null
          echo "Debug APK is a valid ZIP archive; no Android device execution was performed."
      - name: Verify signed APK package and attach provenance
        shell: bash
        run: |
          set -euo pipefail
          # Verify Android signature and app identity (a valid ZIP alone is insufficient).
          "$ANDROID_HOME/build-tools/36.1.0/apksigner" verify --verbose build/Jumpy-debug.apk
          "$ANDROID_HOME/build-tools/36.1.0/aapt" dump badging build/Jumpy-debug.apk > apk-badging.log
          grep -F "package: name='com.dbrckk.jumpy'" apk-badging.log
          unzip -Z1 build/Jumpy-debug.apk > apk-files.txt
          grep -Eq '^lib/arm64-v8a/[^/]+[.]so$' apk-files.txt
          (cd build && sha256sum Jumpy-debug.apk > Jumpy-debug.apk.sha256)
          git rev-parse HEAD > build/SOURCE_COMMIT.txt
          echo "APK signature, application ID and native architecture verified; physical Android QA still required."
      - name: Upload APK for Android device testing
        uses: actions/upload-artifact@ea165f8d65b6e75b540449e92b4886f43607fa02
        with:
          name: Jumpy-Android-debug-${{ github.sha }}
          path: build/
          if-no-files-found: error
          retention-days: 7
          compression-level: 0
```

## File: .github/workflows/production-os-review-handoff.yml
```yaml
name: Trusted Production-OS PR Handoff

# Runs from the default branch only. Never checks out or executes Studio code.
on:
  repository_dispatch:
    types: [production_os_review_handoff]

permissions:
  contents: read
  pull-requests: write
  actions: write

concurrency:
  group: production-os-review-handoff
  cancel-in-progress: false

jobs:
  create-review:
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    env:
      REVIEW_TOKEN: ${{ github.token }}
    steps:
      - name: Verify published checkpoint and open a review PR
        shell: bash
        run: |
          set -euo pipefail
          python3 - <<'PY'
          import json
          import os
          import re
          import urllib.error
          import urllib.parse
          import urllib.request

          repo = os.environ["GITHUB_REPOSITORY"]
          if repo != "dbrckk/Jumpy":
              raise SystemExit("Review handoff must run in the trusted repository")
          with open(os.environ["GITHUB_EVENT_PATH"], encoding="utf-8") as source:
              event = json.load(source)
          payload = event.get("client_payload")
          if not isinstance(payload, dict) or set(payload) != {"branch", "commit_sha"}:
              raise SystemExit("Invalid Production-OS review handoff payload")
          branch = payload.get("branch")
          sha = payload.get("commit_sha")
          if not isinstance(branch, str) or not re.fullmatch(r"studio/mp-[a-f0-9]{24}", branch):
              raise SystemExit("Handoff branch does not match managed Studio namespace")
          if not isinstance(sha, str) or not re.fullmatch(r"[a-f0-9]{40}", sha):
              raise SystemExit("Handoff commit SHA is invalid")

          token = os.environ["REVIEW_TOKEN"]
          base = "https://api.github.com/repos/" + repo
          headers = {
              "Authorization": "Bearer " + token,
              "Accept": "application/vnd.github+json",
              "X-GitHub-Api-Version": "2022-11-28",
              "User-Agent": "production-os-review-handoff",
          }

          def request(method, path, data=None):
              body = json.dumps(data).encode("utf-8") if data is not None else None
              action = urllib.request.Request(
                  base + path, data=body, method=method, headers={
                      **headers, **({"Content-Type": "application/json"} if body else {}),
                  }
              )
              try:
                  with urllib.request.urlopen(action, timeout=20) as response:
                      raw = response.read(1000000)
                      return json.loads(raw) if raw else {}
              except urllib.error.HTTPError as exc:
                  if exc.code in {401, 403}:
                      raise SystemExit(
                          "Target GitHub Actions must allow pull-request creation "
                          "(Pull requests:write and repository setting)"
                      ) from None
                  raise SystemExit("Review handoff GitHub API returned HTTP " + str(exc.code)) from None

          ref = request("GET", "/git/ref/heads/" + branch)
          verified = (ref.get("object") or {}).get("sha")
          if verified != sha:
              raise SystemExit("Review handoff rejected a stale or unverified branch tip")
          delta = request("GET", "/compare/main..." + branch)
          files = delta.get("files")
          if (delta.get("status") not in {"ahead", "diverged"}
                  or not isinstance(files, list) or not 0 < len(files) < 300):
              raise SystemExit("Review handoff requires a bounded nonempty compare")
          if any(str(f.get("filename") or "").startswith(".github/") or str(f.get("filename") or "") == ".gitmodules" for f in files):
              raise SystemExit("Review handoff refuses GitHub automation and submodule configuration changes")

          owner = repo.split("/", 1)[0]
          query = urllib.parse.urlencode({
              "state": "open", "head": owner + ":" + branch, "base": "main",
              "per_page": "20",
          })
          existing = request("GET", "/pulls?" + query)
          if not isinstance(existing, list):
              raise SystemExit("Pull request list returned an invalid response")
          for item in existing:
              if ((item.get("head") or {}).get("ref") == branch
                      and (item.get("base") or {}).get("ref") == "main"):
                  print("Reused existing review: " + str(item.get("html_url") or ""))
                  break
          else:
              created = request("POST", "/pulls", {
                  "title": "Review Production-OS verified Jumpy checkpoint: " + branch,
                  "head": branch,
                  "base": "main",
                  "draft": True,
                  "body": (
                      "Production-OS published this checkpoint to a review branch. "
                      "This PR was opened by the trusted target-repository handoff "
                      "after independently validating the exact branch tip and diff. "
                      "Review all changed files and run required CI before any merge. "
                      "No changes are merged automatically.\n\n"
                      "Checkpoint: `" + sha + "`"
                  ),
              })
              if not isinstance(created, dict) or not created.get("number"):
                  raise SystemExit("Review handoff did not receive a real PR number")
              print("Opened draft review: " + str(created.get("html_url") or ""))
          # GitHub requires manual approval for pull_request checks created with
          # GITHUB_TOKEN. An explicit workflow_dispatch instead schedules an
          # isolated, read-only Godot check against the verified branch tip.
          # This default-branch handoff never checks out Studio code.
          request("POST", "/actions/workflows/validate.yml/dispatches", {
              "ref": branch,
              "inputs": {"expected_sha": sha},
          })
          print("Dispatched Godot validation for exact checkpoint: " + sha)
          PY
```

## File: .github/workflows/semantic-refresh.yml
```yaml
name: Precise semantic refresh

on:
  workflow_dispatch:
  schedule:
    - cron: "23 3 * * 1"

permissions:
  contents: write

concurrency:
  group: semantic-refresh-${{ github.repository }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  semantic:
    uses: dbrckk/repo-brain/.github/workflows/reusable-semantic.yml@main
    with:
      commit_changes: true
```

## File: .github/workflows/validate.yml
```yaml
name: Validate Godot Project

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:
    inputs:
      expected_sha:
        description: "Exact reviewed checkpoint SHA to validate"
        required: true
        type: string

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
      - name: Verify dispatched checkpoint identity
        if: ${{ github.event_name == 'workflow_dispatch' }}
        env:
          EXPECTED_SHA: ${{ inputs.expected_sha }}
        run: |
          set -euo pipefail
          [[ "$EXPECTED_SHA" =~ ^[0-9a-f]{40}$ ]] || { echo "Invalid checkpoint SHA"; exit 1; }
          test "$(git rev-parse HEAD)" = "$EXPECTED_SHA"
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
      - name: Smoke-test touch routing and HUD input passthrough
        run: |
          set -euo pipefail
          .godot-ci/godot --headless --path . --script res://tools/smoke_mobile_input.gd 2>&1 | tee input-smoke.log
          if grep -E "SCRIPT ERROR|Parse Error|Cannot parse|Failed loading resource" input-smoke.log; then
            echo "Godot reported a blocking runtime error during input smoke"
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
const LANDING_CUE_DURATION: float = 0.72
const COYOTE_TIME: float = 0.09
const JUMP_BUFFER_TIME: float = 0.10
const QA_SAMPLE_INTERVAL: float = 1.0

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
	speed = minf(970.0, 470.0 + elapsed * 7.5 + float(score) * 0.42)
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
const SAVE_TMP_PATH: String = "user://jumpy_save.json.tmp"
const BACKUP_PREFIX: String = "JUMPY1"
const MAX_BACKUP_LENGTH: int = 8192

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

func save() -> bool:
	# Write to a sibling file first; never truncate the previous valid save.
	var file: FileAccess = FileAccess.open(SAVE_TMP_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Jumpy: unable to open temporary save. Error %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK:
		push_warning("Jumpy: temporary save write failed with error %s" % error)
		return false
	error = DirAccess.rename_absolute(SAVE_TMP_PATH, SAVE_PATH)
	if error != OK:
		push_warning("Jumpy: failed to commit save, error %s" % error)
		return false
	return true


func export_backup_code() -> String:
	# Portable text backup; no device key, Google account or storage permission.
	var payload: String = JSON.stringify(_validated_save(data))
	return "%s:%s:%s" % [BACKUP_PREFIX, payload.sha256_text(), Marshalls.utf8_to_base64(payload)]


func _decode_backup_code(code: String) -> Dictionary:
	var cleaned: String = code.strip_edges()
	if cleaned.length() < 80 or cleaned.length() > MAX_BACKUP_LENGTH:
		return {}
	var fields: PackedStringArray = cleaned.split(":", false)
	if fields.size() != 3 or fields[0] != BACKUP_PREFIX or fields[1].length() != 64:
		return {}
	var payload: String = Marshalls.base64_to_utf8(fields[2])
	if payload.is_empty() or payload.length() > 4096 or payload.sha256_text() != fields[1]:
		return {}
	var parser: JSON = JSON.new()
	if parser.parse(payload) != OK or not parser.data is Dictionary:
		return {}
	var parsed: Dictionary = parser.data
	if _save_integer(parsed.get("version"), -1, SAVE_VERSION) != SAVE_VERSION:
		return {}
	for key: String in DEFAULT_DATA.keys():
		if not parsed.has(key):
			return {}
	return _validated_save(parsed)


func is_valid_backup_code(code: String) -> bool:
	return not _decode_backup_code(code).is_empty()


func restore_backup_code(code: String) -> bool:
	var restored: Dictionary = _decode_backup_code(code)
	if restored.is_empty():
		return false
	var previous: Dictionary = data.duplicate(true)
	data = restored
	if not save():
		data = previous
		return false
	_refresh_daily()
	return true

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

## File: tools/smoke_mobile_input.gd
```
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

	game.queue_free()
	await process_frame
	print("PASS: input, backups, FLOW, landings, HUD, jump buffer, settled death FX and pooled SFX")
	quit(0)


func _fail(message: String) -> void:
	push_error("Mobile input smoke failed: " + message)
	quit(1)
```

## File: .repo-standards.yml
```yaml
source: dbrckk/repo-standards
ref: main
version: 20
adopted: true
workflow_mode: unified-single-commit
repo_brain: dbrckk/repo-brain@main
repo_brain_fallback: portable-full-rebuild
hotset_fallback: recent-project-state
graph_routing: compact-sharded-reverse-deps
graph_resolver: java-kotlin-tail-v2
graph_enrichment: unique-type-symbol-references-v1
context_budget: confidence-dynamic-3-6-12
routing_learning: deterministic-term-feedback-v1
auto_routing_learning: source-diff-success-v1
validation_memory: passed-failed-test-history-v1
regression_gate: repo-brain-core-tests-v1
benchmark: routing-benchmark-v1
stability_profile: stable-v1
benchmark_guard: avg-files-le-6-cache-required-v1
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
  brain_summary: .ai/brain/summary.md
  brain_incremental_state: .ai/brain/incremental-state.json
  brain_impact: .ai/brain/impact.json
  brain_selected_tests: .ai/brain/selected-tests.json
  brain_references: .ai/brain/references.json
  brain_symbol_dependencies: .ai/brain/symbol-dependencies.json
  brain_capabilities: .ai/brain/capabilities.json
  brain_ast_routing: .ai/brain/ast-routing.json
  brain_ast_symbols: .ai/brain/ast-symbols/
  brain_file_outlines: .ai/brain/file-outlines/
  brain_lookup: .ai/brain/lookup.json
  brain_symbols: .ai/brain/symbols.json
  brain_graph: .ai/brain/code-graph.json
  brain_graph_index: .ai/brain/graph-index.json
  brain_graph_enrichment: .ai/brain/graph-enrichment.json
  brain_graph_manifest: .ai/brain/graph-manifest.json
  brain_graph_shards: .ai/brain/graph-shards/
  brain_reverse_deps: .ai/brain/reverse-deps.json
  brain_architecture_mermaid: .ai/brain/architecture.mmd
  brain_semantic_plan: .ai/brain/semantic-plan.json
  brain_semantic_index: .ai/brain/semantic-index.json
  brain_search_manifest: .ai/brain/search-manifest.json
  brain_search_shards: .ai/brain/search-shards/
  brain_query_cache: .ai/brain/query-cache.json
  brain_routing_learning: .ai/brain/routing-learning.json
  brain_auto_learning: .ai/brain/auto-learning.json
  brain_validation_memory: .ai/brain/validation-memory.json
  brain_benchmark: .ai/brain/benchmark.json
  brain_benchmark_health: .ai/brain/benchmark-health.json
  brain_hotset: .ai/brain/hotset.json
  brain_context_manifest: .ai/brain/context-manifest.json
  brain_context_packets: .ai/brain/context/
  brain_hash_cache: .ai/brain/hash-cache.json
  session_state: .ai/session-state.json
  repo_map: .ai/repo-map.md
  segmented_maps: .ai/maps/
workflow:
  file: .github/workflows/ai-repo-map.yml
  reusable_unified: .github/workflows/reusable-unified.yml
  semantic_refresh: .github/workflows/semantic-refresh.yml
```

## File: AGENTS.md
```markdown
# Repository agent instructions

## Shared development policy — 88 validated rules (2026-10-09)

The project adopts the [88-rule standard](https://github.com/dbrckk/repo-standards/blob/db2f86657ada74a0561e07189f9942d6b66ebb4a/standards/88-rules.md), the [operational agent skill](https://github.com/dbrckk/repo-standards/blob/db2f86657ada74a0561e07189f9942d6b66ebb4a/skills/repo-excellence-88/SKILL.md), and the [educational wiki](https://github.com/dbrckk/repo-standards/blob/db2f86657ada74a0561e07189f9942d6b66ebb4a/docs/WIKI-88.md). Read the relevant parts before substantial work and apply conditional rules only where appropriate.

**Owner preference: do not create new unit tests.** Existing tests may be run for diagnostics; prioritize real functional and integration verification, lint, build, and reproducible checks. Never claim an unexecuted check passed.

Preserve repository-specific constraints and authorized scope. The pinned policy commit above governs the 88 rules; `.repo-standards.yml` continues to configure existing repository intelligence and reusable workflows independently. Do not change workflow refs merely to adopt these rules.


This repository adopts shared standards from `dbrckk/repo-standards` at the release recorded in `.repo-standards.yml`.

Before substantial work:
1. Read the central `AGENTS.md` and relevant standards at the configured ref.
2. Read `.ai/session-state.json` when present.
3. Read `.ai/project-state.md`.
4. Read `.ai/brain/hotset.json`.
5. Read `.ai/brain/context-manifest.json` and only the relevant `.ai/brain/context/<area>.json` packet.
6. Read `.ai/brain/graph-index.json` and the relevant `.ai/brain/graph-shards/<area>.json` when dependency routing matters.
7. Use `.ai/brain/reverse-deps.json` for upstream/downstream file impact.
8. Read `.ai/brain/impact.json` and `.ai/brain/selected-tests.json`.
9. Read `.ai/brain/references.json` and `.ai/brain/symbol-dependencies.json` only when symbol routing requires them.
10. Read `.ai/change-impact.md` and `.ai/architecture.json` when broader structure is needed.
11. Read `.ai/brain/summary.md`, `.ai/brain/incremental-state.json`, and `.ai/brain/capabilities.json` when index freshness/capabilities matter.
12. If ast-grep enrichment is available, route named symbols through `.ai/brain/ast-routing.json` and one `.ai/brain/ast-symbols/<initial>.json` shard.
13. Fall back to `.ai/brain/lookup.json` when AST routing is unavailable or insufficient.
14. Use `.ai/brain/code-graph.json` and `.ai/brain/imports.json` for cross-module context.
15. Read `.ai/dependency-map.json` when dependency context matters.
16. Read `.ai/commands.json`, `.ai/ci-status.md`, and security signals when relevant.
17. Read `.ai/repo-health.md`.
18. Use `.ai/index.md` and segmented maps only if bounded context is insufficient.
19. Read `.ai/repo-map.md` only as a final broad-context fallback.
20. Fetch only task-relevant source files or line ranges.

Repository-specific rules:
- Preserve existing architecture and public interfaces unless the task requires a change.
- Prefer the smallest coherent change.
- Prefer targeted functional or integration checks; existing selected tests may be run as diagnostics, but do not create new unit tests. Expand validation when impact is ambiguous.
- Treat hotset/context packets and graph shards as routing hints, not authoritative source.
- Verify reference/dependency/impact/AST hits against authoritative source before editing.
- Treat security signals and static graph edges as heuristics, not proof.
- Never reproduce suspected secret values.
- Update manual project-state sections when status, blockers, or next priority materially changes.
- Maintain `.ai/session-state.json` for substantial multi-turn work so a later "Continue" can resume without reconstructing the repository.
```

## File: README.md
```markdown
# Jumpy

Jumpy is a portrait-first one-touch hybrid-casual arcade game designed around instant comprehension, short replayable runs, skill expression, social competition, and long-term collection.

## Core loop

**Tap. Jump. Land perfectly. Keep the FLOW alive.**

From the title screen, tap **DAILY** or **ENDLESS** to start a run immediately, or tap blank space to start the default mode. The active mode stays visible in the FLOW HUD. The world scrolls continuously. Tap from a platform to jump; tap once in the air to spend a corrective pulse. Perfect landings build FLOW, which raises score gain and feedback intensity. Miss the world and restart instantly.

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

## Android device build (no PC required)

A debug APK is built automatically by [GitHub Actions](https://github.com/dbrckk/Jumpy/actions/workflows/android-debug-apk.yml) whenever game code, scenes, assets or Android export configuration changes. Open the latest **successful main-branch** run and download the **Jumpy-Android-debug-…** artifact (ZIP containing the APK, SHA-256 checksum and source commit). Manual builds are also available through **Run workflow**.

See [Android device QA](docs/ANDROID_DEVICE_QA.md) for phone installation, signing caveats and the on-device acceptance checklist. **Before replacing a debug APK**, open **SETTINGS → COPY BACKUP** and paste the code into an external note. After reinstalling, copy the code from the note and tap **SETTINGS → RESTORE SAVE** twice to recover progress. Debug APK generation is not proof of production-release quality.

## External production setup

The game runs without external services. Optional production integrations are documented in `SETUP_REQUIRED.txt` so missing credentials never block development.
```
