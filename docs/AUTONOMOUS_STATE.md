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
- Time: 2026-09-07 05:44 UTC
- Base: `bb8b4cf5b7e6`
- Atomic phase: `ACCESSIBILITY_PROFILE_SETTER`
- Executor: `completed`

### Strategic snapshot
is the lowest score and is explicitly called out in the immediate priorities." However, we must verify with current evidence. Looking at the source code: - In `scripts/profile.gd`, we see that the data dictionary includes: "sound": true, "haptics": true, "reduced_motion": false, "high_contrast": false But there is no UI to change these settings. The `settings` menu is not present in the main menu (as noted in the AUTONOMOUS_STATE.md context: "No SETTINGS button."). In `scripts/main.gd`, the `build_ui()` function creates the UI but does not include a settings button. The existing buttons are: title, subtitle, hint, mission, daily, normal, skin, gameover, retry, share. Therefore, the accessibility bottleneck is real: there is no way for the user to adjust sound, haptics, reduced motion, or high contrast. Moreover, the immediate priority #3 is "Expand accessibility/settings and subjective polish surfaces." Now, let's check if there are any other domains that might be more critical. The social/viral loop has a score of 5.2, which is low, but note that the immediate priorities do not list social as the top immediate priority (it's #4). However, the AUTONOMOUS_STATE.md strategic snapshot from the latest cycle points to accessibility as the bottleneck. But we must also consider the PRODUCTION_ROADMAP.md and GAME_DESIGN.md for context. In PRODUCTION_ROADMAP.md, Gate D (Extreme production polish) includes: - Reduced motion, haptic/audio toggles and high-contrast option. This is exactly what is missing. Also, in SETUP_REQUIRED.txt, we see that external dependencies (like analytics, ads, leaderboards) are optional and require setup. However, the game is designed to be playable without them. Now, let's look at the evidence for the bottleneck: - Accessibility score: 4.5 (lowest in the scorecard) - The immediate priorities list accessibility as #3. - The latest autonomous cycle completed ACCESSIBILITY_PROFILE_FOUNDATION, which added persistent reduced_motion and high_contrast defaults, but note that the cycle did not add the UI for toggles. The execution evidence of the latest cycle: "Added persistent reduced_motion and high_contrast defaults; load_data already merges only kn

### Execution evidence
Added one validated preference setter so future UI can persist all four accessibility preferences without duplicating save logic.

### Next-cycle rule
Re-read current source and resolve the next atomic phase from evidence. Do not repeat a failed phase unchanged; reduce scope or change route.
<!-- AUTO_CYCLE_END -->
