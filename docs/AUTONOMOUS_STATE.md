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
- Time: 2026-09-07 05:42 UTC
- Base: `c7af2b077345`
- Atomic phase: `ACCESSIBILITY_PROFILE_FOUNDATION`
- Executor: `completed`

### Strategic snapshot
nd high-contrast option. Therefore, the highest-impact current bottleneck is likely accessibility, because it is the lowest score and is explicitly called out in the immediate priorities. Let's check the evidence for accessibility in the code: In scripts/main.gd, we see: - There is no settings button in the main menu (as noted in the AUTONOMOUS_STATE.md context: "No SETTINGS button."). - The profile.gd has `sound` and `haptics` toggles in the data dictionary, but there is no UI to change them. - There is no reduced motion or high contrast toggle. In the integrations.gd, we see that haptic and sound are used conditionally on `Profile.data.haptics` and `Profile.data.sound`, but there is no way for the user to toggle them. Therefore, the root cause for the low accessibility score is the lack of a settings menu to adjust accessibility options (sound, haptics, reduced motion, high contrast) and the lack of implementation of reduced motion and high contrast features. Acceptance criteria for accessibility (based on Gate D and the immediate priorities): - A settings menu accessible from the main menu. - Toggles for Sound, Haptics, Reduced Motion, and High Contrast. - The toggles should persist and affect the game immediately. - Reduced motion should reduce or eliminate non-essential motion (e.g., screen shake, particle effects, background movement?). - High contrast should adjust colors for better readability. Now, let's consider the next 3-5 priorities. We must choose the highest-impact feasible items that address the bottleneck and are aligned with the adaptive priority model. From the immediate priorities, #3 is "Expand accessibility/settings and subjective polish surfaces." This directly addresses the accessibility bottleneck. We should also consider that without a settings menu, we cannot implement the accessibility toggles. Therefore, the first step is to add a settings button and a settings menu. Looking at the code in main.gd, we see that the UI is built in `build_ui()`. We can add a settings button there and then implement the settings menu. However, note that in the AUTONOMOUS_STATE.md context, there was a failed attempt to add a settings menu. We must avoid r

### Execution evidence
Added persistent reduced_motion and high_contrast defaults; load_data already merges only known keys, so older saves migrate safely.

### Next-cycle rule
Re-read current source and resolve the next atomic phase from evidence. Do not repeat a failed phase unchanged; reduce scope or change route.
<!-- AUTO_CYCLE_END -->
