# Ads setup

`autoload/ads_service.gd` is the only place that talks to an ad SDK. It covers banner, interstitial
and rewarded ads with a **test mode** so every flow can be exercised without any SDK.

## Current state

* `config/ads.json` ships with `"test_mode": true`. In test mode a clearly labelled **TEST AD**
  overlay is shown instead of a real ad and the reward is granted — on any platform.
* Without a plugin (Windows, Web, Android without the SDK) ads are simply unavailable and the UI
  hides the ad buttons.
* **Consent:** the first launch of Home asks "Privacy & Ads" and stores `granted` / `denied` in the
  save settings. Settings → Privacy can change it later. Personalised ads require consent;
  `has_consent()` gates the real SDK path.
* **Interstitials** are never shown during gameplay — only at game over and at level end, and they
  are frequency-capped: at least `interstitial_min_interval_sec` (180 s) **and**
  `interstitial_min_games_between` (3 games) between two interstitials. They are skipped entirely
  after the player bought "Remove Ads" (`GameState.ads_removed()`).
* **Rewarded placements** used by the game: `continue` (after game over), `booster_hammer`,
  `booster_refresh`, `booster_shuffle` (in-game and in the inventory), `shop_coins`.

## To enable real ads (needs your accounts)

1. Pick a Godot 4 Android ad plugin (AdMob/Unity/ironSource — all expose a plugin singleton).
2. Install it as an Android plugin (requires the Gradle build, see `EXPORT_GUIDE.md`).
3. Fill in `config/ads.json`:
   * `android.plugin_singleton` — the singleton name the plugin registers (currently `AdMob`),
   * `android.app_id`, `banner_unit`, `interstitial_unit`, `rewarded_unit` — **your** IDs,
   * `test_mode: false` for release builds.
4. Adapt the three adapter functions at the bottom of `ads_service.gd`
   (`_android_rewarded`, `_android_interstitial`, `_android_banner`) to that plugin's method names.
   The current code assumes `load_rewarded()/show_rewarded()` plus a `rewarded_earned` signal.
5. If you need a consent-management platform (UMP), call it before the first ad request and feed
   the result into `AdsService.set_consent()`.

Never hard-code ad unit IDs in GDScript — they belong in `config/ads.json`.
