extends Node
## Supabase client. Uses ONLY the public anon key + the signed-in user's JWT. Privileged work
## (score validation, rewards, purchase verification) happens in Edge Functions; the service-role key
## never exists in this project. If URL/key are blank the service reports is_configured() == false and
## all calls fail gracefully with {ok:false, error:"not_configured"}.

signal auth_changed

var url := ""
var anon_key := ""
var access_token := ""
var refresh_token := ""
var user_id := ""
var email := ""

func _ready() -> void:
	_load_config("res://config/backend.json")
	_load_config("user://backend.json")      # optional local override for development
	refresh_token = str(SaveManager.data.get("cloud", {}).get("refresh_token", ""))

func _load_config(path: String) -> void:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return
	var p = JSON.parse_string(f.get_as_text())
	if typeof(p) == TYPE_DICTIONARY:
		if str(p.get("supabase_url", "")) != "": url = str(p.supabase_url).rstrip("/")
		if str(p.get("supabase_anon_key", "")) != "": anon_key = str(p.supabase_anon_key)

func is_configured() -> bool:
	return url.begins_with("https://") and anon_key != ""

func is_signed_in() -> bool:
	return access_token != ""

# ---- HTTP -----------------------------------------------------------------------------------
func _request(method: int, path: String, body = null, auth: bool = true, extra: Array = []) -> Dictionary:
	if not is_configured(): return {"ok": false, "error": "not_configured", "code": 0}
	var http := HTTPRequest.new()
	http.timeout = 15.0
	add_child(http)
	var headers := ["Content-Type: application/json", "apikey: " + anon_key]
	headers.append("Authorization: Bearer " + (access_token if (auth and access_token != "") else anon_key))
	headers.append_array(extra)
	var err := http.request(url + path, headers, method, "" if body == null else JSON.stringify(body))
	if err != OK:
		http.queue_free()
		return {"ok": false, "error": "request_failed", "code": 0}
	var r = await http.request_completed
	http.queue_free()
	var code: int = r[1]
	var parsed = JSON.parse_string((r[3] as PackedByteArray).get_string_from_utf8())
	return {"ok": r[0] == HTTPRequest.RESULT_SUCCESS and code >= 200 and code < 300, "code": code, "body": parsed,
		"error": "" if (code >= 200 and code < 300) else "http_%d" % code}

func _call_function(name: String, payload: Dictionary) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/functions/v1/" + name, payload)

# ---- auth -----------------------------------------------------------------------------------
func _adopt(res: Dictionary) -> bool:
	if not res.ok or typeof(res.body) != TYPE_DICTIONARY or not res.body.has("access_token"): return false
	access_token = str(res.body.access_token)
	refresh_token = str(res.body.get("refresh_token", ""))
	var u: Dictionary = res.body.get("user", {})
	user_id = str(u.get("id", ""))
	email = str(u.get("email", ""))
	SaveManager.data.cloud["refresh_token"] = refresh_token
	SaveManager.mark_dirty()
	auth_changed.emit()
	return true

func sign_up(mail: String, password: String) -> bool:
	var res := await _request(HTTPClient.METHOD_POST, "/auth/v1/signup", {"email": mail, "password": password}, false)
	return _adopt(res)

func sign_in(mail: String, password: String) -> bool:
	var res := await _request(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=password", {"email": mail, "password": password}, false)
	return _adopt(res)

## Anonymous sign-in must be enabled in the Supabase project (Auth > Providers).
func sign_in_anonymous() -> bool:
	var res := await _request(HTTPClient.METHOD_POST, "/auth/v1/signup", {}, false)
	return _adopt(res)

func restore_session() -> bool:
	if refresh_token == "": return false
	var res := await _request(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=refresh_token", {"refresh_token": refresh_token}, false)
	return _adopt(res)

func sign_out() -> void:
	access_token = ""
	refresh_token = ""
	user_id = ""
	email = ""
	SaveManager.data.cloud["refresh_token"] = ""
	SaveManager.mark_dirty()
	auth_changed.emit()

# ---- features (all go through Edge Functions) -------------------------------------------------
## Rules v3: the hammer breaks one block WITHOUT gravity and stone blocks can be shot away
## (event log entry "s"). The server copy of the rules has to match this version.
func submit_score(session: GameSession) -> Dictionary:
	return await _call_function("validate-score", {"mode": session.mode, "level_id": GameState.current_level_id,
		"claimed_score": session.scoring.score, "log": session.event_log, "rules": 3})

func get_leaderboard(mode: String = "endless", limit: int = 50) -> Dictionary:
	return await _call_function("leaderboard", {"action": "top", "mode": mode, "limit": limit})

func get_my_rank(mode: String = "endless") -> Dictionary:
	return await _call_function("leaderboard", {"action": "me", "mode": mode})

func cloud_push() -> Dictionary:
	var payload := SaveManager.data.duplicate(true)
	payload.erase("cloud")
	payload.erase("run")
	return await _call_function("cloud-save", {"action": "push", "data": payload, "version": SaveManager.CURRENT_VERSION})

func cloud_pull() -> Dictionary:
	return await _call_function("cloud-save", {"action": "pull"})

func get_profile() -> Dictionary:
	return await _call_function("profile", {"action": "get"})

func update_profile(display_name: String, avatar: int) -> Dictionary:
	return await _call_function("profile", {"action": "update", "display_name": display_name, "avatar": avatar})

func get_daily_challenge() -> Dictionary:
	return await _call_function("daily-challenge", {"action": "get"})

func reward_history() -> Dictionary:
	return await _call_function("rewards", {"action": "history"})

## Inserts into public.feedback (RLS allows insert only; nobody can read others' rows).
func submit_feedback(message: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/rest/v1/feedback",
		{"message": message.substr(0, 2000), "platform": Platform.name_id(), "app_version": "0.1.0"}, true, ["Prefer: return=minimal"])

func verify_purchase(product: String, token: String) -> Dictionary:
	return await _call_function("rewards", {"action": "verify_purchase", "product": product, "purchase_token": token})
