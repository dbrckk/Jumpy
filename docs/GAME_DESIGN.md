# Jumpy — Game Design / Product Spec

## North star
Create a game that is as instantly readable as Flappy Bird but has a much longer mastery and retention curve. Viral success cannot be guaranteed; the product is structured to maximize testability, replayability, shareability and retention.

## 1. Core promise
- Understandable in < 2 seconds.
- One-thumb portrait play.
- Failure feels attributable to the player, not randomness.
- Retry begins immediately.
- Every run can produce a shareable achievement.

## 2. Core mechanics
### Tap jump
Tap while grounded to jump. Timing and landing position are the primary skill.

### Air pulse
One optional mid-air tap gives a smaller corrective impulse. This preserves one-touch controls but creates route correction and advanced mastery.

### Perfect landing
The center strip of each platform is the perfect zone. Consecutive perfect landings build FLOW.

### FLOW
FLOW increases scoring and feedback intensity. It resets gradually through imperfect play rather than punishing a single minor error too heavily.

## 3. Difficulty
- Scroll speed rises continuously.
- Platform gap range expands over time.
- Platform widths contract with difficulty.
- Vertical variation forces pulse decisions.
- Daily mode uses a deterministic seed so every player can compete on the same sequence.

## 4. Retention meta
Already represented in profile data:
- Lifetime score.
- Runs.
- Perfect landings.
- Daily best.
- Play streak.
- Coin bank.
- Skin unlock milestones.
- Three evergreen missions.

Next LiveOps layer after retention validation:
- 7-day quest tracks.
- Weekly themed world modifier.
- Friends leaderboard / ghost replay.
- Limited cosmetic collections.
- Seasonal score ladder.

## 5. Viral loop
1. Player gets a personal best / rare FLOW chain.
2. Game immediately offers SHARE.
3. Share payload challenges another player to beat the score.
4. Daily seed makes score comparison fair.
5. Future deep link opens directly into the same daily challenge.

## 6. Monetization philosophy
Never damage the retry loop.
- No forced ad before the player understands the game.
- Rewarded revive is opt-in.
- Cosmetics are the preferred IAP.
- Competitive power is never sold.
- Monetization is enabled only after retention/engagement data justifies it.

## 7. Analytics questions
The production analytics layer must answer:
- What percentage of installs start a first run?
- Median first-run duration and score.
- Retry rate within 10 seconds of death.
- Runs per session.
- Perfect-landing rate by score band.
- Share button conversion.
- Daily mode adoption.
- D1 / D7 / D30 retention.
- Rewarded-ad opt-in and post-revive retention.

## 8. Quality bars
### Gameplay
Input response should feel immediate. No gameplay dependency on network availability.

### Performance
Target 60 FPS on mid-range Android hardware. Avoid per-frame allocations in production hot paths and profile before adding heavy VFX.

### UX
Readable at a glance; thumb zones avoid critical HUD obstruction; death-to-retry path is one action.

### Visual identity
Dark-space neon, cyan/white perfect zones, strong silhouette, minimal visual noise around landing targets. Cosmetics alter player palette/effects rather than collision readability.

### Audio direction
Short tactile jump transient, bright perfect chime that layers with combo, low death hit, escalating FLOW music stem. Audio assets must be original or properly licensed.

## 9. Release gates
Do not spend on user acquisition before these are measured in a meaningful test cohort:
- Tutorial/first-run start > 90%.
- Strong immediate retry behavior.
- Stable crash-free sessions.
- Performance acceptable on low/mid-tier Android.
- A meaningful share trigger exists.
- D1 retention demonstrates the core loop deserves further investment.

## 10. AAA interpretation
AAA quality here means ruthless polish, reliability, feedback, UX consistency, art/audio cohesion and production discipline — not unnecessary complexity. The game should remain simple enough that a first-time player understands the objective instantly.
