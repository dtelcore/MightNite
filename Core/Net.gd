extends Node

signal room_updated(row: Dictionary)
signal notice_changed(text: String)
signal desynced

const ROSTER := {
	"MartialHero": "res://Characters/MartialHero/MartialHero.tres",
	"LightBandit": "res://Characters/LightBandit/LightBandit.tres",
	"HeavyBandit": "res://Characters/HeavyBandit/HeavyBandit.tres",
}
const STAGES := {
	"dojo": "res://Stages/dojo.tres",
	"shrine": "res://Stages/shrine.tres",
	"neon": "res://Stages/neon.tres",
	"dock": "res://Stages/dock.tres",
	"pit": "res://Stages/pit.tres",
}
const CHARACTER_IDS := {
	"Martial Hero": "MartialHero",
	"Light Bandit": "LightBandit",
	"Heavy Bandit": "HeavyBandit",
}
const STAGE_IDS := {
	"Dojo": "dojo",
	"Shrine": "shrine",
	"Neon Roof": "neon",
	"Dock 7": "dock",
	"The Pit": "pit",
}
const _ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const _T_INPUT := 1
const _T_SUM := 2
const _T_PING := 3
const _T_PONG := 4
const _T_DELAY := 5
const _T_DELAY_ACK := 6

var online := false
var local_slot := 0
var room_code := ""
var room: Dictionary = {}
var client_id := ""
var notice := ""
var link_failed := false
var delay_ready := false
var input_delay := 2
var sim_frame := 0
var match_live := false
var stepping := true
var socket_ready := false

var _url := ""
var _key := ""
var _http: HTTPRequest
var _http_busy := false
var _queue: Array = []
var _ws: WebSocketPeer
var _join_ref := ""
var _msg_ref := 0
var _ws_private := false
var _peer: WebRTCPeerConnection
var _channel: WebRTCDataChannel
var _channel_open := false
var _local_sdp := ""
var _local_kind := ""
var _remote_ready := false
var _pending_ice: Array = []
var _link_msec := 0
var _offer_sent := false
var _last_signal_msec := 0
var _heartbeat_msec := 0
var _poll_wait := 0.0
var _leaving := false
var _match_loading := false
var _fight_sent := false
var local_inputs := {}
var remote_inputs := {}
var _fighters: Array = []
var _sums := {}
var stall_frames := 0
var _delay_bumped := false
var _pings: Array[int] = []
var _ping_msec := 0
var _awaiting_pong := false
var _peer_acked := false
var _desync_sent := false
var _remote_sdp := ""
var _local_ice: Array = []


func _ready() -> void:
	process_physics_priority = -200
	var config_path := "res://Core/SupabaseConfig.gd"
	if ResourceLoader.exists(config_path):
		var cfg = load(config_path)
		_url = str(cfg.URL).trim_suffix("/")
		_key = str(cfg.ANON_KEY)
	_http = HTTPRequest.new()
	_http.timeout = 20.0
	add_child(_http)
	_http.request_completed.connect(_on_http)
	var late := Node.new()
	late.name = "NetLate"
	late.set_script(load("res://Core/NetLate.gd"))
	add_child(late)


func configured() -> bool:
	return _url != "" and _key != ""


func create_room() -> void:
	if not configured():
		_set_notice("Add Core/SupabaseConfig.gd with the project URL and publishable key")
		return
	_reset_session()
	online = true
	local_slot = 0
	_set_notice("Opening room")
	_request(HTTPClient.METHOD_POST, "/rpc/purge_old_rooms", "{}", func(_code: int, _parsed) -> void:
		_post_room(_make_code())
	)


func join_room(code: String) -> void:
	if not configured():
		_set_notice("Add Core/SupabaseConfig.gd with the project URL and publishable key")
		return
	var cleaned := code.strip_edges().to_upper()
	if cleaned.length() != 4:
		_set_notice("Enter a 4 character code")
		return
	_reset_session()
	online = true
	local_slot = 1
	room_code = cleaned
	_set_notice("Joining %s" % cleaned)
	_request(HTTPClient.METHOD_GET, "/rooms?code=eq.%s&select=*" % cleaned, "", _on_join_fetched)


func push_local(character_id: String, stage_id: String, ready: bool) -> void:
	if not online or room_code == "":
		return
	var body := {}
	if local_slot == 0:
		body["p1_character"] = character_id
		body["stage_id"] = stage_id
		body["host_ready"] = ready
	else:
		body["p2_character"] = character_id
		body["guest_ready"] = ready
	_patch(body)


func leave() -> void:
	if _leaving:
		return
	_leaving = true
	var code := room_code
	var was_online := online
	online = false
	match_live = false
	stepping = true
	_shutdown_link()
	room_code = ""
	room = {}
	if was_online and code != "":
		_request(HTTPClient.METHOD_DELETE, "/rooms?code=eq.%s" % code, "", func(_c: int, _p) -> void:
			pass
		)
	GameManager.p1_rounds = 0
	GameManager.p2_rounds = 0
	_leaving = false
	var tree := get_tree()
	if tree == null or tree.current_scene == null:
		return
	if tree.current_scene.scene_file_path == "res://Scenes/MainMenu.tscn":
		return
	tree.call_deferred("change_scene_to_file", "res://Scenes/MainMenu.tscn")


func go_match() -> void:
	if not online or _match_loading:
		return
	var tree := get_tree()
	if tree.current_scene and str(tree.current_scene.scene_file_path).ends_with("Match.tscn"):
		return
	_match_loading = true
	var p1 := _text(room.get("p1_character", "MartialHero"))
	var p2 := _text(room.get("p2_character", "HeavyBandit"))
	var stage := _text(room.get("stage_id", "dojo"))
	if not ROSTER.has(p1):
		p1 = "MartialHero"
	if not ROSTER.has(p2):
		p2 = "HeavyBandit"
	if not STAGES.has(stage):
		stage = "dojo"
	GameManager.p1_data = load(ROSTER[p1])
	GameManager.p2_data = load(ROSTER[p2])
	GameManager.stage = load(STAGES[stage])
	GameManager.p1_rounds = 0
	GameManager.p2_rounds = 0
	tree.call_deferred("change_scene_to_file", "res://Scenes/Match.tscn")


func attach_match(p1, p2) -> void:
	_fighters = [p1, p2]
	sim_frame = 0
	local_inputs.clear()
	remote_inputs.clear()
	_sums.clear()
	stall_frames = 0
	_match_loading = false
	match_live = online and delay_ready
	stepping = true


func should_step() -> bool:
	if not online:
		return true
	return match_live and stepping


func sample_for(player_index: int) -> Dictionary:
	if not online or not match_live:
		return InputManager.sample(player_index)
	var bag: Dictionary = local_inputs if player_index == local_slot else remote_inputs
	if bag.has(sim_frame):
		return bag[sim_frame]
	return _neutral()


func after_step() -> void:
	if not online or not match_live or not stepping:
		return
	if sim_frame > 0 and sim_frame % 30 == 0:
		_send_checksum(sim_frame)
	sim_frame += 1


func pack_input(frame: int, sample: Dictionary) -> PackedByteArray:
	return _pack_input(frame, sample)


func unpack_input(buf: PackedByteArray) -> Dictionary:
	if buf.size() < 7 or buf[0] != _T_INPUT:
		return {}
	return {"frame": _read_u32(buf, 1), "sample": _sample_from_bits(_read_u16(buf, 5))}


func _physics_process(_delta: float) -> void:
	_poll_link()
	if not online or not match_live:
		stepping = true
		return
	if _inputs_ready(sim_frame):
		stepping = true
		stall_frames = 0
		_delay_bumped = false
		_capture_local(sim_frame + input_delay)
	else:
		stepping = false
		stall_frames += 1
		_retransmit()
		if stall_frames == 8:
			_host_bump_delay()
		if stall_frames >= 180:
			_set_notice("Opponent left")
			leave()


func _process(delta: float) -> void:
	_poll_link()
	_service_handshake()
	if not online or match_live or room_code == "":
		return
	_poll_wait += delta
	if _poll_wait < 0.8:
		return
	_poll_wait = 0.0
	if _http_busy:
		return
	_request(HTTPClient.METHOD_GET, "/rooms?code=eq.%s&select=*" % room_code, "", _on_polled_room)


func _reset_session() -> void:
	_leaving = false
	_shutdown_link()
	online = false
	local_slot = 0
	room_code = ""
	room = {}
	link_failed = false
	delay_ready = false
	input_delay = 2
	sim_frame = 0
	match_live = false
	stepping = true
	socket_ready = false
	_match_loading = false
	_fight_sent = false
	_channel_open = false
	_offer_sent = false
	_peer_acked = false
	_pings.clear()
	local_inputs.clear()
	remote_inputs.clear()
	_fighters.clear()
	_client_id()


func _post_room(code: String) -> void:
	room_code = code
	var body := {
		"code": code,
		"status": "lobby",
		"host_id": client_id,
		"game_version": Constants.GAME_VERSION,
		"p1_character": "MartialHero",
		"p2_character": "HeavyBandit",
		"stage_id": "dojo",
		"host_ready": false,
		"guest_ready": false,
	}
	_request(HTTPClient.METHOD_POST, "/rooms", JSON.stringify(body), func(code_status: int, parsed) -> void:
		if code_status == 409:
			_post_room(_make_code())
			return
		var row := _first_row(parsed)
		if code_status >= 300 or row.is_empty():
			_set_notice("Could not open a room (%s)" % code_status)
			online = false
			return
		_apply_room(row)
		_connect_ws()
		_set_notice("Room %s" % room_code)
	)


func _on_join_fetched(code_status: int, parsed) -> void:
	var row := _first_row(parsed)
	if code_status >= 300 or row.is_empty():
		_set_notice("No room with that code")
		online = false
		room_code = ""
		return
	if _text(row.get("game_version")) != Constants.GAME_VERSION:
		_set_notice("Version mismatch")
		online = false
		room_code = ""
		return
	var guest := _text(row.get("guest_id"))
	if guest != "" and guest != client_id:
		_set_notice("That room is full")
		online = false
		room_code = ""
		return
	_patch_path("/rooms?code=eq.%s&guest_id=is.null" % room_code, {"guest_id": client_id}, func(status: int, body) -> void:
		var joined := _first_row(body)
		if status >= 300 or joined.is_empty():
			_set_notice("That room is full")
			online = false
			return
		_apply_room(joined)
		_connect_ws()
	)


func _on_polled_room(code_status: int, parsed) -> void:
	if not online:
		return
	if code_status >= 300:
		return
	if parsed is Array and (parsed as Array).is_empty():
		_set_notice("Room closed")
		leave()
		return
	var row := _first_row(parsed)
	if not row.is_empty():
		_apply_room(row)


func _patch(body: Dictionary) -> void:
	_patch_path("/rooms?code=eq.%s" % room_code, body, func(status: int, parsed) -> void:
		if not online or status >= 300:
			return
		var row := _first_row(parsed)
		if not row.is_empty():
			_apply_room(row)
	)


func _patch_path(path: String, body: Dictionary, callback: Callable) -> void:
	_request(HTTPClient.METHOD_PATCH, path, JSON.stringify(body), callback)


func _apply_room(row: Dictionary) -> void:
	if _text(row.get("game_version")) not in ["", Constants.GAME_VERSION]:
		_set_notice("Version mismatch")
		leave()
		return
	room = row
	room_code = _text(row.get("code", room_code))
	room_updated.emit(row)
	if _text(row.get("guest_id")) != "":
		_ensure_link()
		if local_slot == 0 and _text(row.get("status")) == "lobby":
			_patch({"status": "select"})
	var status := _text(row.get("status"))
	if status == "done":
		_set_notice("Room closed")
		leave()
		return
	if status == "fight":
		go_match()
	_consider_fight()


func _consider_fight() -> void:
	if local_slot != 0 or not delay_ready or not _peer_acked or _fight_sent:
		return
	if _text(room.get("status")) != "select":
		return
	if not bool(room.get("host_ready")) or not bool(room.get("guest_ready")):
		return
	_fight_sent = true
	_patch({"status": "fight"})


func _request(method: int, path: String, body: String, callback: Callable) -> void:
	_queue.append({"method": method, "path": path, "body": body, "callback": callback})
	_pump_http()


func _pump_http() -> void:
	if _http_busy or _queue.is_empty() or _http == null:
		return
	var job: Dictionary = _queue.pop_front()
	_http_busy = true
	_http.set_meta("callback", job["callback"])
	var headers := PackedStringArray([
		"apikey: %s" % _key,
		"Authorization: Bearer %s" % _key,
		"Content-Type: application/json",
		"Prefer: return=representation",
	])
	var err := _http.request(_url + "/rest/v1" + str(job["path"]), headers, int(job["method"]), str(job["body"]))
	if err != OK:
		_http_busy = false
		var callback: Callable = job["callback"]
		callback.call(0, null)
		_pump_http()


func _on_http(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_http_busy = false
	var callback: Callable = _http.get_meta("callback")
	var parsed = null
	if result == HTTPRequest.RESULT_SUCCESS and body.size() > 0:
		parsed = JSON.parse_string(body.get_string_from_utf8())
	if callback.is_valid():
		callback.call(code, parsed)
	_pump_http()


func _connect_ws() -> void:
	if _ws != null or room_code == "" or _key == "":
		return
	_ws = WebSocketPeer.new()
	var root := _url.replace("https://", "wss://")
	var url := "%s/realtime/v1/websocket?apikey=%s&vsn=1.0.0" % [root, _key.uri_encode()]
	_ws.connect_to_url(url)
	_heartbeat_msec = Time.get_ticks_msec()


func _poll_link() -> void:
	if _ws != null:
		_ws.poll()
		var state := _ws.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if _join_ref == "" and room_code != "":
				_join_channel(false)
			while _ws.get_available_packet_count() > 0:
				var packet := _ws.get_packet().get_string_from_utf8()
				_on_ws_text(packet)
			if Time.get_ticks_msec() - _heartbeat_msec > 25000:
				_heartbeat_msec = Time.get_ticks_msec()
				_ws_send(null, _next_ref(), "phoenix", "heartbeat", {})
		elif state == WebSocketPeer.STATE_CLOSED and online and not match_live:
			_ws = null
			_join_ref = ""
			socket_ready = false
			_connect_ws()
	if _peer != null:
		_peer.poll()
	if _channel != null:
		if _channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN and not _channel_open:
			_channel_open = true
			_set_notice("Link open")
			if local_slot == 0:
				_send_next_ping()
		while _channel.get_available_packet_count() > 0:
			_on_packet(_channel.get_packet())


func _on_ws_text(text: String) -> void:
	var parsed = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return
	var topic := str(parsed.get("topic", ""))
	var event := str(parsed.get("event", ""))
	var payload = parsed.get("payload", {})
	if event == "phx_reply" and topic == _topic():
		var status := ""
		if payload is Dictionary:
			status = str(payload.get("status", ""))
		if status == "ok":
			socket_ready = true
			for ice in _local_ice:
				_broadcast(ice)
			_local_ice.clear()
			if local_slot == 1:
				_broadcast({"kind": "hello", "from": client_id})
			_ensure_link()
		elif not _ws_private:
			_ws_private = true
			_ws_send(_join_ref, _next_ref(), _topic(), "phx_leave", {})
			_join_channel(true)
		else:
			link_failed = true
			_set_notice("Could not join the room channel")
		return
	if event == "postgres_changes" and payload is Dictionary:
		var data = payload.get("data", payload)
		if data is Dictionary:
			var record = data.get("record", {})
			if record is Dictionary and not (record as Dictionary).is_empty():
				_apply_room(record)
		return
	if event == "broadcast" and payload is Dictionary:
		var inner = payload.get("payload", {})
		if inner is Dictionary:
			_on_signal(inner)


func _join_channel(private_channel: bool) -> void:
	_ws_private = private_channel
	_join_ref = _next_ref()
	_ws_send(_join_ref, _join_ref, _topic(), "phx_join", {
		"config": {
			"broadcast": {"ack": false, "self": false},
			"presence": {"enabled": false},
			"postgres_changes": [{
				"event": "*",
				"schema": "public",
				"table": "rooms",
				"filter": "code=eq.%s" % room_code,
			}],
			"private": private_channel,
		},
		"access_token": _key,
	})


func _topic() -> String:
	return "realtime:room:%s" % room_code


func _ws_send(join_ref, ref_id, topic: String, event: String, payload: Dictionary) -> void:
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	_ws.send_text(JSON.stringify({
		"topic": topic,
		"event": event,
		"payload": payload,
		"ref": ref_id,
		"join_ref": join_ref,
	}))


func _broadcast(data: Dictionary) -> void:
	_ws_send(_join_ref, _next_ref(), _topic(), "broadcast", {
		"type": "broadcast",
		"event": "signal",
		"payload": data,
	})


func _ensure_link() -> void:
	if _channel_open or link_failed or room_code == "":
		return
	if _link_msec == 0:
		_link_msec = Time.get_ticks_msec()
	if not ClassDB.class_exists("WebRTCPeerConnection"):
		link_failed = true
		_set_notice("WebRTC extension missing")
		return
	if _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN and _join_ref == "":
		_join_channel(false)
	if _peer == null:
		_open_peer()


func _open_peer() -> void:
	_peer = WebRTCPeerConnection.new()
	_peer.session_description_created.connect(_on_local_description)
	_peer.ice_candidate_created.connect(_on_local_ice)
	var err := _peer.initialize({"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]})
	if err != OK:
		link_failed = true
		_set_notice("Could not open a direct link")
		return
	_channel = _peer.create_data_channel("inputs", {
		"negotiated": true,
		"id": 1,
		"ordered": false,
		"maxRetransmits": 0,
	})
	if _channel == null:
		link_failed = true
		_set_notice("Could not open a direct link")


func _service_handshake() -> void:
	if not online or _channel_open or link_failed:
		if online and local_slot == 0 and _channel_open and not delay_ready and not _peer_acked:
			if Time.get_ticks_msec() - _last_signal_msec > 1000 and input_delay >= 2 and _pings.size() >= 4:
				_last_signal_msec = Time.get_ticks_msec()
				_send_delay(input_delay)
		return
	if _link_msec > 0 and Time.get_ticks_msec() - _link_msec > 15000:
		link_failed = true
		_set_notice("Could not open a direct link")
		return
	if _text(room.get("guest_id")) == "" or not socket_ready:
		return
	var now := Time.get_ticks_msec()
	if now - _last_signal_msec < 2000:
		return
	_last_signal_msec = now
	if local_slot == 1:
		_broadcast({"kind": "hello", "from": client_id})
		if _local_sdp != "":
			_broadcast({"kind": _local_kind, "sdp": _local_sdp, "from": client_id})
		return
	if _peer != null and not _offer_sent:
		_offer_sent = true
		_peer.create_offer()
	elif _local_sdp != "":
		_broadcast({"kind": _local_kind, "sdp": _local_sdp, "from": client_id})


func _on_signal(data: Dictionary) -> void:
	if _text(data.get("from")) == client_id:
		return
	var kind := _text(data.get("kind"))
	if kind == "hello":
		if local_slot == 0 and _peer != null and not _offer_sent:
			_offer_sent = true
			_peer.create_offer()
		return
	if _peer == null:
		return
	if kind == "offer" and local_slot == 1:
		var offer := _text(data.get("sdp"))
		if offer == _remote_sdp:
			return
		_remote_sdp = offer
		_peer.set_remote_description("offer", offer)
		_flush_ice()
		if _local_sdp == "":
			_peer.create_answer()
		return
	if kind == "answer" and local_slot == 0:
		var answer := _text(data.get("sdp"))
		if answer == _remote_sdp:
			return
		_remote_sdp = answer
		_peer.set_remote_description("answer", answer)
		_flush_ice()
		return
	if kind == "ice":
		var ice := {"mid": _text(data.get("mid")), "index": int(data.get("index", 0)), "candidate": _text(data.get("candidate"))}
		if _remote_ready:
			_peer.add_ice_candidate(ice["mid"], ice["index"], ice["candidate"])
		else:
			_pending_ice.append(ice)


func _on_local_description(kind: String, sdp: String) -> void:
	if _peer != null:
		_peer.set_local_description(kind, sdp)
	_local_kind = kind
	_local_sdp = sdp
	_broadcast({"kind": kind, "sdp": sdp, "from": client_id})


func _on_local_ice(mid: String, index: int, candidate: String) -> void:
	var data := {"kind": "ice", "mid": mid, "index": index, "candidate": candidate, "from": client_id}
	if socket_ready:
		_broadcast(data)
	else:
		_local_ice.append(data)


func _flush_ice() -> void:
	_remote_ready = true
	for ice in _pending_ice:
		_peer.add_ice_candidate(ice["mid"], ice["index"], ice["candidate"])
	_pending_ice.clear()


func _on_packet(buf: PackedByteArray) -> void:
	if buf.is_empty():
		return
	match buf[0]:
		_T_INPUT:
			if buf.size() < 7:
				return
			var frame := _read_u32(buf, 1)
			remote_inputs[frame] = _sample_from_bits(_read_u16(buf, 5))
		_T_SUM:
			if buf.size() < 17:
				return
			_store_remote_sum(_read_u32(buf, 1), _sum_from_buf(buf, 5))
		_T_PING:
			if buf.size() < 5:
				return
			_send_pong(_read_u32(buf, 1))
		_T_PONG:
			if buf.size() < 5 or not _awaiting_pong:
				return
			_awaiting_pong = false
			_pings.append(maxi(Time.get_ticks_msec() - _read_u32(buf, 1), 0))
			if _pings.size() >= 4:
				_choose_delay()
			else:
				_send_next_ping()
		_T_DELAY:
			if buf.size() < 2:
				return
			var value := clampi(buf[1], 2, 8)
			if match_live:
				_apply_delay(value)
			else:
				input_delay = value
			delay_ready = true
			_send_raw(_pack_byte(_T_DELAY_ACK))
			_set_notice("Delay %d" % input_delay)
		_T_DELAY_ACK:
			_peer_acked = true
			delay_ready = true
			_set_notice("Delay %d" % input_delay)
			if _fighters.size() == 2:
				match_live = true
			_consider_fight()


func _send_next_ping() -> void:
	_awaiting_pong = true
	_ping_msec = Time.get_ticks_msec()
	var buf := PackedByteArray()
	buf.append(_T_PING)
	_write_u32(buf, _ping_msec)
	_send_raw(buf)


func _send_pong(stamp: int) -> void:
	var buf := PackedByteArray()
	buf.append(_T_PONG)
	_write_u32(buf, stamp)
	_send_raw(buf)


func _choose_delay() -> void:
	var sorted := _pings.duplicate()
	sorted.sort()
	var rtt := float(sorted[sorted.size() / 2])
	var frames := int(ceil(rtt * 0.5 / (1000.0 / 60.0))) + 1
	input_delay = clampi(frames, 2, 8)
	_send_delay(input_delay)
	_set_notice("Delay %d" % input_delay)


func _send_delay(value: int) -> void:
	var buf := PackedByteArray()
	buf.append(_T_DELAY)
	buf.append(value)
	_send_raw(buf)


func _host_bump_delay() -> void:
	if local_slot != 0 or _delay_bumped or input_delay >= 8:
		return
	_delay_bumped = true
	var next := mini(input_delay + 1, 8)
	_apply_delay(next)
	_send_delay(next)


func _apply_delay(new_delay: int) -> void:
	new_delay = clampi(new_delay, 2, 8)
	if new_delay <= input_delay:
		return
	var last := -1
	for key in local_inputs.keys():
		last = maxi(last, int(key))
	var sample: Dictionary = local_inputs[last] if last >= 0 else _neutral()
	var frame := last + 1
	var target := sim_frame + new_delay
	while frame <= target:
		local_inputs[frame] = sample.duplicate(true)
		_send_input(frame)
		frame += 1
	input_delay = new_delay


func _capture_local(frame: int) -> void:
	if not local_inputs.has(frame):
		var sample := InputManager.sample(0)
		sample["pressed"] = (sample["pressed"] as Dictionary).duplicate()
		local_inputs[frame] = sample
	_send_input(frame)
	_retransmit()


func _retransmit() -> void:
	var frames: Array = local_inputs.keys()
	frames.sort()
	var start := maxi(frames.size() - 8, 0)
	for i in range(start, frames.size()):
		_send_input(int(frames[i]))


func _send_input(frame: int) -> void:
	if not local_inputs.has(frame):
		return
	_send_raw(_pack_input(frame, local_inputs[frame]))


func _inputs_ready(frame: int) -> bool:
	return _has_frame(local_inputs, frame) and _has_frame(remote_inputs, frame)


func _has_frame(bag: Dictionary, frame: int) -> bool:
	return bag.has(frame) or frame < input_delay


func _send_checksum(frame: int) -> void:
	if _fighters.size() < 2:
		return
	var body := _measure()
	if not _sums.has(frame):
		_sums[frame] = {}
	_sums[frame]["local"] = body
	var buf := PackedByteArray()
	buf.append(_T_SUM)
	_write_u32(buf, frame)
	_write_sum(buf, body)
	_send_raw(buf)
	_compare_sum(frame)


func _store_remote_sum(frame: int, body: Dictionary) -> void:
	if not _sums.has(frame):
		_sums[frame] = {}
	_sums[frame]["remote"] = body
	_compare_sum(frame)


func _compare_sum(frame: int) -> void:
	if not _sums.has(frame):
		return
	var row: Dictionary = _sums[frame]
	if not row.has("local") or not row.has("remote"):
		return
	var local: Dictionary = row["local"]
	var remote: Dictionary = row["remote"]
	for key in local.keys():
		if int(local[key]) != int(remote.get(key, -99999)):
			if _desync_sent:
				return
			_desync_sent = true
			desynced.emit()
			_set_notice("Desync")
			return


func _measure() -> Dictionary:
	var a = _fighters[0]
	var b = _fighters[1]
	return {
		"p1": a.hp.current,
		"p2": b.hp.current,
		"x1": int(round(a.global_position.x)),
		"y1": int(round(a.global_position.y)),
		"x2": int(round(b.global_position.x)),
		"y2": int(round(b.global_position.y)),
	}


func _sum_from_buf(buf: PackedByteArray, at: int) -> Dictionary:
	return {
		"p1": _read_u16(buf, at),
		"p2": _read_u16(buf, at + 2),
		"x1": _read_i16(buf, at + 4),
		"y1": _read_i16(buf, at + 6),
		"x2": _read_i16(buf, at + 8),
		"y2": _read_i16(buf, at + 10),
	}


func _write_sum(buf: PackedByteArray, body: Dictionary) -> void:
	_write_u16(buf, int(body["p1"]))
	_write_u16(buf, int(body["p2"]))
	_write_i16(buf, int(body["x1"]))
	_write_i16(buf, int(body["y1"]))
	_write_i16(buf, int(body["x2"]))
	_write_i16(buf, int(body["y2"]))


func _pack_input(frame: int, sample: Dictionary) -> PackedByteArray:
	var buf := PackedByteArray()
	buf.append(_T_INPUT)
	_write_u32(buf, frame)
	_write_u16(buf, _bits(sample))
	return buf


func _pack_byte(kind: int) -> PackedByteArray:
	var buf := PackedByteArray()
	buf.append(kind)
	return buf


func _bits(sample: Dictionary) -> int:
	var dir: Vector2i = sample.get("dir", Vector2i.ZERO)
	var bits := (int(dir.x) + 1) & 3
	bits |= ((int(dir.y) + 1) & 3) << 2
	var pressed: Dictionary = sample.get("pressed", {})
	for i in Constants.BUTTONS.size():
		if pressed.get(Constants.BUTTONS[i], false):
			bits |= 1 << (4 + i)
	return bits


func _sample_from_bits(bits: int) -> Dictionary:
	var sample := _neutral()
	sample["dir"] = Vector2i((bits & 3) - 1, ((bits >> 2) & 3) - 1)
	var pressed: Dictionary = sample["pressed"]
	for i in Constants.BUTTONS.size():
		pressed[Constants.BUTTONS[i]] = (bits & (1 << (4 + i))) != 0
	return sample


func _neutral() -> Dictionary:
	var pressed := {}
	for button in Constants.BUTTONS:
		pressed[button] = false
	return {"dir": Vector2i.ZERO, "pressed": pressed}


func _send_raw(buf: PackedByteArray) -> void:
	if _channel == null or _channel.get_ready_state() != WebRTCDataChannel.STATE_OPEN:
		return
	_channel.put_packet(buf)


func _shutdown_link() -> void:
	_channel = null
	_channel_open = false
	_peer = null
	_local_sdp = ""
	_local_kind = ""
	_remote_ready = false
	_pending_ice.clear()
	_link_msec = 0
	_offer_sent = false
	_join_ref = ""
	socket_ready = false
	_remote_sdp = ""
	_local_ice.clear()
	_desync_sent = false
	if _ws != null:
		_ws.close()
		_ws = null


func _first_row(parsed) -> Dictionary:
	if parsed is Array and not (parsed as Array).is_empty() and parsed[0] is Dictionary:
		return parsed[0]
	if parsed is Dictionary and parsed.has("code"):
		return parsed
	return {}


func _text(value) -> String:
	if value == null:
		return ""
	var text := str(value)
	if text == "<null>":
		return ""
	return text


func _client_id() -> String:
	if client_id != "":
		return client_id
	var path := "user://client_id.txt"
	if FileAccess.file_exists(path):
		client_id = FileAccess.get_file_as_string(path).strip_edges()
	if client_id == "":
		client_id = "%d-%d" % [Time.get_unix_time_from_system(), randi()]
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(client_id)
	return client_id


func _make_code() -> String:
	var out := ""
	for _i in 4:
		out += _ALPHABET[randi() % _ALPHABET.length()]
	return out


func _next_ref() -> String:
	_msg_ref += 1
	return str(_msg_ref)


func _set_notice(text: String) -> void:
	notice = text
	notice_changed.emit(text)


func _write_u16(buf: PackedByteArray, value: int) -> void:
	buf.append(value & 255)
	buf.append((value >> 8) & 255)


func _write_u32(buf: PackedByteArray, value: int) -> void:
	buf.append(value & 255)
	buf.append((value >> 8) & 255)
	buf.append((value >> 16) & 255)
	buf.append((value >> 24) & 255)


func _write_i16(buf: PackedByteArray, value: int) -> void:
	if value < 0:
		value += 65536
	_write_u16(buf, value)


func _read_u16(buf: PackedByteArray, at: int) -> int:
	return buf[at] | (buf[at + 1] << 8)


func _read_u32(buf: PackedByteArray, at: int) -> int:
	return buf[at] | (buf[at + 1] << 8) | (buf[at + 2] << 16) | (buf[at + 3] << 24)


func _read_i16(buf: PackedByteArray, at: int) -> int:
	var value := _read_u16(buf, at)
	if value >= 32768:
		value -= 65536
	return value
