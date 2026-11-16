# Development plan

Strategy (fixed): Android first, Windows + Web alongside, one GDScript codebase, platform adapters
for ads / billing / notifications / storage. The repository root **is** the Godot project.

## Status per stage

| Stage | State | Notes |
|---|---|---|
| 1. Project + core architecture | ✅ | 14 pure-logic scripts in `core/`, fully unit-tested |
| 2. 8×8 gameplay | ✅ | board, 42 pieces, validator, clears, gravity, scoring, death detection |
| 3. Algorithms + boosters | ✅ | 10 selector families + entropy tray + difficulty manager, seeded generator, hammer / refresh / shuffle / continue, shooting stone blocks |
| 4. UI + screens | ✅ | 19 code-built screens, dark/light theme, i18n, procedural audio, particles/popups |
| 5. Progression + save | ✅ | 10 chapters × 10 levels, daily, streak, season, events, achievements, versioned checksummed save with backup recovery and run resume |
| 6. Supabase | 🟡 | client complete; **server code missing** and nothing deployed |
| 7. Ads + billing | 🟡 | abstractions, test modes and fallbacks done; real SDKs external |
| 8. Platform configs | 🟡 | 3 export presets done; Android never run on a device, no release AAB |
| 9. Test / debug / optimise | 🟡 | 54 automated tests + UI crawlers; no device profiling, no CI |
| 10. Documentation | ✅ | README, CLAUDE.md, AGENTS.md, ARCHITECTURE, TESTING, EXPORT, SETUP docs, CHECKLIST, CHANGELOG |

## Next steps (in priority order)

1. **Re-verify the exports with the current code.** The artifacts in `build/` were produced on
   2026-11-16, shortly before the last UI tweaks (settings / home / splash): rebuild both, run the
   Windows exe, play the Web build in a browser and fix what breaks.
2. **Real-device Android.** Install the debug APK
   (`adb install -r build/android/BlockFallingBlast-debug.apk`) on a device/emulator; fix touch,
   safe-area/notch, back button and performance (target 60 FPS on 4 GB phones); profile
   `BoardView._draw` and reduce allocations if needed. Then build a signed release **AAB** (Gradle
   build; document the keystore handling, never commit it) and replace the placeholder package id
   `com.example.blockfallingblast`.
3. **Write the Supabase server side.** Migrations + RLS + the six Edge Functions + the TypeScript
   copy of the rules (`_shared/game.ts`, rules version 2), then test sign-up/guest, leaderboard,
   cloud-save merge and score validation (replay) end to end. The contract is documented in
   `SUPABASE_SETUP.md`.
4. **Monetisation.** Integrate a real Godot 4 Android ads plugin (own AdMob IDs, UMP consent) and
   Google Play Billing with server verification; implement `BillingService.restore()`; keep the
   test modes and fallbacks.
5. **Game feel & balance.** Play-test gravity + chain clears + the shooting economy; tune
   `ScoringManager.cfg`, the level targets in `data/chapters.json` and the difficulty curve so the
   100 Adventure levels feel fair; add a unit test for every tuning change.
6. **Art & audio pass.** Extend the sliced UI art (background panel, board frame, medals, ribbons,
   FX), add per-chapter backgrounds and recorded/composed music, keep the procedural fallback.
7. **Retention & platform extras.** Real notifications (daily + streak), an Android home-screen
   widget (native Kotlin `AppWidgetProvider` via the Gradle build), accessibility (colour-blind-safe
   palette, larger text), analytics/crash reporting (privacy-compliant).
8. **Release.** Store listings, real privacy policy/terms (replace the templates), web hosting
   guide, Windows code-signing notes, final regression (unit tests + crawlers + all three exports).

## Known gaps to keep in mind

* No CI workflow (the Android build workflow was dropped in the rebrand) — add one if the project
  gets a public repository.
* No `docs/` content: the markdown documentation lives at the repository root.
* `tests/_dbg.gd` and `tests/shot2.gd` are scratch tools, not part of the test suite.
