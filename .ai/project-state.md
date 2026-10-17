# Project state

Status: active

## Working
- PR #34 replaces fixed short procedural gaps with projected-speed/height-aware jump-distance corridors; retains 140 world units of takeoff space and 120-unit randomized variation, including wider late-game gaps. Existing Godot scene smoke validates 750 seeded transitions across speeds/difficulties and one actual 60 Hz generated-platform landing. Gameplay-head Godot passed (39036554008); Android build 39036554018 initially in progress. Exact latest-head and real Android feel pending.
- PR #33 fixes unfair daily streak continuity when crossing local midnight: only consecutive civil dates count, two-day gaps and future-dated saves reset, leap/year transitions work. The existing scene smoke now tests duplicate-day, date gap, leap/year changes and clock rollback; exact-head CI pending before merge.
- PR #32 enriches native Godot neon depth (platform extrusions, luminous landing targets, collectible glints, glossy hero, nebula/stars) with offscreen geometry culling and reduced-motion/high-contrast variants. Godot PR scene/render-path smoke 39035357927 succeeded; ARM64 signed debug APK 39035358002 succeeded. Visual quality and frame pacing on physical Android unverified.
- PR #31 precomputes six procedural sound effects and uses a fixed four-player pool instead of rebuilding WAV/audio nodes for every tap; adds previously missing CLUTCH sound and smooth onset/tail. Godot 4.7.2 scene smoke run 39034429206 and Android debug APK 39034429205 both succeeded before merge. Device audio latency/quality and performance remain unmeasured.
- PR #30 finishes camera-shake, flash and particle decay after death; READY/DEAD static scenes no longer request continuous redraws when settled. Existing scene smoke checks post-death decay and stable READY; Godot PR CI 39033283593 and signed Android APK CI 39033283598 succeeded. Real Android power/FPS measurements remain unverified.
- PR #28 buffered late descending jumps after the pulse is spent for 100 ms; only a supported landing consumes the buffer. Added JUMP QUEUED indicator, expiry and reset. PR Godot scene smoke 39017528341 and signed Android APK 39017528352 succeeded; merged main d727f5e8 with Godot 39017597432, APK 39017597418 and standards 39017598183 all successful. Real Android tap-latency acceptance remains outstanding.
- PR #27 avoids regenerating SCORE/BEST/COINS/FLOW labels and pulse font/theme every physics tick when unchanged. Existing scene smoke and debug APK passed on PR (39017380729, 39017380605) and main (39017424987, 39017424990), plus standards 39017425724. No measured hardware frame-rate improvement is claimed.
- FLOW fairness correction PR #25: perfect and clutch landings never lower FLOW; ordinary landing subtracts 0.25 to x1 floor instead of sometimes increasing the reward. Real-scene Godot smoke and signed Android APK succeeded (runs 39012770357, 39012770361). Device feel not measured.
- PR #24 debug-only FPS and worst render-frame telemetry merged at 82fb4b57; main Godot, APK export and standards succeeded (runs 39012676918, 39012676814, 39012677628).
- PR #24 introduces debug-only in-game rendered FPS and one-second worst frame interval. Godot parse/scene smoke succeeded (39012547771), ARM64 signed debug APK succeeded (39012547805). Release templates hide it. Real Android FPS is not measured yet.
- PR #23 portable save recovery implemented: Settings COPY BACKUP / RESTORE SAVE (double confirmation), SHA-256-verified versioned text, validated profile data and atomic temporary-file save. Godot scene smoke success 38940339891; signed Android QA APK export success 38940339814. Still requires physical Android clipboard + reinstall acceptance.
- Android QA APK pipeline is active: #19 adds export; #20 triggers builds on gameplay/source/asset/preset changes and verifies APK signature, package identity, ARM64 native libraries, SHA256 and source SHA. Main APK build run 38933014477 succeeded, artifact 12058629507 (7-day retention).
- One-tap mode onboarding #21 merged at 4ff41a8d: DAILY and ENDLESS buttons immediately begin their runs and mode appears in FLOW HUD; scene-level input smoke plus main Android export succeeded.
- 90 ms coyote jump grace after walking off ledges in PR #18: preserves the single air pulse, auto-clears on jump/landing/death/retry; Godot 4.7.2 scene input smoke PASS (run 38923324910). Physical Android play-feel remains unverified.
- PR #17 secondary-finger input guard merged at 5e1e3a688b58; Godot + repository standards on main succeeded (runs 38921435757, 38921437647).
- Mobile tap input fix #15 merged at b1c62f7a: fullscreen HUD/labels no longer swallow gameplay taps, synthetic pointer duplicates cannot auto-consume air pulse, menu Button handling preserved; Godot scene-level smoke added to validation workflow.
- Central AI repo-map generation is configured through dbrckk/repo-standards; the Godot search index now passes 6/6 health checks.
- Trusted Production-OS branch-to-draft-PR handoff and exact-SHA Godot validation are operational (canary #31, PR #10).
- Landing judgement HUD is merged on main in PR #11 (commit bc62b2c0): PERFECT/CLUTCH/LANDED, actual awarded points, 0.72-second cue, reduced-motion and high-contrast support, reset/death cleanup, unchanged movement and scoring.
- Repository agent instructions follow the pinned 88-rule policy.

## Broken / blockers
- Android debug export still regenerates its signing key on every build; the PR #23 manual text-backup/restore provides a phone-only preservation path but requires external Notes storage **before uninstall**. A persistent signing identity, Play release signing and physical Android QA are still outstanding.
- Autonomous *gameplay implementation* has not passed: canary #32 (workflow 1b5290ee2ca742b4a50601b995144a82) ended capacity_exhausted/project_envelope_exhausted after two native Godot model stages. Its checkpoint ca2799f on studio/pos-7e4a13159234bb4f6272c89b changed only .studio/state.json, not gameplay code.
- No physical Android visual/touch/frame-pacing qualification or real player comprehension evidence yet; automated headless input smoke does not replace hardware QA.

## Current priority
- Test late-game generated-route fairness on physical Android at 900–970 world units/s; geometric reachability cannot establish human reaction success. Compare near-edge flow and coyote/queued taps with long high-speed gaps.
- Review calendar-based streak correction for local timezone and clock rollback on physical Android; unitless midnight comparisons are validated in scene smoke, device time changes still pending.
- Analyze high-speed generated-platform reachability against fixed jump/pulse trajectories before changing level difficulty.
- Inspect new 2D neon art on a portrait Android phone, checking platform/coin silhouettes, high-contrast landing cues, reduced-motion coin stillness and QA FPS/worst ms against prior APK.
- Test cached jump/pulse/coin/PERFECT/CLUTCH/death cues on Android (rapid overlap, no PCM clicks, sound preference), correlating QA FPS/worst ms with repeated actions.
- Verify on physical Android that the death screen stops shaking/flashing, and compare static-menu battery/CPU impact with debug FPS/worst-frame observations before making performance claims.
- Assess 100 ms jump buffer against Android touch latency and intended timing: a late tap after pulse use queues one jump only on supported landing; early tap expires. Capture video if it feels overly forgiving or triggers unexpected rebounds.
- Use debug FPS and worst-frame readout to quantify whether HUD caching reduces frame-time spikes on actual mid-range Android; inspect rendering profiler if stutters persist.
- Check player perception of FLOW increases/decreases and streak feedback on a real phone while watching the debug FPS overlay.
- Use QA FPS and WORST ms display on a physical Android device; record any spikes and compare reduced motion/high contrast, then profile hot paths based on evidence.
- Verify backup export to Notes and restore after Android reinstall on real hardware; confirm best score, coins, skins, daily reset, clipboard persistence and accessibility.
- Test the latest verified main APK (run 38933014477) on a physical Android phone following docs/ANDROID_DEVICE_QA.md; check one-tap mode start, HUD, collision feedback, reduced-motion/contrast and frame pacing.
- Measure whether 90 ms edge grace improves accidental missed jumps on physical Android; tune window only after gameplay feedback.
- Conduct physical Android touch + menu button + multi-touch and frame-pacing QA after PR #15, including jump/pulse separation.
- Reduce native Godot agent context/planning-token consumption or implement a genuinely bounded small-change coding lane; do not simply raise cost limits or repeat exhausted canary #32 unchanged.
- Validate the new landing cue on a real portrait Android device, including repeated landing, retry, high contrast, reduced motion, touch passthrough and frame pacing.

## Validation
- PR #34 speed-aware route generation: Godot scene-integration run 39036554008 passed on gameplay head; signed ARM64 APK run 39036554018 must complete success and exact final PR SHA checks precede merge. Real-device playtesting still pending.
- PR #33 exact-head Godot and Android CI run IDs 39036093799 and 39036093873; complete result is required before merge, and physical Android clock/date testing remains outstanding.
- PR #32 Godot 4.7.2 parse + scene render variant smoke success (39035357927); signed ARM64 debug APK export success (39035358002). No claimed physical-device GPU benchmark.
- PR #31 pooled SFX integration smoke and Godot parse succeeded (39034429206); signed ARM64 debug APK export succeeded (39034429205). Physical device audio quality unverified.
- PR #30 Godot parse/scene smoke (39033283593) and signed ARM64 debug APK (39033283598): both succeeded before merge; no hardware Android benchmark.
- PR #28 pre-landing buffer Godot 39017528341 and Android export 39017528352 both success; merged main Godot 39017597432, Android 39017597418, standards 39017598183 all success. No physical Android test.
- PR #27 HUD-value caching Godot 39017380729 and Android export 39017380605 successful; merged main Godot 39017424987, Android 39017424990, standards 39017425724 successful.
- PR #25 Godot parse+scene smoke 39012770357 and signed ARM64 APK 39012770361: both success. Real-device evaluation pending.
- PR #24 main Godot 39012676918, Android APK 39012676814, standards 39012677628: completed success.
- PR #24 Godot input/runtime smoke: success (39012547771); debug APK export and Android package checks: success (39012547805). Device behavior not tested.
- PR #23 verified: 38940339891 (Godot parse + real-scene save smoke); 38940339814 (signed ARM64 APK export). Human Android clipboard test remains outstanding.
- #21 main Godot validation succeeded (38933014631), Repository standards succeeded (38933016305), Android APK export succeeded (38933014477), and PR checks succeeded (38932900546, 38932900548). No claim of hardware Android performance.
- PR #18 gameplay parse/smoke success, run 38923324910. Scene smoke covers ledge grace activation, consumption, expiration, existing pulse and mobile input; not a device test.
- PR #15 scene-level input smoke and Godot parse: success (run 38913510252). Merged-main Godot parse/smoke: success (run 38913796123); repository standards: success (run 38913797853). No device-level Android QA claimed.
- Landing-feedback PR #11 exact-head Godot 4.7.2 import/parse and production-document checks: success (run 38764425310).
- Merged main bc62b2c0 Godot project validation: success (run 38764507391).
- Merged main Repository standards unified CI: success, including Repo Brain (run 38764508490).
- Keep gameplay feel and real-device behavior distinct from headless parse confidence.

## Last verified
- 2026-10-17

<!-- AUTO:START -->
## Automatic repository state

Generated: 2026-10-17T13:21:47Z

### Git
- Branch: `main`
- Head: `94295b9a4403`
- Commit date: 2026-10-17T09:21:39-04:00
- Commit: Fix local-calendar play streaks across midnight, gaps and clock rollback (#33)
- Tracked files: 109

### Recently changed files
- `docs/GAME_DESIGN.md`
- `scripts/profile.gd`
- `tools/smoke_mobile_input.gd`
- `docs/ANDROID_DEVICE_QA.md`
- `scripts/main.gd`
- `scripts/integrations.gd`

### Project signals
- `project.godot`

> Generated by dbrckk/repo-standards. Keep manual priorities and blockers outside the AUTO markers.
<!-- AUTO:END -->
