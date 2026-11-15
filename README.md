# Original Puzzle

An original, offline block puzzle game for Android, Windows and Web, built with
Godot 4.7 (Compatibility renderer) and typed GDScript. No plugins, no paid
assets, no network access.

## How to play

Drag one of the three pieces onto the 8x8 board. A piece must fit completely
inside the board and may not overlap other blocks. When a horizontal row is
completely filled it clears, and **gravity** then drops everything above it.
When all three pieces are used, three new ones appear. The game ends when none
of the remaining pieces fits anywhere.

### Rules in detail

- **Clearing:** only full horizontal rows clear. Several rows can clear at once.
- **Gravity:** after rows clear, each remaining row keeps its exact contents and
  falls so that no cleared row remains below it (whole-row compaction). This
  never changes the shape of what is left and can never create a new full row,
  so there are no cascades. The rule lives in `scripts/game/gravity.gd`.
- **Score:** 1 point per cell placed, plus `10 x rows x rows x combo` for a clear.
- **Combo:** counts consecutive placements that clear at least one row. A
  placement that clears nothing resets it to zero.
- **Fair pieces:** a new set of three is re-rolled (up to 12 times) if none of
  its pieces would fit the board at all. A set that still cannot fit is allowed,
  so a genuinely full board still ends the game.

## Project layout

```
scenes/            main, menu, game, settings scenes
scripts/game/      pure rules: board, gravity, pieces, scoring (no nodes)
scripts/ui/        screens, board/piece drawing, animations
scripts/systems/   autoloads: Settings (save/load), Haptics, Sfx
assets/            icons (SVG source + generated PNG); audio is synthesised
tests/             headless test runners
tools/             gen_icons.gd (SVG to PNG)
```

Game logic (`scripts/game`) never touches nodes, input or animation. The UI
reads results from `GameState.place_piece()` and animates them.

## Requirements

- Godot 4.7.2 stable (Standard, not .NET) and its export templates
  (Editor > Manage Export Templates).
- For Android: JDK 17 or newer, and the Android SDK (see below).

In the commands below, `godot` means your Godot executable (use the `_console`
build on Windows to see output).

## Run

```
godot --path .
```

## Tests

```
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . res://tests/ui_tests.tscn
```

- `run_tests.gd`: placement, invalid placement, row clearing, multi-row clears,
  gravity, scoring, combo, piece regeneration, game over, restart, save/load.
- `ui_tests.tscn`: drives the real game screen (drag and drop, invalid drops,
  clear and gravity animation, pause, restart, game over, navigation) and checks
  layout at six screen sizes from small phone to landscape desktop.

Both exit with code 1 on any failure. The tests use temporary save files and
never touch your real best score.

## Saved data

Stored locally in `user://settings.cfg`: best score, sound, volume, vibration
and placement-preview settings. Nothing is sent anywhere.

## Exports

Presets are in `export_presets.cfg`. Output goes to `build/`, which is
git-ignored.

```
godot --headless --path . --export-release "Windows Desktop" build/windows/OriginalPuzzle.exe
godot --headless --path . --export-release "Web"             build/web/index.html
godot --headless --path . --export-debug   "Android APK (debug)"  build/android/OriginalPuzzle-debug.apk
godot --headless --path . --export-release "Android AAB (release)" build/android/OriginalPuzzle-release.aab
```

The Web preset disables thread support, so it works on any static host without
special headers. Serve `build/web/` over HTTP (browsers block `file://`), for
example `python -m http.server -d build/web`.

### Android setup

Package id `com.voidpanther.originalpuzzle`, name "Original Puzzle", portrait,
minimum Android 7.0 (API 24), arm64 for the debug APK, arm64 and armv7 for the
release AAB. The only permission requested is `VIBRATE`.

1. Install the Android SDK so it lives at `%LOCALAPPDATA%\Android\Sdk`
   (or set the path in Editor > Editor Settings > Export > Android). Needed
   packages for Godot 4.7.2:

   ```
   sdkmanager "platform-tools" "build-tools;36.1.0" "platforms;android-36" "cmake;3.10.2.4988404" "ndk;29.0.14206865"
   ```

   The first run asks you to accept Google's SDK licenses. If your Windows user
   name contains a space, run `sdkmanager` from a space-free copy of the
   command-line tools, or use short (8.3) paths.
2. Set the JDK path in Editor Settings > Export > Android > Java SDK Path (or
   set `JAVA_HOME`).
3. Install the Android build template once: Project > Install Android Build
   Template (creates the git-ignored `android/` folder).
4. The standard debug keystore must exist at
   `%APPDATA%\Godot\keystores\debug.keystore` (alias `androiddebugkey`,
   password `android`). Create it with:

   ```
   keytool -genkeypair -keystore debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
   ```

### Release signing

Never put keystore files or passwords in the project or in git (`*.keystore`,
`*.jks`, `export_credentials.cfg` and `.env` are git-ignored).

1. Create a release keystore once and **back it up safely**; losing it means you
   can no longer update the app:

   ```
   keytool -genkeypair -v -keystore original-puzzle-release.jks -alias release -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Supply the credentials through environment variables, never files in the repo:

   ```
   set GODOT_ANDROID_KEYSTORE_RELEASE_PATH=C:\secure\original-puzzle-release.jks
   set GODOT_ANDROID_KEYSTORE_RELEASE_USER=release
   set GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=<your password>
   ```

3. Export the AAB with the command above and upload it to Google Play. Increase
   `version/code` in the Android presets for every upload.

### iOS (future)

Not configured yet. The project uses only cross-platform Godot features, so it
should export to iOS later with the iOS export template and a Mac.

## Original assets

All visuals are drawn in code or generated from the SVG icons in this repo, and
all sound effects are synthesised at start-up (`scripts/systems/sfx.gd`). No
third-party art, audio or fonts are used.
