# Changelog

Newest first. Version numbers follow `config/app.json` / `export_presets.cfg` (`0.1.0`).

## 0.1.0 — current working tree (rebrand + shooting)

**Repo layout**
- The Godot project **is** the repository root: `core/`, `autoload/`, `ui/`, `data/`, `config/`,
  `assets/`, `tests/`, `export_presets.cfg`. The old `godot/` subfolder is gone.
- The `supabase/` folder is **not** part of this repository any more — only the client
  (`autoload/backend_service.gd`) survives; the server contract is documented in
  `SUPABASE_SETUP.md`.
- Rebranded to **Block Falling Blast**, studio *MILO | FOUNDERS* (`config/app.json`); the app icon
  is `assets/app_icon.png` and no Godot robot icon is used any more.
- The GitHub Actions Android workflow was removed; there is currently **no CI**.

**New gameplay: shooting stone blocks**
- Stone blocks (colour 9) are pre-placed level obstacles that cannot be moved.
- Tap once → the stone **cracks** (free); tap again → it is **destroyed** and one charge is spent.
- Charges: 5 in level/daily games, 3 in endless. `GameSession.shoot()`, `is_shootable()`,
  `has_stone()`.
- A destroyed stone does **not** make the blocks above it fall (same for the hammer booster).
- Level start layouts always contain at least 4 stones, so the ability is available from level 1.
- New HUD element `ui/shots_chip.gd` (crosshair + remaining charges, only visible while stone is on
  the board), hand-drawn crack overlay in `BoardView`, new SFX `crack` / `shot`.

**UI**
- New `ui/screens/adventure.gd` replaces the old chapter screen: current level, how to complete it,
  overall progress and the chapter map in one page.
- New `ui/streak_chip.gd` (day-streak pill on Home) and `ui/switch.gd` (music / SFX / haptics
  switches in the sound area of Settings).
- Settings was slimmed down: sound, language, notifications, privacy and data only.

**Localisation**
- 16 languages (`en`, `hi`, `ja`, `zh`, `es`, `fr`, `de`, `pt`, `ru`, `ko`, `ar`, `it`, `tr`, `id`,
  `vi`, `pl`), 57 keys each. English is the key, `en.json` is intentionally empty and every missing
  key falls back to English.

**Art**
- UI art from an original reference sheet: 9 gem blocks (incl. a stone block), purple/blue/gold pill
  buttons, square buttons, ON/OFF toggles, coin, gem, star, empty star, lock, and menu icons for
  Daily, Events, Season, Trophy, Profile, Chest, Calendar, Language, Privacy, Info, Close.
- `UIKit.tex()` caches the textures, `UIKit.art_style()` builds 9-slice button skins; everything
  falls back to the procedural drawing when a texture is missing.

**Tests**
- `tests/test_shooting.gd` added (7 tests): only stone is shootable, crack → destroy, charge
  limits, no gravity after a destroy, hammer does not make blocks fall, shot state survives a save
  round-trip, every level starts with stone.
- Suite is now **54 tests / 1146 assertions, 0 failures** (Godot 4.7.2, headless).
- The crawlers `tests/crawl_ui.gd` (every button on every screen) and `tests/crawl_back.gd`
  (Android back on every screen) cover the 19 screens: **18 screens / 1211 button presses / 0
  script errors** and **18 screens / no errors** respectively.

**Documentation**
- All markdown documentation was rewritten against the current code: `README.md`, `CLAUDE.md`
  (new), `AGENTS.md` (was empty), `ARCHITECTURE.md`, `FEATURES_CHECKLIST.md`, `TESTING.md`,
  `EXPORT_GUIDE.md`, `SUPABASE_SETUP.md`, `BILLING_SETUP.md`, `ADS_SETUP.md` (new),
  `DEVELOPMENT_PLAN.md`, `NEXT_LEVEL_PROMPT.md`, `CHANGELOG.md`.

**Fixed**
- Removed the leftover debug print in `tests/test_ui.gd` that polluted the test output.

---

## Earlier history — pre-merge “Block Falling Blast” line (archived)

These entries describe the development line that existed before the current repository was
merged; they are kept for reference (levels, art passes, gravity rules v2).

### 0.3.3 — second art pass (sheets 2 and 3)
- New art in `assets/ui/`: stone gem (block 9), red/green pill buttons (danger/good), square
  buttons, ON/OFF toggles, empty star, lock, menu icons.
- Used: stone block on board, Quit/Continue buttons, square pause button, Settings/Sound toggles,
  locked levels show a lock, empty stars, icons on the Home "More" buttons.
- Not used yet: board frame, portrait background, plain panel, progress bar, check mark, info/close
  icons (the sliced files for these were dropped; re-slice from the sheets when needed).

### 0.3.2 — gem art pass (from supplied reference sheet)
- Sliced the user-supplied reference sprite sheet into `assets/ui/` (8 gem blocks incl. a
  hue-shifted pink, blue/purple/gold pill buttons, hammer/refresh/shuffle, coin, gem, star).
  Background removal was scripted; the stone block (9) stays procedural.
- `UIKit.tex()` / `UIKit.art_style()`: cached textures + 9-slice button skins (primary = purple,
  secondary = blue, accent = gold-rimmed); danger/good stay flat. All code falls back to the old
  vector drawing if a texture is missing.
- Board/tray/logo blocks, booster buttons (with icons), currency bar and star rows now use the art.
  No game rules touched; 47 tests pass.
- Not done: the sheet's background panel, board frame, medals, ribbons, shield/crown and sparkle FX
  are not used yet (unused files were not kept).

### 0.3.1 — async/await + full UI crawl
- Fixed "Trying to call an async function without await": `Main.go()` is no longer a coroutine
  (tween `finished` → `_swap`); dialog/button lambdas that call coroutines now `await`;
  fire-and-forget network/ad calls use `call_deferred`.
- Added `tests/crawl_ui.gd` (opens every screen, presses every button/toggle/slider and every
  dialog button) and `tests/crawl_back.gd` (Android-back on every screen): 1007 presses, 19 screens,
  0 script errors.
- Privacy/Terms now go back to Settings (they were returning Home).
- README rewritten as a full project guide; added `NEXT_LEVEL_PROMPT.md`.

### 0.3.0 — Gravity (rules v2)
- After any line clear (horizontal or vertical) every block falls straight down its column; if the
  fall completes new lines they clear too (chain). Hammer and Continue also settle the board.
  Animated: clear flash, then blocks accelerate down.
- Level / daily starting layouts are now settled stacks on the floor (one column left empty so no
  line starts complete).
- Server rules bumped to version 2 (`_shared/game.ts` gravity + chain, `validate-score` requires
  rules = 2); replay cross-check 8/8 games identical.
- Tests: 47 tests, 917 assertions (gravity compaction, row/column drops, chain clears, session
  gravity, settled level layouts).

### 0.2.0
- Fixed desktop window going off-screen (title bar / minimize / fullscreen / close buttons
  unreachable): the window now starts as a 9:16 portrait fitted inside the usable screen area,
  centered, with the title bar on screen. Fullscreen is optional (Home "Full" button, F11,
  Settings); "Fit window to screen" in Settings.
- Launch sequence: game logo → studio name/logo → loading screen (real load steps + tips) → Home.
  Tap skips logo/studio. Studio name, tagline and game title are set in `config/app.json`.
- New Home: Adventure Mode (100 levels = 10 chapters × 10, progress + "Continue" shortcut),
  Classic/Endless mode (with Continue), Settings, Quit (hidden on Web); other screens under "More".
- Chapters expanded 6 → 10 (100 levels). Original-game assets deliberately NOT used (copyright) —
  logo/studio/loading art is original and procedurally drawn.

### 0.1.0 (initial build of that line)
- Stage 1–2: project, core engine (board, 42 pieces, validator, clears, scoring, death detection),
  drag-and-drop BoardView.
- Stage 3: algorithm families, difficulty manager, seeded generator, boosters, continue.
- Stage 4: 20 code-built screens, themes, i18n architecture, procedural audio, particles/popups.
- Stage 5: progression (6 chapters × 10 levels), daily, streak, season, events, achievements;
  versioned checksummed save with backup recovery and run resume.
- Stage 6: Supabase migrations (RLS), 6 Edge Functions, client `BackendService`; server score replay
  verified vs GDScript logs.
- Stage 7: ads + billing + notification abstractions with test modes and graceful fallbacks.
- Stage 8: export presets for Android / Windows / Web; Windows and Web exports run-tested, Android
  debug APK built.
- Stage 9: fixes found by testing — JSON int/float checksum mismatch (store payload as string),
  64-bit RNG state lost through JSON (store as string), zero-width layout (margin-based centered
  column), frozen tray intro animation (start redraw loop on bind), nondeterministic continue
  tie-break (made deterministic for server replay), leftover tmp save files.
- Stage 10: documentation.
