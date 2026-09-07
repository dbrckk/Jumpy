# Jumpy — Autonomous Living State

This file is maintained by the autonomous evolution system. It is the current working memory for strategic direction, quality gaps, blockers and immediate action.

## Current stage
Vertical slice evolving toward production-quality hybrid-casual mobile game.

## Current systemic assessment
- Core loop exists and is playable.
- Deterministic daily play, persistence, missions, streaks, skins, sharing fallback, haptics and procedural audio exist.
- Godot 4.7.2 headless validation is active.
- Autonomous 30-minute evolution pipeline is active and can push validated changes.
- External production integrations remain intentionally decoupled behind `scripts/integrations.gd`.

## Immediate priorities
1. Raise moment-to-moment game feel and readable skill expression.
2. Strengthen return motivation and post-run feedback without bloating the one-touch core.
3. Expand accessibility/settings and subjective polish surfaces.
4. Add stronger local social/competitive loops before relying on external services.
5. Improve testability and objective quality evidence.

## Current known external dependencies
See `SETUP_REQUIRED.txt`. External dependencies must never silently block independent local work.

## Quality scorecard
These scores are provisional engineering estimates, not final player evidence.

| Domain | Score /10 | Evidence / gap |
|---|---:|---|
| Core feel and controls | 7.2 | Functional one-touch loop; device tuning and broader feel iteration still required. |
| Readability and UX | 7.0 | Cohesive basic HUD; onboarding/settings/accessibility need deeper pass. |
| Difficulty / mastery | 6.8 | Procedural scaling exists; mastery curve not yet validated with players. |
| Replayability / retention | 6.9 | Daily, missions, streak and skins exist; rotation and long-term depth incomplete. |
| Progression / economy | 6.4 | Coins/skins are present; economy depth and reward pacing need design validation. |
| Social / challenge loop | 5.2 | Share fallback only; ghosts/deep-link/friend challenge not complete. |
| Visual identity / VFX | 6.8 | Procedural neon identity and feedback exist; final art/motion pass incomplete. |
| Audio / haptics | 6.2 | Procedural feedback exists; final mix/music hierarchy incomplete. |
| Accessibility | 4.5 | Dedicated reduced-motion/contrast/toggle architecture incomplete. |
| Performance / stability | 7.4 | Headless parse validation active; real device matrix/frame pacing not yet proven. |
| Code / architecture | 7.5 | Small maintainable project with integration boundaries; test coverage still limited. |
| QA / testability | 6.3 | CI catches parse/resource failures; gameplay invariants need automated tests. |
| Analytics readiness | 6.0 | Event boundaries exist; production analytics and experimentation not connected. |
| Android / store readiness | 5.8 | Export preset exists; signing, device build, compliance and listing work remain. |

## Blocking risks
- Subjective game feel cannot be certified from headless CI alone.
- Real retention/viral performance cannot be claimed before analytics and player evidence.
- External store/social integrations require user-owned account configuration.

## Planning rule
Every cycle must inspect this file, `AUTONOMOUS_TEAM.md`, `PRODUCTION_ROADMAP.md`, current source and recent changes. It must update priorities when new evidence changes the optimal path. A completed task must cause a fresh systemic re-evaluation rather than a blind move to an old checklist item.

<!-- AUTO_CYCLE_START -->
## Latest autonomous strategic cycle
**Time:** 2026-09-07 05:32 UTC  
**Base commit:** `d7b39847abdd`  
**Execution focus:** `OPEN_ENDED_STRATEGIC_TASK`  
**Lane:** `open-ended`  
**Executor status:** `timeout_180s`

### Multidisciplinary review and immediate plan
### 1. Weakest Domains with Concrete Repository Evidence
- **Accessibility (4.5/10)**  
  Evidence from `AUTONOMOUS_STATE.md`: "Dedicated reduced-motion/contrast/toggle architecture incomplete."  
  Code evidence:  
  - `scripts/main.gd`: No settings UI exists (`build_ui()` lacks a SETTINGS button).  
  - `scripts/profile.gd`: `sound` and `haptics` toggles exist in `data` but have no UI exposure.  
  - No toggles for reduced motion (affects `camera_kick`, `flash`, particle intensity) or high contrast (UI text stroke, perfect zone/bg colors).  
  - `scripts/integrations.gd`: `haptic()` checks `Profile.data.haptics` but no UI to change it.  
  - `_draw()` in `main.gd` uses hardcoded `camera_kick`/`flash` with no motion-reduction logic.  

### 2. Highest-Value Safe Implementation Feasible Now
**Implement a persistent accessibility settings menu with toggles for Sound, Haptics, Reduced Motion, and High Contrast, integrated into the main menu.**  
- **Why highest-value**: Directly raises the lowest-scoring domain (Accessibility) with zero external dependencies. Uses existing `Profile` persistence, Godot UI nodes, and synthesized audio/haptics. Enables safer feel tuning by accommodating sensitivities (e.g., motion sickness), improving retention data quality.  
- **Feasibility**: No new external accounts/APIs/paid services required. All changes are local to the repository and validated via headless CI.  

### 3. Measurable Acceptance Criteria
1. Settings menu accessible from main menu via new "SETTINGS" button (positioned below SKIN button) with persistent toggles for:  
   - **Sound**: Mutes `Integrations.play_tone` and event audio when disabled.  
   - **Haptics**: Skips `Input.vibrate_handheld` calls when disabled.  
   - **Reduced Motion**: Disables camera kick (`camera_kick = 0`), flash (`flash = 0`), reduces particle burst intensity to ≤50% power, and disables non-essential animations (e.g., background star twinkle).  
   - **High Contrast**: Increases UI text stroke to 8px, sets perfect zone color to `#00ffff`, and background to `#000000`.  
2. Toggling any setting immediately affects gameplay/UI without restart (verified via manual inspection).  
3. Settings persist across sessions via `Profile.data` (saved to `user://jumpy_save.json`); defaults: `sound=true`, `haptics=true`, `reduced_motion=false`, `high_contrast=false`.  
4. Headless CI passes: No regressions in core gameplay (perfect landing detection, scoring, mission progression) with all toggles enabled/disabled.  
5. Android device verification: Toggles function as described (no crashes, settings persist after force-close/reopen).  

### 4. Next 3-7 Actions in Priority Order (Post-Implementation)
1. **Tune jump arc/pulse for device-validated feel (Gate A)**  
   Adjust `GRAVITY`, `JUMP_V`, `PULSE_V` constants based on feel principles; add automated invariant tests for jump arc consistency and landing timing.  
2. **Enhance post-run feedback with mastery metrics (Gate B)**  
   Expand game-over screen to show perfects, clutchs, max FLOW, and coin efficiency; persist via `Profile` for long-term trends.  
3. **Implement rotating daily missions (Gate B)**  
   Replace static mission goals with daily-rotating objectives (e.g., "Land 10 perfects," "Score 500 coins"); store in `Profile.daily_missions`.  
4. **Add local daily ghost system (Gate C)**  
   Record player's best run (input replay) for the current daily seed; render as translucent ghost during subsequent runs; persist via `Profile`.  
5. **Strengthen onboarding clarity (Gate A/UX)**  
   Add visual jump/pulse hints during first 3 seconds of gameplay (e.g., animated tap indicators) without text dependence.  
6. **Implement deterministic QA test for FLOW logic (QA)**  
   Create automated test verifying FLOW multiplier scales correctly with consecutive perfects/clutches and resets on misses.  
7. **Refine coin audio hierarchy (Audio)**  
   Layer coin collection SFX with FLOW intensity (higher pitch/volume at high FLOW) using existing `Integrations.play_tone`.  

### 5. Blockers + Alternate Routes
- **Blocker for Action 1 (Tune jump arc/pulse)**:  
  Device validation requires real-device testing (blocked without external setup per `SETUP_REQUIRED.txt`).  
  **Alternate route**: Tune constants using established feel principles (e

### Executor evidence
Safety gate: ACCEPTABLE: scripts/main.gd,scripts/profile.gd

 	ui.retry = make_button(root, "RETRY", Vector2(280, 940), Vector2(520, 110), restart_pressed)  	ui.share = make_button(root, "SHARE", Vector2(330, 1080), Vector2(420, 86), func() -> void: Integrations.share_score(score, daily_mode)) +	build_settings_menu()    func make_label(parent: Control, text: String, size: int, pos: Vector2, dim: Vector2, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:  	var label: Label = Label.new()  	label.text = text  [0m [0m✗ [0mEdit .jumpy-studio-cycle/scripts/main.gd failed [91m[1mError: [0mNo changes to apply: oldString and newString are identical. [0m [0m← [0mEdit .jumpy-studio-cycle/scripts/main.gd Index: /workspaces/ai-dev-server/.jumpy-studio-cycle/scripts/main.gd =================================================================== --- /workspaces/ai-dev-server/.jumpy-studio-cycle/scripts/main.gd +++ /workspaces/ai-dev-server/.jumpy-studio-cycle/scripts/main.gd @@ -35,8 +35,10 @@  var flash: float = 0.0  var last_platform_id: int = -1  var next_platform_id: int = 1  var ui: Dictionary = {} +var settings_menu: Control = null +var settings_visible: bool = false    func _ready() -> void:  	fx_rng.randomize()  	build_ui()  [0m

### Remaining deterministic shortcuts
DAILY_BEST_MENU: Surface the daily best score in daily mode.
RUN_STATS_GAMEOVER: Improve post-run feedback with skill/run stats.

### Operating instruction
Re-audit the whole product next cycle. A timeout, invalid diff, missing implementation or failed validation is evidence: diagnose the root cause, change the route, and keep advancing independent work. Never repeatedly spend cycles on the same failed method without adaptation.

### Validation outcome
Godot 4.7.2 rejected the implementation candidate. Source changes were discarded; this diagnostic state is preserved so the next cycle must choose a different implementation route.
<!-- AUTO_CYCLE_END -->
