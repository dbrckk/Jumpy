# Jumpy — Android debug build and device qualification

## Build from a phone (no PC required)

1. Open the [Android debug APK workflow](https://github.com/dbrckk/Jumpy/actions/workflows/android-debug-apk.yml) in the GitHub browser, sign in, select **Run workflow** on `main`, then confirm.
2. Open the successful run and download the **Jumpy-Android-debug-…** artifact under **Artifacts**. GitHub supplies a ZIP file; extract it on the phone.
3. Install `Jumpy-debug.apk` only if you trust the repository build. Android may request permission to install apps from your browser or file manager.
4. Open Jumpy in portrait. No PC, Play Store publication, API key, or paid signing account is required for this *debug* build.

**Important:** A new temporary debug signing key is generated for each workflow run. An APK from a later run usually **cannot update the previous installation**. Uninstall the old debug app first if Android reports a signing conflict. Uninstalling removes the app's local save data. Debug APKs are **not** signed for Google Play release; do not publish them as production apps.

The workflow downloads and verifies the official Godot 4.7.2 Linux editor and matching Android export templates, configures the Android SDK and Java 17, exports the existing ARM64 Android preset, and attaches the resulting APK for **seven days**. Its success means that the APK was built; it does **not** prove device rendering, FPS, or touch quality.

## On-device acceptance

- **Start:** launch the game and tap an empty area once. Confirm the first tap performs a single jump, without immediately spending the air pulse.
- **Menus:** DAILY, ENDLESS, SKIN, SETTINGS, all Settings toggles, and BACK work without accidentally starting a run.
- **Multi-touch:** touch with two fingers; secondary fingers must not spend the air pulse or trigger a retry.
- **Ledge grace:** just after leaving an edge, a quick tap should still jump; after roughly 90 ms, the same airborne tap should use the optional pulse instead.
- **Landing:** PERFECT, CLUTCH and LANDED cues remain readable; no overlap with AIR PULSE status or top score labels.
- **Accessibility:** test reduced motion and high contrast, then retry after dying.
- **Performance:** play for several minutes; check frame pacing, stutters and input delay, especially after repeated deaths and particle bursts.

Report the phone model, Android version, the tested workflow run URL, and a screenshot/video of any visual or touch defect. **Do not call the game Android-qualified until this physical-device checklist passes.**
