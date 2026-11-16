# Prompt to take this project to the next level

Copy everything below the line into Claude Code (run it inside the repository root) or into ChatGPT
together with `README.md`.

---

You are the lead Godot 4 developer on **Block Falling Blast**, an original 8×8 gravity block-puzzle
game (typed GDScript, Godot 4.7.2) with one codebase for Android (primary), Windows and Web, and an
optional Supabase backend.

**The repository root is the Godot project root** — `project.godot`, `core/`, `ui/`, `autoload/`,
`data/`, `config/`, `assets/`, `tests/` are all at the top level. There is no `godot/` subfolder and
no `supabase/` folder in the repo.

**First read, in order:** `CLAUDE.md`, `AGENTS.md` (permanent rules — obey them), `README.md`,
`ARCHITECTURE.md`, `FEATURES_CHECKLIST.md`, `CHANGELOG.md`. Then confirm the baseline:
```
godot --headless --path . --import
godot --headless --path . -s res://tests/run_tests.gd        # expected: 54 tests, 0 failed, 1146 assertions
godot --headless --path . -s res://tests/crawl_ui.gd         # expected: 18 screens, ~1200 presses, 0 SCRIPT ERROR
godot --headless --path . -s res://tests/crawl_back.gd      # expected: 18 screens, no errors
```
Godot console binary on this machine:
`C:\Users\This PC\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`

**Hard rules**
1. Everything must be original. Do not copy code, art, audio, names or branding from any other game
   or store app, and never port/obfuscate somebody else's app.
2. Keep `core/` pure (no nodes, no `OS`, no autoloads, no file I/O). Platform code only in
   `autoload/`. One codebase — never fork per platform.
3. If you change scoring / pieces / board / gravity / clears / boosters / shooting, bump the **rules
   version** (currently `2`) in `BackendService.submit_score`, keep the server copy of the rules in
   sync, regenerate logs with `tests/gen_logs.gd` and re-run the server replay cross-check.
4. Never fake features, never claim something works until you ran it. Update
   `FEATURES_CHECKLIST.md` + `CHANGELOG.md` after each stage. No secrets in the client (only the
   Supabase URL + anon key).
5. After every change: run `run_tests.gd` and grep the output for `SCRIPT ERROR`; for UI work run
   `tests/crawl_ui.gd` and look at real screenshots (`tests/shot.gd` pattern). Every coroutine call
   must be awaited or `call_deferred`.

**Work plan (do in this order, test after each, keep going without asking for routine permission)**
1. **Re-verify the exports with the current code.** The artifacts in `build/` were produced on
   2026-11-16, shortly before the last UI tweaks: rebuild both (`--export-release "Windows Desktop"`
   / `"Web"`), run the Windows exe, play the Web build in a browser, and fix what breaks.
2. **Real-device Android:** install the debug APK (`adb install -r build/android/BlockFallingBlast-debug.apk`)
   on a device/emulator; fix touch, safe-area/notch, back button and performance (target 60 FPS on
   4 GB phones); profile `BoardView._draw` and reduce allocations if needed. Build a signed release
   **AAB** (Gradle build; document keystore handling, never commit it) and replace the placeholder
   package id `com.example.blockfallingblast`.
3. **Write the Supabase server side** (it is missing): migrations + RLS, the six Edge Functions
   (`validate-score`, `leaderboard`, `cloud-save`, `profile`, `daily-challenge`, `rewards`) and the
   TypeScript copy of the rules (`_shared/game.ts`, rules version 2). The exact contract the client
   expects is in `SUPABASE_SETUP.md`. Then test sign-up/guest, leaderboard, cloud-save merge and
   score validation (replay) end to end; wire the server daily challenge into gameplay and read
   seasons/events from the tables with offline fallback; add a reward-history screen.
4. **Game feel & balance:** play-test gravity + chain clears + the shooting economy; tune
   `ScoringManager.cfg`, the level targets in `data/chapters.json` and the difficulty curve so the
   100 Adventure levels feel fair; add unit tests for every tuning change.
5. **Original art & audio pass:** extend the sliced UI art (background panel, board frame, medals,
   ribbons, FX), add per-chapter backgrounds and recorded/composed music loaded from `res://assets/`,
   keep the procedural fallback, and add 2–3 unlockable block skins/themes.
6. **Monetization:** integrate a real Godot 4 Android ads plugin (own AdMob IDs, UMP consent) and
   Google Play Billing with server verification (`rewards` function + Play service account);
   implement `BillingService.restore()`; keep the test modes and fallbacks.
7. **Retention & platform extras:** real local/push notifications (daily challenge, streak), an
   Android home-screen widget (native Kotlin `AppWidgetProvider` via the Gradle build) showing
   streak/daily status, accessibility (colour-blind-safe palette option, larger text),
   analytics/crash reporting (privacy-compliant), and a CI workflow for the Android build.
8. **Release:** store listings checklist, real privacy policy/terms (replace the templates), web
   hosting guide, Windows code-signing notes, final regression: unit tests + crawlers + all three
   exports (Windows run, Web browser run, Android device run).

**Deliverable after each stage:** what changed, tests added/passed (with numbers), what was verified
on which platform, what is still unverified, and the exact remaining external requirements
(accounts, keys, devices).
