# Jumpy — Adaptive Production Roadmap

This roadmap is a strategic framework, not a frozen checklist. The autonomous team must re-evaluate priorities every cycle using `AUTONOMOUS_TEAM.md`, `AUTONOMOUS_STATE.md`, current source, recent changes, QA evidence and any available player/device evidence.

## North star
Create a mobile arcade game with one-second comprehension and near-instant retry, but enough mastery, progression, identity and social tension to sustain repeated play. Feature count is secondary to coherence and feel.

## Current milestone
Playable vertical slice evolving toward an evidence-backed production candidate.

Implemented foundations include core movement, FLOW/perfect/clutch landing skill feedback, procedural level generation, deterministic daily seed, coins, persistence, missions, streaks, skins, sharing fallback, haptics, procedural audio, neon UI/theme, analytics/ads/leaderboard integration boundaries, Android export preset, Godot 4.7.2 headless CI and a 30-minute autonomous evolution pipeline.

## Adaptive priority model
Every candidate task is ranked against:

1. Expected player impact.
2. Effect on the weakest current quality domain.
3. Risk to the one-touch core.
4. Ability to validate safely now.
5. Reversibility.
6. Dependency cost.
7. Second-order effects on performance, UX, retention and maintainability.

The highest-value feasible item becomes the immediate action. If evidence changes, priorities change.

## Gate A — Core feel and comprehension
Goals:
- Device-tune jump arc, pulse, platform gaps, camera motion and scoring zones.
- Make success/failure causality obvious in under a second.
- Maintain immediate retry and stable 60 FPS target.
- Add automated invariants where possible for deterministic generation and run state.
- Instrument first-run duration, retry rate and runs/session once analytics is connected.

Exit evidence:
- no gameplay blocker;
- crash-free basic loop;
- reliable frame pacing on target devices;
- strong retry behavior in actual playtests;
- tutorial comprehension without text dependence where possible.

## Gate B — Mastery, retention and progression
Goals:
- Three rotating daily missions rather than lifetime-only counters.
- Seven-day streak reward structure.
- 20+ meaningful cosmetic variants with readable silhouettes/effects.
- Weekly gameplay modifier system that preserves fairness.
- Local ghost recording before backend-dependent social ghosts.
- Reward pacing/economy that gives goals without damaging instant replay.

Exit evidence:
- repeated-session behavior supports continued investment;
- progression does not obscure the arcade core;
- no obvious dominant exploit or dead reward path.

## Gate C — Social and viral systems
Goals:
- Native share sheet and generated score-card image.
- Deep links into the current daily challenge.
- Friend challenge flow.
- Personal-best, clutch and FLOW-chain share moments.
- Daily/global/friends leaderboard surfaces when backend exists.
- Ghost-based asynchronous rivalry.

Exit evidence:
- share conversion and invite-open rate are measurable;
- social systems create competition without blocking solo play;
- no spammy or coercive loop.

## Gate D — Extreme production polish
Goals:
- Cohesive final art direction and motion language.
- Layered original music and final SFX hierarchy/mix.
- Reduced motion, haptic/audio toggles and high-contrast option.
- Full localization architecture.
- Refined tutorial, settings, pause, privacy/consent surfaces.
- Store icon, screenshots, trailer and listing assets.
- Consistent micro-feedback for all meaningful player actions.

Exit evidence:
- release-candidate quality across target device matrix;
- no visual/audio/UI subsystem feels placeholder relative to the rest;
- accessibility paths are functional, not decorative.

## Gate E — Monetization only after retention evidence
Goals:
- Optional rewarded revive.
- Optional rewarded post-run bonus.
- Cosmetic supporter/no-ads purchase.
- Never sell competitive power.

Exit evidence:
- monetization does not reduce retention, retry rate or perceived fairness.

## Gate F — Store and live operations readiness
Goals:
- Android signing/AAB.
- Google Play testing tracks.
- Privacy policy, Data Safety and consent.
- Crash reporting and production analytics.
- Staged rollout and rollback plan.
- LiveOps content/update operating rhythm.

All external-account/API actions must be documented first in `SETUP_REQUIRED.txt`.

## Continuous cross-discipline audits
The autonomous system must periodically perform fresh audits even when the current backlog is non-empty:

- Core loop / game feel audit
- First-session UX audit
- Difficulty/mastery audit
- Retention/progression audit
- Social/viral audit
- Art/VFX/motion audit
- Audio/haptics audit
- Accessibility audit
- Performance/memory/frame-pacing audit
- Architecture/debt audit
- QA/testability audit
- Analytics/experiment audit
- Android/release/compliance audit

A discovered systemic weakness may supersede an older planned feature.

## Problem-solving protocol
A blocker never means “stop” unless every safe independent path is exhausted. The team must consider alternative implementation, simplification, local substitute, mock/stub boundary, architecture change, instrumentation, deferred external integration, or removal of unnecessary complexity. Failed approaches are evidence and must alter the next plan.

## Definition of done
Jumpy is not called complete because a feature list is long. The requested extreme quality bar is reached only when input feel, frame pacing, UI, VFX, audio, progression, accessibility, testing, analytics readiness, social loops, store compliance and real-device/player evidence are all strong, no P0/P1 issue remains, and a fresh adversarial multidisciplinary audit cannot identify a material feasible improvement.

Virality remains an outcome to measure, not a property that can be truthfully guaranteed by code alone.
