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
**Time:** 2026-09-06 19:22 UTC  
**Execution focus:** `STREAK_MENU`

### Multidisciplinary review
### Systemic Audit & Immediate Action Plan

**1. Weakest Quality Domains & Biggest Bottleneck**  
- **Weakest domain**: Accessibility (4.5/10) - dedicated reduced-motion/contrast/toggle architecture is incomplete, blocking inclusive reach and violating the quality bar requirement (≥9.3 for critical domains).  
- **Biggest bottleneck**: Subjective game feel validation (currently 7.2/10) cannot be certified from headless CI alone, creating a feedback loop where feel iterations lack player evidence. This stalls progression in core mastery, retention, and polish domains as changes risk degrading the one-touch core without measurable improvement.  
- **Root cause**: Accessibility gaps (e.g., no motion/haptic/exposure controls) force players with sensitivities to disengage, reducing retention data needed to validate feel/tuning changes. Second-order effect: low accessibility scores depress perceived quality, discouraging external validation efforts critical for feel iteration.  

**2. Highest-Value SAFE Immediate Implementation**  
**Action**: Implement a persistent accessibility settings menu with toggles for Sound, Haptics, Reduced Motion, and High Contrast, integrated into the main menu.  
- **Why highest-value**:  
  - Directly raises the lowest-scoring domain (Accessibility) with minimal risk to core loop (no gameplay logic changes).  
  - Enables future feel/tuning validation by allowing players to customize experience (e.g., reducing motion sickness triggers), increasing retention data quality.  
  - Zero external dependencies: uses existing `Profile` persistence, Godot UI nodes, and synthesized audio/haptics.  
  - Aligns with immediate priority #3 (Expand accessibility/settings) and Gate D polish goals, accelerating the roadmap by addressing a blocker early.  
- **Why safe**:  
  - Isolated to UI/settings systems; core gameplay (`update_player`, `jump`, etc.) remains untouched.  
  - All changes are reversible and validated via existing headless CI (no new test infrastructure needed).  
  - No new assets, APIs, or account actions required.  

**Acceptance Criteria**:  
1. Settings menu accessible from main menu (via new "SETTINGS" button) with persistent toggles for:  
   - Sound (mutes `Integrations.play_tone` and event audio)  
   - Haptics (skips `Input.vibrate_handheld` calls)  
   - Reduced Motion (disables camera kick, flash, particle burst intensity >50%, and non-essential animations)  
   - High Contrast (increases UI text stroke, brightens perfect zones to `#00ffff`, darkens background to `#000000`)  
2. Toggling any setting immediately affects gameplay/UI without restart.  
3. Settings persist across sessions via `Profile.data` (saved to `user://jumpy_save.json`).  
4. Headless CI validates no regressions in core gameplay (e.g., perfect landing detection, scoring) with settings toggled.  
5. Manual verification on Android device confirms toggles function as described (no crashes, settings persist).  

**3. Next 3–7 Actions (Priority Order)**  
*After implementing accessibility settings, re-prioritize based on updated systemic state:*  
1. **Tune jump arc/pulse for device-validated feel** (Gate A): Adjust `GRAVITY`, `JUMP_V`, `PULSE_V` based on common Android device latency profiles; add visual landing zone predictor (optional toggle) to improve skill expression causality. *Impact: Directly addresses core feel bottleneck (7.2→8.5+)*  
2. **Enhance post-run feedback with mastery metrics** (Gate B): Replace static game-over screen with dynamic summary showing FLOW max, perfect/clutch ratios, coin efficiency, and streak progress; add "TRY AGAIN" haptic pulse on retry. *Impact: Strengthens return motivation (priority #2) without bloating core*  
3. **Implement rotating daily missions** (Gate B): Replace lifetime counters with 3 refreshed daily missions (e.g., "Land 5 perfects", "Collect 10 coins", "Reach 500 score"); tie to coin rewards and streak bonuses. *Impact: Fixes replayability/retention gap (6.9→8.0+) and progression economy (6.4→7.5+)*  
4. **Add local daily ghost system** (Gate C): Record player's best daily run as input sequence; allow sharing via

### Remaining high-confidence immediate actions
STREAK_MENU: Surface current streak on the home screen.
DAILY_BEST_MENU: Surface the daily best score in daily mode.
RUN_STATS_GAMEOVER: Improve post-run feedback with skill/run stats.

### Operating instruction
Re-audit the whole product next cycle. Do not mechanically repeat this plan if source changes or new evidence make another action higher-value.
<!-- AUTO_CYCLE_END -->
