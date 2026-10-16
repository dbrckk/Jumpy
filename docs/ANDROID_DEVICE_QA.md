# Jumpy — Android debug build and device qualification

## Build from a phone (no PC required)

1. Open the [Android debug APK workflow](https://github.com/dbrckk/Jumpy/actions/workflows/android-debug-apk.yml) in a phone browser. **Each change to gameplay, scenes, assets, add-ons or the Android export configuration automatically builds a fresh APK** on `main`. For a one-off build, sign in, choose **Run workflow** on `main`, then confirm.
2. Open the latest **successful run on `main`** and download its **Jumpy-Android-debug-…** artifact under **Artifacts**. Avoid installing builds from unreviewed pull requests. GitHub supplies a ZIP file; extract it on the phone.
3. The archive contains `Jumpy-debug.apk`, its `Jumpy-debug.apk.sha256` checksum and `SOURCE_COMMIT.txt` (the exact Git commit used). The CI also checks that the APK has a valid signature, the expected package name and ARM64 libraries. Optionally compare the APK checksum with a trusted local SHA-256 tool before installing.
4. Install `Jumpy-debug.apk` only if you trust the repository build. Android may request permission to install apps from your browser or file manager. Open Jumpy in portrait. No PC, Play Store publication, API key, or paid signing account is required for this *debug* build.

**Important:** A new temporary debug signing key is generated for each workflow run. An APK from a later run usually **cannot update the previous installation**. Uninstall the old debug app first if Android reports a signing conflict. Uninstalling removes the app's local save data. Debug APKs are **not** signed for Google Play release; do not publish them as production apps.

The workflow downloads and verifies the official Godot 4.7.2 Linux editor and matching Android export templates, configures the Android SDK and Java 17, exports the existing ARM64 Android preset, and attaches the resulting APK for **seven days**. Normal documentation and AI-context-only commits do not trigger a costly new build. Its success proves package construction and static APK checks, **not** device rendering, FPS, touch quality or accessibility.

## On-device acceptance

- **Start:** launch the game and tap an empty area once. Confirm the first tap performs a single jump, without immediately spending the air pulse.
- **Menus:** DAILY, ENDLESS, SKIN, SETTINGS, all Settings toggles, and BACK work without accidentally starting a run.
- **Multi-touch:** touch with two fingers; secondary fingers must not spend the air pulse or trigger a retry.
- **Ledge grace:** just after leaving an edge, a quick tap should still jump; after roughly 90 ms, the same airborne tap should use the optional pulse instead.
- **Landing:** PERFECT, CLUTCH and LANDED cues remain readable; no overlap with AIR PULSE status or top score labels.
- **Accessibility:** test reduced motion and high contrast, then retry after dying.
- **Performance:** play for several minutes; check frame pacing, stutters and input delay, especially after repeated deaths and particle bursts.

Report the phone model, Android version, the tested workflow run URL, and a screenshot/video of any visual or touch defect. **Do not call the game Android-qualified until this physical-device checklist passes.**
