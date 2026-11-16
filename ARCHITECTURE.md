# Architecture

```
<repo root> = the Godot project root (project.godot lives here)
  core/        pure logic (RefCounted): Board, PieceDB, PlacementValidator, LineClearManager,
               ScoringManager, DeathDetector, BoardEvaluator, MoveSolver, Algorithms,
               DifficultyManager, PieceGenerator, LevelDB, GameSession
  autoload/    Platform, SaveManager, AudioManager, GameState, AdsService, BillingService,
               NotificationService, BackendService   (singletons; adapters for platform/SDK/network)
  ui/          main.tscn/main.gd (screen manager + animated background), Screen base, UIKit, I18n,
               BoardView, Logo, CurrencyBar, StarsDisplay, StreakChip, ShotsChip, Switch,
               screens/*.gd (19 screens, built in code)
  data/        chapters.json, meta.json (season/events/achievements/shop/daily), lang/*.json (16)
  config/      ads.json, billing.json, backend.json, app.json
  assets/      app_icon.png, ui/*.png (gem blocks, buttons, toggles, icons)
  tests/       run_tests.gd + test_*.gd (headless), crawl_ui.gd + crawl_back.gd,
               shot*.gd + gen_logs.gd (dev tools)
  build/       export output (git-ignored)
```

There is no `godot/` subfolder and no `supabase/` folder in this repository: the Godot project is
the repository, and the backend is only reached over HTTP (see `SUPABASE_SETUP.md`).

## Data flow

UI (`BoardView`) → `GameSession.place()` → `LineClearManager` + `ScoringManager` → result
dictionary → UI animates and `GameState.on_move()` updates stats/autosave. `GameSession.event_log`
records every tray/placement/booster/shot event; `BackendService.submit_score` sends it to
`validate-score`, which is supposed to replay it with the same rules in TypeScript (server code is
not part of this repo — the client sends `rules: 2`).

## Rules (independent design)

* Board 8×8. Pieces are fixed-orientation (no rotation by the player). 42 pieces = 15 base
  polyominoes (1–5 cells) × distinct rotations.
* Score: 1/cell + 10/line + multi-line bonus table + combo multiplier (+0.5 per consecutive
  clearing move, capped ×4.5 at combo 8) + 100 perfect-clear bonus. All in `ScoringManager.cfg`.
* **Gravity (rules v2):** after a clear, blocks fall down their columns
  (`LineClearManager.gravity/resolve`); falls that complete lines chain-clear; all lines in a chain
  count toward the move's line total.
* Game over only when **no remaining tray piece fits anywhere** (`DeathDetector`).
* **Shooting (rules v2):** stone blocks (colour 9) are pre-placed level obstacles. The first shot
  cracks a stone, the second one destroys it and spends one charge (`GameSession.shoot`,
  `GameSession.SHOTS_PER_GAME = 5`, `SHOTS_PER_ENDLESS = 3`). A destroyed stone does **not** move
  the blocks above it. Level start layouts always contain at least 4 stones, so the ability is
  available from level 1.
* Boosters (`GameSession.BOOSTER_CFG`, overridable per session): Hammer removes a block (no
  gravity afterwards); Refresh deals a new 3-piece tray; Shuffle re-rolls unused pieces. Limit
  3/game each. Continue clears the two fullest rows (deterministic tie-break so a server can
  replay it).

## Algorithm families

Names follow the families referenced in the brief; the behaviour is our own interpretation (the
original implementations are unknown and are not reproduced): `can_put`, `clear`, `score`,
`deal_death_state`, `hole_max_diff`, `avoid_clear_board`, `new_clear_board`, `random_no_die`,
`fill_sort`, `fill_weight` (per-piece selectors); `entropy3_medium` (tray-level, targets 0.918 bit
family entropy); `simple_death` (= `DeathDetector`). `DifficultyManager` weights them by difficulty
and board fill; `PieceGenerator` is seeded (`RandomNumberGenerator`) and guarantees a playable tray
whenever any piece fits.

## Persistence

`SaveManager`: `user://save.json` = `{version, data:<json string>, sig:sha256(salt+version+data)}`;
atomic-ish write (tmp → copy), previous file kept as `save.bak.json`; on load failure/tamper it
falls back to backup, then defaults, and flags `recovered`. The checksum deters casual editing
only. `migrate()` merges new default keys (forward compatible); add per-version blocks for breaking
changes. The save also holds the auto-saved endless run (`run`) and the cloud refresh token
(`cloud`).

## Platform adapters

| Concern | Android | Windows | Web |
|---|---|---|---|
| Ads | plugin singleton (adapter stubs, untested) | unavailable (test overlay in test mode) | same as Windows |
| Billing | Play Billing plugin + server verification (untested) | unavailable | unavailable |
| Notifications | plugin (untested), widgets need native code | no-op | no-op |
| Storage | `user://` | `user://` | `user://` → IndexedDB |
| Haptics | `Input.vibrate_handheld` | none | none |
| Display | portrait, back button | fullscreen/F11, fitted portrait window | canvas resize |

`Platform` is the only place that knows the target OS; gameplay code never calls `OS.*` directly.

## Localization

English text is the key; `data/lang/<code>.json` maps English → translation; add the code to
`I18n.LANGUAGES`. Currently **16 languages** (`en`, `hi`, `ja`, `zh`, `es`, `fr`, `de`, `pt`, `ru`,
`ko`, `ar`, `it`, `tr`, `id`, `vi`, `pl`) with 57 keys each — `en.json` is intentionally empty
because English is the key. Missing keys fall back to English, so a partial translation never breaks
a screen.
