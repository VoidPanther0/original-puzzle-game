# CLAUDE.md

Operating manual for Claude Code working in this repository.
`AGENTS.md` holds the permanent rules and has priority over anything written here.

## Project

**Block Falling Blast** — an original 8×8 block-puzzle game with gravity.
Godot **4.7.2**, typed GDScript, GL Compatibility renderer. One codebase, three targets:
Android (primary), Windows Desktop, Web. Supabase is optional and **not configured** (the client
code exists, the server code is not in this repository).

The **repository root is the Godot project root** — `project.godot`, `core/`, `ui/`, `autoload/`,
`data/`, `config/`, `assets/`, `tests/` are all at the top level. Commands use `--path .`
(there is no `godot/` subfolder).

## Golden rules

1. `core/` is pure logic — no nodes, no `OS`, no autoloads, no file I/O. It must stay headless
   testable.
2. Platform differences live only in `autoload/`. The UI never calls `OS.*` directly; it asks
   `Platform`.
3. UI → `GameSession` → result dict → UI animates. The UI never writes to `Board` directly.
4. Every `await` call must be awaited or deliberately deferred (`call_deferred`).
5. Rule changes (scoring, pieces, board, gravity, boosters, shooting) bump the **rules version**
   (currently `2`) in `BackendService.submit_score` and are logged in `CHANGELOG.md`.
6. Never claim a feature works unless you ran it. Never claim an APK/AAB/exe exists unless the
   export succeeded.
7. No secrets in the client — only the Supabase URL and anon key.
8. Do not port to another engine. Godot + GDScript only.

## Commands

```bash
godot --headless --path . --import                      # once, to register class_name scripts
godot --headless --path . -s res://tests/run_tests.gd   # unit tests  -> "TESTS: N run, 0 failed, M assertions"
godot --headless --path . -s res://tests/crawl_ui.gd    # opens every screen, presses every button
godot --headless --path . -s res://tests/crawl_back.gd  # Android back on every screen
godot --path .                                          # play
```

Windows console binary used on this machine:
`C:\Users\This PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

The test runner does **not** treat engine `SCRIPT ERROR` lines as failures — grep the output for
`SCRIPT ERROR` as well.

## Architecture in one screen

```
core/   (pure)  board.gd  piece_db.gd  placement_validator.gd  line_clear_manager.gd
                scoring_manager.gd  death_detector.gd  board_evaluator.gd  move_solver.gd
                algorithms.gd  difficulty_manager.gd  piece_generator.gd  level_db.gd
                game_session.gd
autoload/       Platform  SaveManager  AudioManager  GameState
                AdsService  BillingService  NotificationService  BackendService
ui/             main.tscn + main.gd (screen manager)  screen.gd (base)  ui_kit.gd  i18n.gd
                board_view.gd  logo.gd  currency_bar.gd  stars_display.gd  streak_chip.gd
                shots_chip.gd  switch.gd  screens/*.gd (19)
data/           chapters.json (10 chapters x 10 levels)  meta.json (season/events/achievements/shop/daily)
                lang/<code>.json (16 languages, 57-91 keys depending on translation progress; English is the key)
config/         ads.json  app.json  backend.json  billing.json
```

Read flow: `BoardView` (input) → `GameSession.place()` → `LineClearManager` + `ScoringManager`
→ result dictionary → `GameState.on_move()` (stats + autosave) → UI animates.

## Game rules (must match the code)

* 8×8 board, tray of 3 pieces, **no rotation**, 42 pieces = 15 base polyominoes (1–5 cells) ×
  distinct orientations.
* A full **row or column** clears; several lines clear together, an intersection counts once.
* **Gravity v2:** after a clear every block falls straight down its column; a fall that completes
  lines chains until stable. Level layouts are gravity-settled stacks with one empty column.
* Scoring: 1/cell + 10/line + multi-line bonus (2 lines +10, 3 +30, 4 +60, …) × combo multiplier
  (+0.5 per consecutive clearing move, capped at combo 8) + 100 for emptying the board.
* **Game over** only when no remaining tray piece fits anywhere.
* **Shooting (rules v2):** stone blocks (colour 9) are level obstacles. Tap once → cracked (free),
  tap again → destroyed (costs 1 charge). 5 charges in level/daily, 3 in endless. A destroyed
  stone does **not** make blocks above it fall.
* **Boosters** (3 per game each): hammer (removes one block, no gravity), refresh (new tray),
  shuffle (re-rolls unused pieces). Continue after game over clears the two fullest rows.

## Style

Tabs, `snake_case` functions, typed GDScript, one `##` header comment per file explaining what it
owns, screens built in code (no hand-placed `.tscn` layouts), data-driven numbers in
`config/*.json` and `data/*.json`.

## Working agreement

* After every change: run `run_tests.gd`, grep for `SCRIPT ERROR`, and for UI work run
  `crawl_ui.gd` and look at a real screenshot (`tests/shot.gd` pattern).
* Add a unit test for every rule or tuning change; the suite must stay at 0 failures.
* Update `FEATURES_CHECKLIST.md` and `CHANGELOG.md` in the same change.
* Deliverable per stage: what changed, tests added/passed (with numbers), what was verified on
  which platform, what is still unverified, and the exact external requirements left
  (accounts, keys, devices).
