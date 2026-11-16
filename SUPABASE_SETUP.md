# Supabase setup

**Status: client only.** `autoload/backend_service.gd` is complete and speaks the Supabase REST +
Edge Function API, but **the server side is not part of this repository** (no `supabase/` folder, no
SQL migrations, no Edge Functions) and nothing has ever been deployed. `config/backend.json` is
empty, so `BackendService.is_configured()` returns `false`, every request fails gracefully and the
game stays fully playable offline. No credentials exist in the repo — and no service-role key ever
may.

## 1. What the client expects

### Auth (REST, `/auth/v1/…`)

| Call | Endpoint | Payload |
|---|---|---|
| `BackendService.sign_up(mail, pw)` | `POST /auth/v1/signup` | `{email, password}` |
| `BackendService.sign_in(mail, pw)` | `POST /auth/v1/token?grant_type=password` | `{email, password}` |
| `BackendService.sign_in_anonymous()` | `POST /auth/v1/signup` | `{}` (needs the Anonymous provider enabled) |
| `BackendService.restore_session()` | `POST /auth/v1/token?grant_type=refresh_token` | `{refresh_token}` |

All authenticated calls send `apikey: <anon key>` plus `Authorization: Bearer <user JWT>`.

### Edge Functions (`POST /functions/v1/<name>`)

| Function | Payload | Answer used by the client |
|---|---|---|
| `validate-score` | `{mode, level_id, claimed_score, log, rules: 2}` | recomputed score / rejection |
| `leaderboard` | `{action: "top", mode, limit}` or `{action: "me", mode}` | score rows, own rank |
| `cloud-save` | `{action: "push", data, version}` or `{action: "pull"}` | merged save payload |
| `profile` | `{action: "get"}` / `{action: "update", display_name, avatar}` | profile row |
| `daily-challenge` | `{action: "get"}` | server seed + target |
| `rewards` | `{action: "history"}` / `{action: "verify_purchase", product, purchase_token}` | reward rows / verification result |

### Tables

`profiles`, `player_stats`, `cloud_saves`, `scores`, `daily_challenges` / `daily_completions`,
`seasons`, `events`, `reward_history`, `purchases`, `feedback`, plus a `leaderboard_best` view.
The client writes to **one** table directly: `public.feedback` (insert only —
`{message, platform, app_version}`). Everything else goes through Edge Functions with the
service-role key.

### Score replay contract (rules version 2)

`GameSession.event_log` is the replay format the server must understand. Entry types:

| `t` | Meaning | Fields |
|---|---|---|
| `tray` | a new tray was dealt | `ids: [piece_id, …]` (3 entries, `""` for an empty slot) |
| `p` | a piece was placed | `i` (tray index), `r` (row), `c` (col) |
| `h` | hammer removed a block | `r`, `c` |
| `s` | a stone block was destroyed by a shot | `r`, `c` |
| `c` | continue (revive) | — |

The server replays the log with its own copy of the rules (gravity v2, shooting, boosters),
recomputes the score and stores **the recomputed value**; illegal placements, impossible
continues/hammers, unknown pieces or score mismatches are rejected. Rate limit: 30 runs/hour/user.
Only `endless` runs are ranked.

**Known limit:** piece dealing is client-side randomness, so the server can prove play legality
and score arithmetic but not that a modified client was dealt fair pieces. Mitigations if needed:
server-issued seeds, plausibility caps, moderation.

## 2. Creating and deploying the backend

1. Create a project at supabase.com. In **Auth → Providers** enable Email (and **Anonymous
   sign-ins** for "Play as guest").
2. Write the schema: tables + Row Level Security policies + the profile trigger + the
   `leaderboard_best` view. Keep the service-role key **out** of every client-visible file.
3. Deploy the six functions (`validate-score`, `leaderboard`, `cloud-save`, `profile`,
   `daily-challenge`, `rewards`). The platform injects the service-role key and URL — do not copy
   them anywhere.
4. Optional secrets (`supabase secrets set`): `ALLOWED_ORIGIN=https://your-web-host`, and for
   purchase verification `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` + `ANDROID_PACKAGE_NAME`.
5. Put **only** the project URL and the anon/publishable key in `config/backend.json` (or in a
   local `user://backend.json` override for development). Never the service-role key.

## 3. Security model (what the server must enforce)

* RLS is on for every table; clients can only read their own rows (and public config tables).
* All writes to scores, cloud saves, rewards and purchases go through Edge Functions using the
  service role.
* The client always sends `rules: 2`; logs from other rules versions must be refused.
* CORS: only the shipped web host (and `ALLOWED_ORIGIN`) may call the functions.

## 4. Still missing

* The server code itself (migrations + functions + the TypeScript copy of the rules).
* The server daily challenge is not wired into gameplay — the daily layout is derived locally by
  `LevelDB.daily_level(date)`.
* Season and event configuration is shipped in `data/meta.json`; the `seasons` / `events` tables
  exist in the plan but the client does not read them.
* There is no reward-history screen in the UI, even though `BackendService.reward_history()` exists.
