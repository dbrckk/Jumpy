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
- Time: 2026-09-07 06:22 UTC
- Base: `76041e19e07b`
- Atomic phase: `ACCESSIBILITY_SETTINGS_UI`
- Executor: `timeout_140s`

### Strategic snapshot
ytics and experimentation not connected. | | Android / store readiness | 5.8 | Export preset exists; signing, device build, compliance and listing work remain. | ## Blocking risks - Subjective game feel cannot be certified from headless CI alone. - Real retention/viral performance cannot be claimed before analytics and player evidence. - External store/social integrations require user-owned account configuration. ## Planning rule Every cycle must inspect this file, `AUTONOMOUS_TEAM.md`, `PRODUCTION_ROADMAP.md`, current source and recent changes. It must update priorities when new evidence changes the optimal path. A completed task must cause a fresh systemic re-evaluation rather than a blind move to an old checklist item. ## Latest autonomous cycle (from AUTO_CYCLE_START to AUTO_CYCLE_END): - Time: 2026-09-07 06:07 UTC - Base: `c4f53f87690c` - Atomic phase: `ACCESSIBILITY_SETTINGS_UI` - Executor: `timeout_140s` ### Strategic snapshot (from the cycle): - Real retention/viral performance cannot be claimed before analytics and player evidence. - External store/social integrations require user-owned account configuration. - Planning rule: ... (as above) - Latest autonomous cycle indicates that the current phase was ACCESSIBILITY_VISUAL_BEHAVIOR and the strategic snapshot highlighted that accessibility is the lowest (4.5) and the next lowest is social/viral at 5.2. ### Execution evidence: - A change in main.gd to reduce burst count and power when reduced_motion is true. ### Acceptance criteria for resolving the accessibility bottleneck (as per the latest cycle): - A settings menu is accessible from the main menu (or pause menu) that allows toggling: Sound, Haptics, Reduced motion, High contrast. - The toggles persist across sessions (via the existing Profile system). - The game respects these settings in real-time. ### Next 3-5 priorities (from the latest cycle): 1. Implement a settings button in the main menu (or pause menu) that opens a settings panel. 2. In the settings panel, add toggles for the four accessibility preferences (sound, haptics, reduced motion, high contrast) that call Profile.set_preference and save. 3. Update the game to respect these settings (wi

### Execution evidence
[0m > build · nvidia_nim/nvidia/nemotron-3-super-120b-a12b [0m [0m→ [0mRead scripts/main.gd

### Next-cycle rule
Re-read current source and resolve the next atomic phase from evidence. Do not repeat a failed phase unchanged; reduce scope or change route.
<!-- AUTO_CYCLE_END -->
