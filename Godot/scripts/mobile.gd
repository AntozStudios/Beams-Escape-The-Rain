extends Node

signal reward(amount: int)
const PROJECT := "ee68dd81-e71c-4d23-9eb4-6be970f92a12"
const CLIENT := "27223240-152c-495d-b11f-7586fae7bf8c"
const LOGIN := "https://player-login.unity.com/v1/oauth2/"
const REDIRECT := "unitydl://com.unityplayeraccounts." + PROJECT
const AUTH := "https://player-auth.services.api.unity.com/v1/authentication/"
const CLOUD := "https://cloud-save.services.api.unity.com/v1/data/projects/"
var bridge
var activity
var profile
var status := "logged out"
var player_id := ""
var access := ""
var busy := false
var verifier := ""
var state := ""
var deadline := 0
var expires := 0
var syncing := false
var generation := 0
var poll_time := 0.0

func initialize(saved_profile) -> void:
	profile = saved_profile
	if OS.get_name() != "Android" or not Engine.has_singleton("AndroidRuntime"):
		set_process(false)
		return
	activity = Engine.get_singleton("AndroidRuntime").get_activity()
	bridge = Engine.get_singleton("JavaClassWrapper").wrap("com.antoz.beams.BeamsMobile")
	if bridge:
		bridge.initialize(activity,OS.is_debug_build())
		migrate_preferences()
		if not str(profile.value("session","")).is_empty():
			restore_session()

func migrate_preferences() -> void:
	if profile.value("imported",false):
		return
	var prefs = activity.getSharedPreferences("com.AntozStudios.BeamsEscapeTheRain.v2.playerprefs",0)
	if prefs.contains("HighScore"):
		profile.save("HighScore",maxi(profile.record(),prefs.getInt("HighScore",0)))
	if prefs.contains("lastCubeMaterial"):
		profile.save("playerSkin",prefs.getInt("lastCubeMaterial",0))
	for pair in [["LastMusicVolume","Music"],["LastProcessingValue","Vignette"]]:
		if prefs.contains(pair[0]):
			profile.save(pair[1],prefs.getFloat(pair[0],0.0))
	if prefs.contains("LastFollowPlayerSliderValue"):
		profile.save("Follow Player",prefs.getInt("LastFollowPlayerSliderValue",1))
	if prefs.contains("lastCameraColor_R"):
		var sky := Color(prefs.getFloat("lastCameraColor_R",0.0),prefs.getFloat("lastCameraColor_G",0.0),prefs.getFloat("lastCameraColor_B",0.0))
		for i in profile.ITEMS.size():
			if profile.ITEMS[i][1] == "skyColor" and sky.is_equal_approx(profile.ITEMS[i][3]):
				profile.save("skyColor",i)
	profile.save("imported",true)

func can_login() -> bool:
	return bridge != null

func reward_ready() -> bool:
	return bridge != null and bridge.ready()

func watch() -> void:
	if reward_ready():
		bridge.watch(activity)

func banner(visible: bool) -> void:
	if bridge:
		bridge.setBanner(activity,visible)

func _process(delta: float) -> void:
	poll_time += delta
	if not bridge or poll_time < 0.2:
		return
	poll_time = 0
	var amount := int(bridge.takeReward())
	if amount > 0:
		reward.emit(amount)
	var callback := str(bridge.takeLogin())
	if not state.is_empty():
		if Time.get_ticks_msec() >= deadline:
			fail("Sign-in timed out")
		elif callback.begins_with(REDIRECT + "?"):
			exchange(callback.get_slice("?",1))
	if not busy and not player_id.is_empty() and Time.get_unix_time_from_system() >= expires:
		restore_session()

func random_string() -> String:
	return base64url(Crypto.new().generate_random_bytes(32))

func base64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+","-").replace("/","_").trim_suffix("=")

func sign_in() -> void:
	if not can_login() or busy:
		return
	state = random_string()
	verifier = random_string()
	deadline = Time.get_ticks_msec()+180000
	busy = true
	status = "Signing in..."
	var query := {"response_type":"code","redirect_uri":REDIRECT,"response_mode":"query","client_id":CLIENT,"state":state,"code_challenge":base64url(verifier.sha256_buffer()),"code_challenge_method":"S256","scope":"openid email offline_access"}
	if OS.shell_open(LOGIN+"auth?"+HTTPClient.new().query_string_from_dict(query)) != OK:
		fail("Could not open sign-in")

func exchange(query: String) -> void:
	var params := {}
	for field in query.split("&"):
		params[field.get_slice("=",0)] = field.get_slice("=",1).uri_decode()
	if params.get("state","") != state:
		return
	state = ""
	if not params.has("code"):
		fail("Sign-in cancelled")
		return
	var form := {"grant_type":"authorization_code","code":params.code,"redirect_uri":REDIRECT,"client_id":CLIENT,"code_verifier":verifier}
	verifier = ""
	var result := await request(LOGIN+"token",["Content-Type: application/x-www-form-urlencoded"],HTTPClient.METHOD_POST,HTTPClient.new().query_string_from_dict(form))
	if not result.has("access_token"):
		fail("Sign-in failed")
		return
	await authenticate("external-token/unity",{"token":result.access_token})

func restore_session() -> void:
	busy = true
	await authenticate("session-token",{"sessionToken":profile.value("session","")})

func authenticate(path: String, body: Dictionary) -> void:
	var epoch := generation
	var result := await request(AUTH+path,["ProjectId: "+PROJECT,"Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(body))
	if epoch != generation:
		return
	if not result.has("idToken") or not result.has("userId"):
		expires = int(Time.get_unix_time_from_system())+60
		fail("Sign-in failed")
		return
	player_id = result.userId
	access = result.idToken
	profile.save("session",result.sessionToken)
	expires = int(Time.get_unix_time_from_system())+int(result.get("expiresIn",3600))-60
	busy = false
	status = "PlayerId: "+player_id
	await sync_score()

func sync_score() -> void:
	if access.is_empty() or syncing:
		return
	syncing = true
	var epoch := generation
	var endpoint := CLOUD+PROJECT+"/players/"+player_id+"/items"
	var headers := PackedStringArray(["Authorization: Bearer "+access,"Content-Type: application/json"])
	var data := await request(endpoint+"?keys=HighScore",headers,HTTPClient.METHOD_GET)
	if epoch != generation:
		return
	if data.has("results"):
		var remote := -1
		var lock_id := ""
		for item in data.results:
			if item.key == "HighScore":
				remote = int(item.value)
				lock_id = item.get("writeLock","")
		if remote > profile.record():
			profile.save("HighScore",remote)
		elif remote < profile.record():
			var body := {"key":"HighScore","value":profile.record()}
			if not lock_id.is_empty():
				body.writeLock = lock_id
			data = await request(endpoint,headers,HTTPClient.METHOD_POST,JSON.stringify(body))
	if epoch != generation:
		return
	syncing = false
	if data.is_empty():
		status = "Cloud sync pending"
		await get_tree().create_timer(20).timeout
		if epoch == generation:
			sync_score()
	else:
		status = "PlayerId: "+player_id

func request(url: String, headers: PackedStringArray, method: int, body: String = "") -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 15
	add_child(http)
	if http.request(url,headers,method,body) != OK:
		http.queue_free()
		return {}
	var response: Array = await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] < 200 or response[1] >= 300:
		return {}
	var parsed = JSON.parse_string(response[3].get_string_from_utf8())
	return parsed if parsed is Dictionary else {}

func fail(message: String) -> void:
	state = ""
	verifier = ""
	busy = false
	status = message

func sign_out() -> void:
	generation += 1
	syncing = false
	player_id = ""
	access = ""
	profile.config.clear()
	profile.save("imported",true)
	fail("logged out")
