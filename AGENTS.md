# AGENTS.md — permanent rules for this repository

Read this before touching anything. It applies to every agent (Claude Code, OpenCode, Codex, …) and to
every human contributor. `CLAUDE.md` is the short version of this file for Claude Code specifically.

## 1. What this project is

**Block Falling Blast** — an original 8×8 block puzzle game with gravity, written in **Godot 4.7.2 /
typed GDScript** (GL Compatibility renderer). One codebase exports to **Android (primary)**,
**Windows Desktop** and **Web**. Supabase is an optional online backend.

* The **repository root is the Godot project root** (`project.godot` lives here). There is no `godot/`
  subfolder and no `supabase/` folder in this repository.
* Everything here is **original work**. Do not copy code, art, audio, names or branding from any
  other game, APK or store listing. Game *ideas* are fine, copying is not.

## 2. Hard rules

1. **Never fake a feature.** Never claim something works unless you actually ran it. If a feature is
   untested, say so in `FEATURES_CHECKLIST.md` with the ❌/🟡 marker.
2. **`core/` stays pure.** No `Node`, no `OS.*`, no `Input`, no `Time`, no autoload access, no file
   I/O, no animations. `core/` is `RefCounted` logic only and must stay unit-testable headless.
3. **Platform differences live only in `autoload/`.** One codebase, never a per-platform fork. The UI
   never calls `OS` directly — it asks `Platform`.
4. **UI never mutates game state directly.** UI → `GameSession` → result dictionary → UI animates.
   The UI may not write to `Board` except through a session API call.
5. **Rules changes are a breaking change.** If you touch scoring, pieces, board size, gravity, clears,
   boosters or the shooting system, bump the **rules version** (currently `2`) in
   `BackendService.submit_score` and keep the server copy in sync. Log the change in `CHANGELOG.md`.
6. **Every coroutine call must be awaited or explicitly fire-and-forget** (`call_deferred`). Calling
   an `await` function without `await` is a runtime error in GDScript.
7. **No secrets in the client.** Only the Supabase project URL and the anon/publishable key may ever
   live in `config/backend.json`. The service-role key belongs on the server only.
8. **Never commit** `build/`, keystores, `export_credentials.cfg`, `.env` or personal files.
   (`.gitignore` already covers these — keep it that way.)
9. **Never claim an APK/AAB/exe exists unless the export actually succeeded.** Check `build/`.
10. **Do not port the game to another engine or framework.** Godot + GDScript only. No C#, no React,
    no HTML rewrite, no Kotlin port.

## 3. Layout (quick map)

```
core/        pure logic — board, pieces, placement, clears, gravity, scoring, death detection,
             move solving, generation algorithms, difficulty, levels, one game session
autoload/    8 singletons — Platform, SaveManager, AudioManager, GameState, AdsService,
             BillingService, NotificationService, BackendService
ui/          screen manager (main.tscn/main.gd), Screen base, UIKit, I18n, BoardView, chips,
             screens/*.gd (19 screens, all built in code)
data/        chapters.json, meta.json, lang/*.json (16 languages)
config/      ads.json, app.json, backend.json, billing.json
assets/      app_icon.png + ui/*.png (blocks, buttons, icons)
tests/       run_tests.gd + test_*.gd (headless), crawl_ui.gd / crawl_back.gd, shot*.gd, gen_logs.gd
```

## 4. Commands

```
godot --headless --path . --import                      # once, registers class_name scripts
godot --headless --path . -s res://tests/run_tests.gd   # unit tests (must be 0 failures)
godot --headless --path . -s res://tests/crawl_ui.gd    # presses every button on every screen
godot --headless --path . -s res://tests/crawl_back.gd  # Android-back on every screen
godot --path .                                          # play
```

On Windows use the `_console` build so the output is visible. The one used on this machine is
`C:\Users\This PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
The runner cannot see engine `SCRIPT ERROR` lines as failures — **grep the output for
`SCRIPT ERROR`** as well.

## 5. Code style

* **Tabs** for indentation, `snake_case` for functions/variables, `PascalCase` for classes.
* **Typed GDScript** everywhere: `func f(x: int) -> void:`, `var v: String = ""`.
* One `##` doc comment at the top of every file explaining what it owns.
* `class_name` only for genuinely global types (`Board`, `GameSession`, `I18n`, `UIKit`, …).
* Screens are **built in code** — no hand-placed `.tscn` layouts.
* Comments explain *why*, not *what*. Do not add banner comments to every function.
* Prefer data-driven configuration (`config/*.json`, `data/*.json`) over hard-coded values when the
  value is a balance or catalogue number.

## 6. Definition of done for a change

1. `run_tests.gd` passes (0 failed) and the output has no `SCRIPT ERROR`.
2. New behaviour has a unit test in `tests/test_*.gd` (rule changes) or a crawler/screenshot check
   (UI changes).
3. `FEATURES_CHECKLIST.md` and `CHANGELOG.md` are updated.
4. Nothing outside `core/` was made node-dependent, and no platform code leaked into `core/`.
5. If the change is user-visible, the affected screen still works at 450 px width (phone) and on a
   desktop window.

## 7. Documentation map

| File | Purpose |
|---|---|
| `README.md` | Full project guide: game, rules, architecture, status |
| `CLAUDE.md` | Operating manual for Claude Code in this repo |
| `AGENTS.md` | This file — permanent rules |
| `ARCHITECTURE.md` | Directory map, data flow, rules, adapters, persistence |
| `FEATURES_CHECKLIST.md` | Per-feature status: tested / untested / not implemented |
| `TESTING.md` | How to run the tests, what they cover, what was really run |
| `EXPORT_GUIDE.md` | Export presets, per-platform notes |
| `SUPABASE_SETUP.md` | Backend contract and deployment steps |
| `BILLING_SETUP.md` | In-app purchase setup |
| `ADS_SETUP.md` | Ad SDK setup |
| `DEVELOPMENT_PLAN.md` | Stages, priorities, what is still missing |
| `CHANGELOG.md` | History of the project |
| `NEXT_LEVEL_PROMPT.md` | Ready-made prompt to continue development |
