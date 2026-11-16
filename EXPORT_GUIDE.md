# Export guide

Presets live in `export_presets.cfg`: **Android**, **Windows Desktop**, **Web**. Godot 4.7.2 with
export templates 4.7.2.stable installed. All three presets exclude `tests/*` and `*.md` from the
package and write into `build/` (git-ignored).

```bash
godot --headless --path . --import
godot --headless --path . --export-release "Windows Desktop" build/windows/BlockFallingBlast.exe
godot --headless --path . --export-release "Web"             build/web/index.html
godot --headless --path . --export-debug   "Android"         build/android/BlockFallingBlast-debug.apk
```

(The preset paths in `export_presets.cfg` already point at exactly these files, so the export
commands can also be run without the trailing path argument.)

## Verified status

| Target | Built | Run/tested |
|---|---|---|
| Windows x86_64 (embedded PCK) | yes — 2026-11-16 | yes — launched, clean exit, save written |
| Web (no threads) | yes — 2026-11-16 | yes — in a browser, gameplay drag/drop works |
| Android debug APK | yes — 2026-11-16 (signed with the Godot debug keystore) | **no** — no device |
| Android release AAB | **not built** | no |

The artifacts in `build/` were produced from this code base on 2026-11-16, shortly **before** the
last UI tweaks (settings/home/splash). Nothing in `build/` is committed. Re-run the export commands
above after any change and check the file timestamps before claiming a build exists.

## Android

Requirements (already configured on this machine in Editor Settings): JDK 17+ (21 used), Android
SDK (build-tools 36.1), debug keystore.

* Change `package/unique_name` (`com.example.blockfallingblast` is a placeholder) and the launcher
  icon before publishing. The current icon is `res://assets/app_icon.png`.
* The APK is built for `armeabi-v7a` + `arm64-v8a`; `version/code` 1, `version/name` 0.1.0.
* Requested permissions: INTERNET, VIBRATE, POST_NOTIFICATIONS.
* Release/AAB: switch `gradle_build/use_gradle_build=true` and `gradle_build/export_format=1` (AAB),
  install the Android build template (Project → Install Android Build Template), create a release
  keystore and set the `keystore/release*` options (never commit it). Plugins (AdMob, Play
  Billing, notifications) require the Gradle build.
* Back button is handled (`NOTIFICATION_WM_GO_BACK_REQUEST` → current screen's `on_back`).
  Portrait is set in the project settings. Install test:
  `adb install -r build/android/BlockFallingBlast-debug.apk`.

## Windows

Fullscreen (F11 / the saved `fullscreen` setting), the window starts as a 9:16 portrait fitted
inside the usable screen area. The exe embeds the release template + PCK, so it is large (~105 MB)
— compress/zip it for sharing. For distribution consider code signing (`codesign/enable`) and a
dedicated `.ico`; the current icon is `res://assets/app_icon.png`.

## Web

Built with `thread_support=false` so it works on any static host without COOP/COEP headers. Serve
`build/web/` over HTTPS (any static host); locally: `python -m http.server -d build/web 8060`.
Audio starts after the first user gesture (browser rule). Saves go to IndexedDB (clearing site
data erases them). Ads/billing/notifications are disabled on Web by `Platform`.
