extends Node

var httpRequest := HTTPRequest.new()
func _ready() -> void:
	add_child(httpRequest)
	set_physics_process(false)
	httpRequest.request_completed.connect(_on_auth_response)

func _auth(Username: String, Password: String) -> void:
	httpRequest.request("http://127.0.0.1:8080/authanticate", [], HTTPClient.METHOD_POST, JSON.stringify({"Username": Username, "Password":Password}))

var SessionIDBodyString: String
var SessionID: PackedByteArray
func _on_auth_response(result: int = 0, response_code: int = 0, headers: PackedStringArray = [], body: PackedByteArray = []) -> void:
	SessionIDBodyString = body.get_string_from_ascii()
	var json: Variant = JSON.parse_string(body.get_string_from_ascii())
	if json == null:
		print("Error: _on_auth_response")
		return
	SessionID = json["SessionID"]
	
	httpRequest.request_completed.disconnect(_on_auth_response)
	httpRequest.request_completed.connect(_on_lobby_response)
	httpRequest.request("http://127.0.0.1:8080/getlobby", [], HTTPClient.METHOD_POST, SessionIDBodyString)

var LobbyID: String
func _on_lobby_response(result: int = 0, response_code: int = 0, headers: PackedStringArray = [], body: PackedByteArray = []) -> void:
	var json = JSON.parse_string(body.get_string_from_ascii())
	if json == null:
		print("Error: _on_lobby_response")
		return
	LobbyID = json["LobbyID"]
	_connect_to_lobby()

var wsConn := WebSocketClient.new()
var p1 := WebRTCPeerConnection.new()
var ch1 := p1.create_data_channel("chat", { "id": 1, "negotiated": true })
func _connect_to_lobby() -> void:
	wsConn.connect_to_url("ws://127.0.0.1:8080/lobby/" + LobbyID)
	set_physics_process(true)
	wsConn.connection_established.connect(_on_ws_ready)
	print(LobbyID)
	print(SessionID)
	#while true:
		#await get_tree().create_timer(1).timeout
		#print("WAIT!")
		#if wsConn.get_ready_state() == wsConn.STATE_OPEN:
			#return _on_ws_ready()

func _on_ws_ready(peer: WebSocketPeer, protocol: String) -> void:
	print("GOODCALL")
	wsConn.send(SessionID)
	wsConn.data_received.connect(_on_data_recieved)

	p1.session_description_created.connect(p1.set_local_description)
	p1.session_description_created.connect(send_description)
	p1.ice_candidate_created.connect(send_ice)
	#p1.create_offer()
	#ch1.put_packet("Hi from P1".to_utf8_buffer())

var myIndex: int = -1
var recievers: PackedByteArray = []
func _on_data_recieved(peer : WebSocketPeer, message, is_string : bool) -> void:
	if is_string:
		match message[0]:
			0:
				if len(message) == 2:
					myIndex = message[1]
				print_debug("Got error: ", message.slice(1).get_string_from_ascii())
			1:
				print_debug("Create offer request from: ", message[1])
				recievers.append(message[1])
				p1.create_offer()
			2:
				print_debug("Remove player form scene: ", message[1])
			3:
				print_debug("Got json data from peer: ", message[1])
				var json: Variant = JSON.parse_string(message.slice(2).get_string_from_ascii())
				if json == null:
					print_debug("Json parsing error or malformed data")
					return
				print_debug("Data: ", json)
				handle_packet(json)

func send_ice(media: String, index: int, name: String) -> void:
	var to := recievers[-1]
	recievers.remove_at(-1)
	wsConn.send(PackedByteArray([3]) + JSON.stringify({
		"packet": "ice",
		"media": media,
		"index": index,
		"name": name,
	}).to_ascii_buffer())

func send_description(type: String, sdp: String) -> void:
	var to := recievers[-1]
	recievers.remove_at(-1)
	wsConn.send(JSON.stringify({
		"packet": "ice",
		"type": type,
		"sdp": sdp,
	}).to_ascii_buffer())

func handle_packet(json: Variant) -> void:
	match json["packet"]:
		"description":
			p1.set_remote_description(json["type"], json["sdp"])
		"ice":
			p1.add_ice_candidate(json["media"], json["index"], json["name"])

func _physics_process(delta) -> void:
	wsConn.poll()
	pass
	#p1.poll()
	#if ch1.get_ready_state() == ch1.STATE_OPEN and ch1.get_available_packet_count() > 0:
		#print("P1 received: ", ch1.get_packet().get_string_from_utf8())
	#wsConn.poll()
	#var state = wsConn.get_ready_state()
	#if state == WebSocketPeer.STATE_OPEN:
		#while wsConn.get_available_packet_count():
			#var packet := wsConn.get_packet()
			#handle_packet(packet, wsConn.was_string_packet())
	#elif state == WebSocketPeer.STATE_CLOSED:
		#var code = wsConn.get_close_code()
		#var reason = wsConn.get_close_reason()
		#print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		#set_process(false)

