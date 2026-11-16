# Billing setup

`autoload/billing_service.gd` + the shop catalogue in `data/meta.json`
(`kind: "iap"`: coin packs, gem pack, booster pack, remove-ads).

## Current state

- **Test mode** grants purchases instantly **only in debug builds** (`OS.is_debug_build()`); a red
  banner in the Shop says so. Release builds never simulate a purchase.
- Windows/Web: real-money purchases unavailable (the Shop shows why). Android without the plugin
  or backend: unavailable.
- Production flow (implemented, **untested**): plugin purchase → purchase token → `rewards` Edge
  Function `verify_purchase` (Google Play Developer API, token de-duplicated by SHA-256) → only
  then the reward is granted locally and the purchase acknowledged/consumed.
- `BillingService.restore()` is a **stub** — non-consumables cannot be restored yet.

## Products

Defined in `config/billing.json` and referenced from `data/meta.json`:

| Product id | Type | Shop item | Display price (placeholder) |
|---|---|---|---|
| `coins_500` | consumable | Coin Pouch — 500 coins | $0.99 |
| `coins_3000` | consumable | Coin Chest — 3000 coins | $4.99 |
| `gems_100` | consumable | Gem Handful — 100 gems | $1.99 |
| `booster_pack` | consumable | Booster Pack — 3× hammer, refresh, shuffle | $2.99 |
| `remove_ads` | non-consumable | Remove Ads | $3.99 |

Soft-currency items (`kind: "coins"` / `kind: "gems"`) are bought locally in the Shop and never
reach the store: hammer 150 coins, refresh 100 coins, shuffle 80 coins, 500 coins for 10 gems.

## To enable (needs your accounts)

1. Create the in-app products in Play Console with the IDs above; mark consumables vs
   non-consumable as listed.
2. Install a Godot 4 Google Play Billing plugin (Gradle build), set `plugin_singleton` in
   `config/billing.json` (currently `GodotGooglePlayBilling`) and adapt `_android_purchase` /
   `_android_acknowledge` to that plugin's API.
3. Create a Google Cloud service account with Play Developer API access, grant it in Play Console,
   set `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` + `ANDROID_PACKAGE_NAME` as Supabase secrets and deploy
   the `rewards` function.
4. Set `test_mode` false for release. Implement `restore()` for non-consumables.

Prices in `meta.json` (`price_label`) are display strings only — read the real localised prices
from the plugin before launch.
