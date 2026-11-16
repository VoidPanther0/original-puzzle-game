# Features checklist

Legend: ✅ implemented **and tested** · 🟡 implemented, only partly/indirectly tested ·
🔧 implemented but needs an external SDK/account, untested · ❌ not implemented

## Gameplay
- ✅ 8×8 board, 64 addressable cells, occupancy
- ✅ 3-piece tray, refill after 3 used; 42-piece independent database (1–5 cells), validated
- ✅ Drag & drop (mouse; touch via emulation), pointer-follow, snap, line-clear preview,
  invalid-drop feedback (shake + return)
- ✅ Row/column/simultaneous clears, intersections counted once; clear animations, particles,
  popups, SFX
- ✅ Scoring: placement, line, multi-line, combo, perfect clear; configurable; best score persisted
- ✅ Game over = no placement possible for any remaining piece; continue (coins/ad)
- ✅ Seeded deterministic generation; all 10 selector families + entropy tray + simple death;
  difficulty manager
- ✅ **Shooting stone blocks:** 1st tap cracks, 2nd tap destroys (1 charge), limited charges per
  game (5 level/daily, 3 endless), charge only spent on the destroy, no gravity after a destroy,
  shot state survives save/restore, every level starts with stone
- ✅ Boosters: hammer, refresh, shuffle; inventory, costs, per-game limits, configurable;
  animations
- 🟡 Rotation/mirroring: intentionally not supported (fixed-orientation pieces)
- 🟡 Algorithms are independent interpretations, not the original ones (original unknown)
- 🟡 Balance never play-tested by humans; targets in `data/chapters.json` are untuned guesses

## Launch flow & Home
- ✅ Logo → studio → loading → Home; Adventure (100 levels), Classic/Endless, Settings, Quit,
  day-streak pill
- ❌ Original game's art/audio/branding: intentionally not used (copyrighted by its owner)

## Screens (all reachable and functional)
- ✅/🟡 19 screens built in code: splash, home, game (+ pause / game-over dialogs), adventure,
  levels, level complete, daily, season, events, shop, inventory, leaderboard, profile,
  achievements, settings, language, privacy, terms, support — all load, core flows exercised by the
  crawlers (18 screens, 1211 button presses, 0 script errors). Visual polish checked on
  screenshots, not on a real phone.
- 🟡 Languages: 16 languages (`en`, `hi`, `ja`, `zh`, `es`, `fr`, `de`, `pt`, `ru`, `ko`, `ar`,
  `it`, `tr`, `id`, `vi`, `pl`) with a growing key set (57-91 keys depending on how far the
  translation has progressed); English is the key and the fallback
- 🟡 Gem/button/icon art from an original reference sheet (screenshot-checked at 450×800 dark theme
  only; light theme, desktop sizes and Android untested). Not used yet: background panel, board
  frame, medals, ribbons, shield/crown, sparkle FX
- ✅ Light/dark theme; portrait + wide-window responsive layout
- ✅ Ad-consent prompt on first launch

## Progression & save
- ✅ 10 chapters × 10 levels (JSON-driven, seeded start layouts, piece pools, difficulty scaling,
  stars, unlocks) — 100 levels
- ✅ Daily challenge (local, date-seeded) + streaks; season pass tiers; events; achievements
- ✅ Local save: versioned, checksummed, backup recovery, autosave, run resume
- 🟡 Level/season/event numbers are independent placeholders, not recovered original data

## Backend (Supabase)
- 🟡 Client (`autoload/backend_service.gd`): auth, profile, cloud push/merge, leaderboard,
  feedback, score submit — code complete, untested against a live project, and **not configured**
  (`config/backend.json` is empty, so every call fails gracefully and the game stays offline)
- ❌ Server side is **not in this repository**: SQL migrations, `_shared/game.ts` and the six Edge
  Functions (`leaderboard`, `cloud-save`, `profile`, `daily-challenge`, `rewards`, `validate-score`)
  still have to be written/deployed — see `SUPABASE_SETUP.md` for the contract
- ❌ Server daily challenge not wired into gameplay; season/event tables not read by the client;
  reward-history UI not built
- 🟡 Score-replay logic was cross-checked against real GDScript game logs in an earlier build
  (21/21 identical); that check cannot be repeated until the server code exists again

## Ads / billing / notifications
- ✅ Ad abstraction, test mode, consent, frequency caps, graceful fallback
- 🔧 Real Android ad SDK adapter (needs plugin + IDs) — see `ADS_SETUP.md`
- ✅ Billing abstraction, debug-only test mode, verification pipeline written
- 🔧 Play Billing adapter + live verification (needs plugin, Play Console, service account) —
  see `BILLING_SETUP.md`
- 🔧 Push/daily/streak reminder scheduling adapter (needs plugin)
- ❌ `BillingService.restore()` for non-consumables (stub only)
- ❌ Android home-screen widgets (needs native Kotlin AppWidgetProvider)

## Platforms
- ✅ One project, three export presets (Android, Windows Desktop, Web)
- ✅ Windows exe built (2026-11-16) and run; ✅ Web built (2026-11-16) and run in a browser
- 🟡 Android debug APK built + signed, **not run on a device**; ❌ release AAB not built;
  ❌ package id still the placeholder `com.example.blockfallingblast`
- ❌ Real-device performance profiling (design choices only: idle `_process` off, throttled
  background, no per-frame allocations in hot paths)
- 🟡 Haptics (Android only, untested); audio is procedural synth tones (no recorded assets)
- ❌ CI / build workflow (the GitHub Actions Android workflow was removed in the rebrand)
