# Jumpy

Jumpy is a portrait-first one-touch hybrid-casual arcade game designed around instant comprehension, short replayable runs, skill expression, social competition, and long-term collection.

## Core loop

**Tap. Jump. Land perfectly. Keep the FLOW alive.**

The world scrolls continuously. Tap from a platform to jump; tap once in the air to spend a corrective pulse. Perfect landings build FLOW, which raises score gain and feedback intensity. Miss the world and restart instantly.

## Already implemented

- Endless procedural platform generation.
- Difficulty/speed escalation.
- One-touch jump + single airborne pulse.
- Perfect-landing zones, combo and FLOW multiplier.
- Coins, run score, best score and persistent profile.
- Daily deterministic seed and daily best score.
- Missions, streak tracking and cosmetic skin unlock milestones.
- Haptic abstraction with mobile support.
- Share fallback through clipboard.
- Leaderboard, analytics and rewarded-ad integration boundaries.
- Procedural neon rendering: no proprietary asset dependency.
- Portrait mobile layout with desktop controls for development.

## Engine

Godot 4.x / GDScript. Open `project.godot` and run `scenes/Main.tscn`.

Desktop controls: Space, Enter or left click.

## Product strategy

Jumpy is intentionally not pure hypercasual. The core interaction remains one-second-simple, while progression, daily competition, cosmetics, missions and future LiveOps create retention depth. See `docs/GAME_DESIGN.md`.

## Android device build (no PC required)

A debug APK is built automatically by [GitHub Actions](https://github.com/dbrckk/Jumpy/actions/workflows/android-debug-apk.yml) whenever game code, scenes, assets or Android export configuration changes. Open the latest **successful main-branch** run and download the **Jumpy-Android-debug-…** artifact (ZIP containing the APK, SHA-256 checksum and source commit). Manual builds are also available through **Run workflow**.

See [Android device QA](docs/ANDROID_DEVICE_QA.md) for phone installation, signing caveats and the on-device acceptance checklist. Debug APK generation is not proof of production-release quality.

## External production setup

The game runs without external services. Optional production integrations are documented in `SETUP_REQUIRED.txt` so missing credentials never block development.
