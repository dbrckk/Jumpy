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
## Latest autonomous cycle
- Time: 2026-09-07 05:47 UTC
- Base: `a38d5ff9751a`
- Atomic phase: `ACCESSIBILITY_VISUAL_BEHAVIOR`
- Executor: `timeout_120s`

### Strategic snapshot
as the lowest (4.5). The next lowest is social/viral at 5.2, but note that the immediate priorities list social as #4, after accessibility. Also, the PRODUCTION_ROADMAP.md states that every cycle must inspect the files and update priorities when new evidence changes the optimal path. Given the evidence, the highest-impact current bottleneck is accessibility. Root causes: - No settings UI in the main menu to access accessibility toggles (sound, haptics, reduced motion, high contrast). - The existing code has the preference system (in Profile) but no way for the user to change them via the UI. Acceptance criteria for resolving the bottleneck: - A settings menu is accessible from the main menu (or pause menu) that allows toggling: * Sound (on/off) * Haptics (on/off) * Reduced motion (on/off) * High contrast (on/off) - The toggles persist across sessions (via the existing Profile system). - The game respects these settings in real-time: * Sound: disables all audio (including procedural tones) when off. * Haptics: disables vibration when off. * Reduced motion: reduces or disables non-essential motion (e.g., screen shake, particle effects, camera kick) when on. * High contrast: adjusts colors to improve readability (e.g., increasing contrast between background and foreground elements) when on. Next 3-5 priorities (based on the immediate priorities and the bottleneck): 1. Implement a settings button in the main menu (or pause menu) that opens a settings panel. 2. In the settings panel, add toggles for the four accessibility preferences (sound, haptics, reduced motion, high contrast) that call Profile.set_preference and save. 3. Update the game to respect these settings: - For sound: in Integrations.gd, check Profile.data.sound before playing tones. - For haptics: already checked in Integrations.gd (haptic function checks Profile.data.haptics), but we should also check in the jump/pulse functions? Actually, the haptic function already checks, so we are good. - For reduced motion: reduce or disable camera kick, flash, particle effects, and any other non-essential motion when reduced_motion is true. - For high contrast: adjust colors (e.g., make the player more visible, a

### Execution evidence
--- /workspaces/ai-dev-server/.jumpy-studio-cycle/scripts/main.gd +++ /workspaces/ai-dev-server/.jumpy-studio-cycle/scripts/main.gd @@ -180,9 +180,14 @@  func jump() -> void:  	player_vy = JUMP_V  	on_ground = false  	pulse_available = true -	burst(Vector2(PLAYER_X, player_y + PLAYER_R), skin_color(), 8, 230.0) +	var burst_count = 8 +	var burst_power = 230.0 +	if Profile.data.reduced_motion: +		burst_count = int(burst_count * 0.5) +		burst_power *= 0.5 +	burst(Vector2(PLAYER_X, player_y + PLAYER_R), skin_color(), burst_count, burst_power)  	Integrations.haptic(14)    func pulse() -> void:  	pulse_available = false  [0m

### Next-cycle rule
Re-read current source and resolve the next atomic phase from evidence. Do not repeat a failed phase unchanged; reduce scope or change route.
<!-- AUTO_CYCLE_END -->
