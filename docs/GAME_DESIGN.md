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
Tap while grounded to jump. Timing and landing position are the primary skill. From the title screen, DAILY and ENDLESS are one-tap **start** actions, not selectors requiring a second tap. Tapping empty space still launches the default mode. During a run, the FLOW HUD also labels the active mode.

Input routing: the fullscreen CanvasLayer container and read-only HUD labels
ignore pointer events. Only interactive menu buttons consume clicks/touches.
Gameplay processes the physical touch or desktop mouse event once, ignoring
Godot's synthetic mouse/touch emulation events to avoid a single mobile tap
accidentally triggering both jump and air pulse. Only the primary finger
(touch index 0) controls gameplay; additional simultaneous fingers cannot
start a run, consume the air pulse, or trigger retry.

The existing Godot CI now runs a headless **scene-level input integration
smoke** covering root/label/button mouse filters, primary and secondary
physical touches, a synthetic duplicate, menu handling and a genuine desktop click. This is not physical
Android qualification; separately verify real touch, UI buttons, multi-touch
behavior and frame pacing before release.

### Ledge jump grace
Walking off the edge of a platform starts a 0.09-second jump grace window. A
tap during this window makes a full jump without using the optional air pulse,
making near-edge mobile taps more forgiving. The grace is cleared immediately
after jumping or landing, on retry and on death. Once expired, the airborne tap
still uses the normal single air pulse. The existing scene-level Godot smoke
covers grace activation, jump behavior, pulse preservation and expiry. This
mechanical improvement does not replace human Android feel and latency testing.

### Air pulse
One optional mid-air tap gives a smaller corrective impulse. This preserves one-touch controls but creates route correction and advanced mastery.

### Pre-landing jump buffering
Once the single midair pulse has been used, a tap while descending is no
longer discarded. It queues one jump for up to 0.10 seconds; if the player
makes a valid supported landing during that window, the jump starts
automatically immediately after landing judgement and the air pulse refills.
The upper HUD briefly says **JUMP QUEUED**. The buffered input expires if
there is no landing, and is cleared on a jump, pulse, retry or death. Tapping
during the earlier airborne phase still consumes the normal pulse first.
This adds forgiveness for near-landing timing without granting an extra
midair jump or scoring an unsupported edge graze. The existing Godot scene
smoke covers successful buffering, expiry and reset; the 100 ms window needs
actual Android touch-latency and gameplay-feel validation.

### Air pulse status HUD
While airborne, a compact read-only cue above the landing judgement shows
**AIR PULSE READY** before the optional correction and **AIR PULSE USED**
after it. It disappears while grounded, on the ready menu, and after death.
It ignores pointer events so taps still control the jump. The pulse status and landing judgement occupy separate vertical bands to avoid text overlap on the portrait HUD. High-contrast mode
uses white text; the indicator introduces no new movement, scoring or
procedural generation behavior. Validate readability and touch passthrough
on a portrait Android device before release.

### Consistent edge collision
A landing is awarded only when the player's horizontal overlap is large enough
for the platform to support the player on the following physics frame. Mere
visual edge grazes must not trigger a landing cue, score or FLOW bonus and then
immediately drop the player. The existing Godot scene smoke covers both rejected
edge grazes and accepted supported edge landings. Physical Android collision
feel remains a separate QA gate.

### Perfect landing
The center strip of each platform is the perfect zone. Consecutive perfect landings build FLOW.

### Landing judgement HUD
On the first scored landing on a new platform, an in-game cue near the upper playfield labels the result: **PERFECT** (center strip), **CLUTCH** (edge recovery), or **LANDED** (ordinary). Scored judgements also show the points just earned. It fades after 0.72 seconds, without obscuring touch input or changing any score, combo, jump, pulse or procedural generation rule.

Reduced-motion mode shows the cue without a fade animation; high-contrast mode uses white text. Restart and death clear the cue immediately. This is an implementation feature, not evidence of subjective device-level game feel; verify portrait readability and touch handling on Android before release.

### FLOW
FLOW increases scoring and feedback intensity. Perfect landings and clutch
recoveries advance the streak without lowering an already earned multiplier.
Each ordinary landing lowers the streak by one and decays the FLOW multiplier
by 0.25, never below x1.0. Previously switching the clutch coefficient
(0.18) to the ordinary-landing coefficient (0.25) could *increase* FLOW on
an ordinary landing; this inconsistency is corrected. A Godot scene-level
integration smoke verifies perfect -> clutch -> ordinary and repeated ordinary
landings, while the overall difficulty and platform generation remain unchanged.

## 3. Difficulty
- Scroll speed rises continuously.
- Platform gap range expands over time.
- Platform widths contract with difficulty.
- Vertical variation forces pulse decisions.
- Daily mode uses a deterministic seed so every player can compete on the same sequence.

### Mobile save recovery
Settings offers **COPY BACKUP** and **RESTORE SAVE** to preserve local progress
across Android debug APK reinstalls signed with different temporary keys.
The user must paste the exported text into a separate notes application before
uninstalling. On the new install, copying the text back and tapping RESTORE
twice replaces progress only after integrity, version and schema validation.
The backup is checksum-protected but not encrypted; a restored daily best is
refreshed for the current date. Atomic temporary-file replacement reduces
the risk of a truncated save. Godot scene-level CI covers roundtrip,
tampering and incomplete backup rejection, not Android clipboard behavior.

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

When a run ends, the death flash, camera shake and existing particles still
decay to zero, then gameplay background redraws stop while the death screen
or title menu is idle. This prevents the old permanent death-screen flash/shake
and eliminates needless continuous scene redraw requests in static menus.
The existing headless scene smoke validates that effects settle, but device
battery consumption and render performance still need on-phone measurement.

On debug templates only, the upper-right QA HUD reports measured rendered FPS
and the worst render-frame interval from the previous one-second window. The
diagnostic readout uses native Godot frame statistics, samples once per second
instead of allocating UI strings every frame, stays visible after game over for
screenshots, and resets before a new run. It is disabled on release templates.
Headless integration verifies the instrumentation contract; only an actual
Android device can establish gameplay frame-pacing acceptance.

### HUD performance
The in-game HUD runs in the physics loop, but score, best score, coins and
FLOW labels are now formatted and assigned only when their underlying values
change. Pulse text and theme color also update only when visibility, readiness
or high-contrast mode changes. This removes redundant text/layout work during
uninterrupted play while preserving immediate UI updates on landings, pulse
consumption, death, retry and Daily/Endless mode switches. The existing Godot
scene smoke checks value transitions and unchanged-label reuse. No device-level
FPS gain is claimed without measurements from the Android debug overlay.

### UX
Readable at a glance; thumb zones avoid critical HUD obstruction; death-to-retry path is one action.

### Visual identity
Dark-space neon, cyan/white perfect zones, strong silhouette, minimal visual noise around landing targets. Cosmetics alter player palette/effects rather than collision readability.

### Audio direction
Short tactile jump transient, bright perfect chime that layers with combo, low death hit, escalating FLOW music stem. Audio assets must be original or properly licensed.

The six currently shipped arcade sound cues (coin/skin, jump, pulse, clutch,
perfect, death) are synthesized once when the Integrations autoload starts and
replayed by four reusable AudioStreamPlayer voices. The CLUTCH recovery now
receives a distinct audio cue instead of vibration alone. Short attack and
release envelopes keep the procedural PCM from clicking at either boundary.
Repeated gameplay feedback reuses the same PCM resources and nodes, without
per-tap audio allocation. Voice count is bounded under rapid effects; when
all four voices are busy the pool reuses one voice. Godot headless scene
integration verifies audio resource reuse, while audible feel, mixing,
latency and frame-time benefits still require an Android hardware check.

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
