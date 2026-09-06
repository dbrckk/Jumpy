# Jumpy — Production Roadmap

## Current milestone: playable vertical slice

Implemented: core movement, FLOW/perfect landings, procedural level generation, deterministic daily seed, coins, persistence, missions, streaks, skins, sharing fallback, haptics, procedural audio, neon UI/theme, analytics/ads/leaderboard integration boundaries, and Godot 4.7.2 headless CI.

## Gate A — Core feel
- Device-playtest on low/mid/high Android.
- Tune jump arc, pulse, platform gaps, camera kick and perfect-zone width.
- Target 60 FPS and immediate retry.
- Record first-run duration, retry rate, runs/session once analytics is connected.

Exit: no gameplay blocker, crash-free basic loop, strong immediate retry behavior.

## Gate B — Retention
- Daily challenge leaderboard.
- Three rotating daily missions instead of lifetime-only counters.
- 7-day streak rewards.
- 20+ cosmetic variants with readable silhouettes/effects.
- Weekly gameplay modifier system.
- Local ghost recording, then friend/global ghosts when backend is available.

Exit: retention data supports continued investment.

## Gate C — Social/viral
- Native share sheet and generated score-card image.
- Deep links into the current daily seed.
- Friend challenge flow.
- Personal-best and FLOW-chain share triggers.
- Daily/global/friends leaderboard tabs.

Exit: share conversion and invite-open rate are measurable and non-trivial.

## Gate D — Production polish
- Original art direction pass and cohesive motion language.
- Original layered music + final SFX mix.
- Accessibility: reduced motion, haptic/audio toggles, high-contrast option.
- Full localization architecture.
- Tutorial refinement, settings, pause, privacy/consent.
- Store icon, screenshots, trailer and listing assets.

Exit: release candidate quality across target device matrix.

## Gate E — Monetization after retention
- Optional rewarded revive.
- Optional rewarded post-run bonus.
- Cosmetic supporter/no-ads purchase.
- Never sell competitive power.

Exit: monetization does not reduce retention or retry rate.

## Gate F — Store release
- Android signing/AAB.
- Google Play testing tracks.
- Privacy policy/Data Safety/consent.
- Crash reporting and production analytics.
- Staged rollout and rollback plan.

All external-account/API actions must be documented first in `SETUP_REQUIRED.txt`.

## Definition of done
A release is not called "AAA" because it has many features. Jumpy reaches the intended quality bar only when input feel, frame pacing, UI, VFX, audio, progression, analytics, social loops, store compliance and device testing are all validated. Virality is an outcome to test; it cannot be guaranteed by code alone.
