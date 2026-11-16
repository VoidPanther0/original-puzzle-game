# Testing

## Automated (headless)

```bash
godot --headless --path . --import          # once, to register class_name scripts
godot --headless --path . -s res://tests/run_tests.gd
```

The runner exits with code 1 on failure and prints `TESTS: N run, N failed, N assertions`.
It picks up every `res://tests/test_*.gd` file automatically and runs each `test_*` method on a
fresh instance.

**Coverage:** grid init, 42-piece validity, placement/invalid placement, row/column/simultaneous
clears and intersection (counted once), preview purity, gravity compaction and row/column drops,
chain clears, session gravity and scoring, settled level layouts, combo scoring, death detection
(incl. no false game-over), move solver, seeded determinism, tray playability on random boards,
pool restriction, every algorithm family, difficulty manager, board evaluator, boosters
(hammer/refresh/shuffle/limits/config override/continue), **shooting** (only stone is shootable,
crack → destroy, charge limits, no gravity after a destroy, hammer does not make blocks fall, shot
state survives a save round-trip, every level starts with stone), level goals and stars, event log,
save round trip, corruption recovery from backup, tamper detection, migration, currency and booster
inventory, level progression and unlocks, streaks and best score, season/events/achievements, run
save/resume incl. RNG state, and a UI smoke test that boots `main.tscn`, builds every screen
(17 screens in the smoke test, game and level-complete in the play-through test), switches theme
and language, plays moves and performs a real drag-and-drop through `BoardView`.

**Last result (Godot 4.7.2, 2026-11-16): 54 tests, 0 failed, 1146 assertions.**
The "Parse JSON failed" console line is the intentional corrupt-save test. The runner cannot see
engine `SCRIPT ERROR` lines as failures — **grep the output for `SCRIPT ERROR`** too.

## UI crawlers

```bash
godot --headless --path . -s res://tests/crawl_ui.gd    # every screen, every button/toggle/dialog
godot --headless --path . -s res://tests/crawl_back.gd  # Android-back / Escape on every screen
```

`crawl_ui.gd` opens each screen, presses every visible button, switch and slider, presses the
buttons of any dialog that opens, then goes Back and repeats. Both crawlers point the save system
at `user://crawl_save.json`, so the real save is never touched. After the run, grep the output for
`SCRIPT ERROR` — there must be none.

**Last result (Godot 4.7.2, 2026-11-16): `CRAWL: 18 screens, 1211 button presses`, 0 script errors**
(`crawl_ui.gd`) and **`BACK TEST: 18 screens, no errors`** (`crawl_back.gd`). The crawler visits
every screen except the splash screen and ends with the back handler on each of them.

## Server-rule cross-check (needs the backend code)

`tests/gen_logs.gd` plays seeded games (with hammers, refresh, shuffle, continue, shots) and dumps
event logs. The matching replay script (`crosscheck_replay.mjs`, Node ≥ 22.6
`--experimental-strip-types`) lives in the backend repository, which is **not part of this
repository** — see `SUPABASE_SETUP.md`. When the server side is available:

```bash
LOGS_OUT=logs.jsonl godot --headless --path . -s res://tests/gen_logs.gd
LOGS_OUT=logs.jsonl node --experimental-strip-types <backend>/tests/crosscheck_replay.mjs
```

## Manual / export verification (what was really done)

* Windows release exe: built and launched (clean exit, save file written).
* Web release build: served over HTTP, loaded in a browser, consent → Play → drag a piece onto the
  board → score/moves updated.
* Android debug APK: built and signed, manifest inspected. **Not installed or run** (no
  device/emulator) — touch, safe areas and performance are therefore unverified.
* Screens were visually checked via the `tests/shot*.gd` screenshot tools.

## Not tested

Supabase functions (no project; the server code is not in this repository), Google Play
billing/verification, any real ad SDK, push notifications, widgets, performance on a real low-end
phone, audio quality, gamepad/keyboard play (pointer only), and human play-testing of the balance.
