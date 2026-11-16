# Block Falling Blast — project guide

> An original 8×8 block-puzzle game with gravity, built with **Godot 4.7.2 / typed GDScript** and
> exported to **Android (primary)**, **Windows Desktop** and **Web**. This document is written so it
> can be pasted into ChatGPT / Claude and still give a complete picture of the project. A
> ready-made "continue development" prompt lives in `NEXT_LEVEL_PROMPT.md`.

## 1. What this is

* **Repository root = Godot project root.** `project.godot`, `core/`, `ui/`, `autoload/`, `data/`,
  `config/`, `assets/`, `tests/` and `export_presets.cfg` are all at the top level. There is **no**
  `godot/` subfolder and **no** `supabase/` folder in this repository.
* Entry scene: `res://ui/main.tscn` · renderer: GL Compatibility · typed GDScript, no plugins, no
  paid assets, no network requirement (online features are optional and off by default).
* **Provenance:** everything here is original. No code, art, audio or branding was taken from any
  other game or store app. Art is drawn procedurally or sliced from an original reference sheet,
  audio is synthesised at runtime.

## 2. How to run

```bash
godot --path .                                             # play (desktop window auto-fits the screen)
godot --headless --path . --import                         # once, registers class_name scripts
godot --headless --path . -s res://tests/run_tests.gd      # unit tests
godot --headless --path . -s res://tests/crawl_ui.gd       # presses every button on every screen
godot --headless --path . -s res://tests/crawl_back.gd     # Android-back on every screen
```

On Windows use the `_console` build so the output is visible.
Exports: see `EXPORT_GUIDE.md`.

## 3. The game (rules)

* **8×8 board.** Each turn the player has a **tray of 3 pieces**; drag one onto the board (mouse or
  touch). Pieces **cannot be rotated**.
* **42 pieces** = 15 base polyominoes (1–5 cells: dot, domino, I3, L3, I4, O, L4, J4, T4, S4, Z4, I5,
  big-L5, U5, T5) × their distinct orientations. Built in code in `core/piece_db.gd`, validated by
  tests.
* A **row or column that is completely filled clears**. Several lines clear together; a cell at an
  intersection is counted once.
* **Gravity (rules v2):** after a clear, **every block falls straight down its column** until it
  rests. If the fall completes new lines, they clear too (**chain/cascade**), repeating until
  stable.
* **Scoring** (`core/scoring_manager.gd`, all values in `cfg`): 1 point per placed cell; 10 per
  cleared line; multi-line bonus (2 lines +10, 3 +30, 4 +60, 5 +100, …); **combo multiplier**
  +0.5 per consecutive clearing move (capped at combo 8 → ×4.5); +100 for emptying the board. The
  best score is saved.
* **Game over** only when **no remaining tray piece fits anywhere** (`core/death_detector.gd`). The
  tray refills when all three pieces are used.
* **Shooting (rules v2):** **stone blocks** (colour 9) are pre-placed obstacles that block your
  lines and cannot be moved. **Tap once → cracked (free), tap again → destroyed (costs one
  charge).** 5 charges in level/daily games, 3 in endless. A destroyed stone does **not** make the
  blocks above it fall.
* **Boosters** (`GameSession.BOOSTER_CFG`, 3 per game each): **Hammer** removes one block (no
  gravity afterwards); **Refresh** deals a brand-new tray; **Shuffle** re-rolls only the unused
  pieces. They come from the inventory, from coins (150 / 100 / 80) or from a rewarded ad.
  **Continue** after game over (rewarded ad or 200 coins) clears the two fullest rows.

## 4. Game modes & flow

Launch: **game logo → studio name/logo → loading screen (real load steps + tips) → Home**
(`ui/screens/splash.gd`; tap skips logo/studio). Studio name, tagline and game title come from
`config/app.json` (`MILO | FOUNDERS`, *Block Falling Blast*).

Home (`ui/screens/home.gd`): logo, **day-streak** pill, **Play Adventure**, **Play Classic**, and a
`Settings` / `Quit` row (Quit hidden on Web). Everything else lives in the `•••` menu:
Daily Challenge, Shop, Events, Season Pass, Leaderboard, Profile, Inventory, Achievements,
Support and Feedback.

* **Adventure** (`ui/screens/adventure.gd`) — the current level, how to complete it, overall progress
  and the chapter map. **100 levels** = 10 chapters × 10 (`data/chapters.json`). Each level has a
  score target, 3-star thresholds (1× / 1.4× / 1.9× target), a restricted piece pool, a difficulty
  value and a seeded starting layout (gravity-settled stone stacks with one empty column, so a level
  never starts with a completed line). A level unlocks when the previous one has ≥ 1 star; a
  chapter unlocks when the last level of the previous chapter has ≥ 1 star. The first clear pays
  coins.
* **Classic / Endless** — play until stuck. The run is auto-saved, so "Continue" restores the exact
  board, tray, score and RNG state.
* **Daily Challenge** — date-seeded, identical for everyone that day; target from `data/meta.json`,
  reward 120 coins + 5 gems.

**19 screens**, all built in code: splash, home, game (with pause and game-over dialogs), adventure,
levels, level complete, daily, season, events, shop, inventory (currency + boosters), leaderboard,
profile, achievements, settings, language, privacy, terms, support/feedback. Every screen handles
Android back / Escape.

## 4b. Engagement systems (original design)

Combo multiplier with popups ("COMBO x3", "DOUBLE!", "TRIPLE!", "PERFECT CLEAR!"), particles,
haptics, procedurally synthesised SFX; stars and chapter unlocks; daily challenge; **streak**
counter (a whole missed day breaks it); season pass with 10 XP tiers (400 XP each); 3 time-boxed
events with progress bars; 6 achievements; coin/gem economy; rewarded-ad options (continue, free
booster, free coins); ad-consent prompt and frequency-capped interstitials.

## 5. Code architecture

```
core/       PURE logic (no nodes, no platform calls) — fully unit-tested
  piece_db.gd             42-piece database + validation
  board.gd                8x8 grid (PackedInt32Array), place/can_place/full rows & cols
  placement_validator.gd  all legal positions, snap-to-grid for dragging
  line_clear_manager.gd   detect / clear / preview / gravity / resolve (cascade) + fall list
  scoring_manager.gd      points, combo, bonuses (configurable)
  death_detector.gd       game-over test
  board_evaluator.gd      heuristics: holes, roughness, near-complete lines, fit score
  move_solver.gd          enumerate moves, best move, "can the whole tray still be played?"
  algorithms.gd           10 piece-selection strategies + entropy tray + simple death
  difficulty_manager.gd   weights strategies by difficulty and board fullness
  piece_generator.gd      SEEDED tray generator, guarantees a playable tray when possible
  level_db.gd             builds level/daily configs from JSON (+ stack layouts)
  game_session.gd         one game: board, tray, scoring, boosters, shooting, goal/stars,
                          continue, event log, save/restore
autoload/   singletons (adapters between game and platform/network)
  platform.gd             which OS/export we are on; vibrate, fullscreen, window fitting
  save_manager.gd         local save (see §8)
  audio_manager.gd        synthesised SFX + music loop (no audio files)
  game_state.gd           progression, economy, streaks, daily, season, events, achievements,
                          the active session
  ads_service.gd          ads abstraction (test mode / Android plugin / fallback)
  billing_service.gd      in-app purchases abstraction (+ server verification)
  notification_service.gd reminders abstraction (Android plugin; no-op elsewhere)
  backend_service.gd      Supabase client (auth, leaderboard, cloud save, profile, feedback,
                          score submit)
ui/         presentation only
  main.tscn / main.gd     screen manager, transitions (tween, non-coroutine `go()`), animated
                          background, toasts, back button
  screen.gd               base class: centered responsive column, page header, cards, dialogs
  ui_kit.gd               themes (dark/light), styled buttons/labels/panels, block palette, art
  board_view.gd           board + tray drawing, drag & drop, snap preview, animations (pop, clear
                          flash, gravity fall, particles, popups, cracks)
  i18n.gd                 translations (English is the key)
  logo.gd, currency_bar.gd, stars_display.gd, streak_chip.gd, shots_chip.gd, switch.gd
  screens/*.gd            19 screens
data/       chapters.json (10 chapters), meta.json (season, events, achievements, shop, daily),
            lang/*.json (16 languages)
config/     ads.json, billing.json, backend.json (URL + anon key only), app.json
assets/     app_icon.png, ui/*.png (gem blocks, buttons, toggles, icons)
tests/      unit tests, UI smoke test, UI crawler, back-button crawler, dev screenshot tools
```

**Golden rules:** `core/` never touches nodes/OS; UI calls `GameSession`, never the reverse.
Platform differences live only in the autoload adapters. Input is mouse events everywhere (Android
touch is emulated by the engine), so one code path serves all platforms.

## 6. Piece-generation "algorithms" (original implementations)

The tray is generated per slot by choosing one strategy; the weights depend on the difficulty (0–1)
and on how full the board is (`DifficultyManager`, `Algorithms`, `PieceGenerator`):
`can_put` (anything that fits) · `clear` (piece that completes lines) · `score` (highest immediate
score) · `deal_death_state` (when the board is crowded, deal the piece with most room) ·
`hole_max_diff` (removes the most holes) · `avoid_clear_board` · `new_clear_board` ·
`random_no_die` (weighted random but playable) · `fill_sort` / `fill_weight` (snug-fit ranking /
weighted) · `entropy3_medium` (a tray with medium shape variety) · `simple_death`.
Near-full boards get more help, low fill gets more variety. The generator is **seeded**
(`RandomNumberGenerator`), so a seed plus a move list reproduces a game exactly.

## 7. Input (how the game feels)

`BoardView._gui_input`: pressing a tray slot starts a drag; the piece floats ~1.7 cells above the
pointer so the finger does not hide it; `PlacementValidator.snap()` finds the nearest legal anchor;
a ghost piece plus highlighted would-clear lines preview the result; releasing on a legal spot calls
`GameSession.place()` (animation, sound, haptics); releasing elsewhere shakes the board and slides
the piece back. Tapping a stone block shoots it (crack → destroy). Hammer mode turns board taps
into single-block removals.

## 8. Saving

`user://save.json` (IndexedDB on Web): `{version, data:<json string>, sig:sha256(salt+version+data)}`.
Writes go through a temp file; the previous file is kept as `save.bak.json`. On corruption or a
failed checksum the backup is loaded, otherwise the defaults are used, and the player is told with a
toast. `migrate()` merges missing default keys (forward compatible). Autosave is debounced (2 s) and
runs on pause/close. The checksum only deters casual editing — authoritative validation happens on
the server.

## 9. Online backend (Supabase) — client only, never deployed

`autoload/backend_service.gd` speaks the Supabase REST + Edge Function API using **only** the public
anon key and the signed-in user's JWT. With `config/backend.json` empty (the default) the service
reports `is_configured() == false` and every call fails gracefully; the game is fully playable
offline.

Expected Edge Functions: `validate-score` (replays the client's event log with the server copy of
the rules, **rules version 2**, recomputes the score, rejects illegal moves / impossible boosters /
mismatches, rate-limits, and ranks only endless runs), `leaderboard`, `cloud-save`, `profile`,
`daily-challenge`, `rewards`. **The server-side code (SQL migrations, `_shared/game.ts`, the
functions) is not part of this repository** — see `SUPABASE_SETUP.md` for the contract and the steps
needed to create and deploy it.

## 10. Ads, purchases, notifications

Abstractions with **test modes** and graceful fallback: rewarded ads (continue, booster, coins),
interstitials only at game over / level end (frequency-capped: ≥ 180 s and ≥ 3 games apart, never
mid-game, never after "Remove Ads"), banner support, and an ad-consent prompt. Purchases are granted
**only after server verification** (debug-build test mode excepted). Reminders use an Android
plugin; every other platform is a safe no-op. The real Android SDK adapters are stubs awaiting
plugins and IDs — see `ADS_SETUP.md` and `BILLING_SETUP.md`. Home-screen widgets are not implemented
(they need native Kotlin code).

## 11. Testing & verification status

* **54 unit tests / 1146 assertions, 0 failures** (`tests/run_tests.gd`, verified on Godot 4.7.2):
  grid, 42 pieces, placement, clears, intersections, gravity and chain clears, scoring and combos,
  death detection, solver, seeded determinism, every algorithm family, difficulty manager, boosters
  (hammer/refresh/shuffle/limits/continue), **shooting (crack → destroy, charge limits, gravity
  after a destroy, save round-trip, every level starts with stone)**, levels/stars/unlocks, streaks,
  season/events/achievements, save round trip / corruption / tamper / migration, run resume, and a
  UI smoke test with a real drag-and-drop.
* **UI crawler** (`tests/crawl_ui.gd`): **18 screens, 1211 button presses, 0 script errors**;
  **back-button crawler** (`tests/crawl_back.gd`): **18 screens, no errors** — every screen
  navigates back correctly (levels → adventure, language/privacy/terms → settings,
  achievements → profile, everything else → home).
* **Exports:** Windows and Web exports were built from this code base on 2026-11-16 and played
  (drag & drop works); the Android debug APK was built and signed but **never run on a device**; no
  release AAB exists. Current status per platform is listed in `EXPORT_GUIDE.md` and
  `FEATURES_CHECKLIST.md`.
* Async hygiene: every call to a coroutine is either awaited or deliberately fire-and-forget through
  `call_deferred` (`Main.go()` is not a coroutine).

## 12. Known limits / not done

Real ads/billing/push SDKs (need plugins and accounts) · home-screen widgets · the Supabase server
code (not in this repo, never deployed) · server daily challenge not wired into gameplay ·
season/event tables not read from the server · audio is synthesised, not recorded music · only the
sliced UI art set (no background art, board frame, medals or FX) · Android never run on real
hardware (touch, safe areas, performance unverified) · balance never play-tested by humans ·
`restore()` for non-consumable purchases is a stub.

## 13. Documentation map

`CLAUDE.md` (Claude Code manual) · `AGENTS.md` (permanent rules) · `ARCHITECTURE.md` ·
`FEATURES_CHECKLIST.md` · `TESTING.md` · `EXPORT_GUIDE.md` · `SUPABASE_SETUP.md` ·
`ADS_SETUP.md` · `BILLING_SETUP.md` · `DEVELOPMENT_PLAN.md` · `CHANGELOG.md` ·
`NEXT_LEVEL_PROMPT.md`.
