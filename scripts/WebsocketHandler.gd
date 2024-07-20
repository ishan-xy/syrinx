extends Node2D

var httpRequest := HTTPRequest.new()
var clients: PackedByteArray = []
var Username := "ishansingla"
var Password := "12345678"

func _ready() -> void:
	add_child(httpRequest)
	set_physics_process(false)
	_auth()

func _auth_error(error: String) -> void:
	print_debug("auth error: ", error)

func _lobby_error(error: String) -> void:
	print_debug("lobby error: ", error)

func _auth() -> void:
	httpRequest.request_completed.connect(_on_auth_response)
	print("authenticating")
	var err := httpRequest.request("http://127.0.0.1:8080/authanticate", [], HTTPClient.METHOD_POST, JSON.stringify({"Username": Username, "Password":Password}))
	if err != OK: return _auth_error("_auth: Error while sending request / Connection error")

var SessionIDBodyString: String
var SessionID: PackedByteArray
func _on_auth_response(result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != OK: return _auth_error("Http response error, result error: "+str(result))
	#if response_code != 200: _auth_error("Http response error, response code: "+str(response_code))
	SessionIDBodyString = body.get_string_from_ascii()
	var json: Dictionary = JSON.parse_string(body.get_string_from_ascii())
	if json == null: return _auth_error("Json parse error")
	elif json.has("error"): return _auth_error("Server error:\n" + str(json["error"]))
	elif !json.has("SessionID"): return _auth_error("Mendatory key SessionID not found")
	SessionID = json["SessionID"]
	
	httpRequest.request_completed.disconnect(_on_auth_response)
	httpRequest.request_completed.connect(_on_lobby_response)
	httpRequest.request("http://127.0.0.1:8080/getlobby", [], HTTPClient.METHOD_POST, SessionIDBodyString)

var LobbyID: String
var wsConn := WebSocketClient.new()
func _on_lobby_response(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.parse_string(body.get_string_from_ascii())
	if json == null: return _lobby_error("Json parse error")
	elif json.has("error"): return _lobby_error("Server error:\n" + str(json["error"]))
	elif !json.has("LobbyID"): return _lobby_error("Mendatory key LobbyID not found")
	LobbyID = json["LobbyID"]
	print(LobbyID)
	wsConn.connection_established.connect(_on_ws_ready)
	set_physics_process(true)
	print("Connected to Lobby")
	wsConn.connection_closed.connect(_connect_to_lobby)
	_connect_to_lobby()

func _connect_to_lobby() -> void:
	wsConn.connect_to_url("ws://127.0.0.1:8080/lobby/" + LobbyID)

	#$"../Control".queue_free()

func _on_ws_ready(_peer: WebSocketPeer, _protocol: String) -> void:
	wsConn.send(SessionID)
	print("Questions Websocket Connected")
	wsConn.data_received.connect(_on_data_recieved)

var myIndex: int = -1
signal data_recieved(String)
func _on_data_recieved(_peer : WebSocketPeer, message, _is_string : bool) -> void:
	data_recieved.emit(	message.get_string_from_ascii())

	print(message.get_string_from_ascii())

func _physics_process(_delta) -> void:
	wsConn.poll()
