extends Node
enum Message{
	id,
	join,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	removeLobby,
	checkIn
}

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}

var Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
@export var hostPort = 8914
func _ready():
	if "--server" in OS.get_cmdline_args():
		print("hosting on " + str(hostPort))
		peer.create_server(hostPort)
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message == Message.lobby:
				JoinLobby(data)
				
			if data.message == Message.offer || data.message == Message.answer ||data.message == Message.candidate:
				print("source id is " + str(data.orgPeer))
				sendToPlayer(data.peer, data)
			if data.message == Message.removeLobby:
				if lobbies.has(data.lobbyID):
					lobbies.erase(data.lobbyID)
	pass

func peer_connected(id):
	print("Peer Connected: " + str(id))
	users[id] = {
		"id" : id,
		"message" : Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf8_buffer())
	pass

func peer_disconnected(id):
	pass

func JoinLobby(user):
	var result = genRandomString()
	var lobbyID = user.lobbyValue
	if lobbyID == "":
		user.lobbyValue = result
		lobbyID = user.lobbyValue
		lobbies[lobbyID] = Lobby.new(user.id)
		print(lobbyID)
	var player = lobbies[lobbyID].AddPlayer(user.id, user.name)
	
	for p in lobbies[lobbyID].Players:
		
		var data = {
			"message" : Message.userConnected,
			"id" : user.id
		}
		sendToPlayer(p, data)
		
		var data2 = {
			"message" : Message.userConnected,
			"id" : p
		}
		sendToPlayer(user.id, data2)
		
		var lobbyInfo = {
			"message" : Message.lobby,
			"players" : JSON.stringify(lobbies[lobbyID].Players),
			"host" : lobbies[lobbyID].HostID,
			"lobbyValue" : user.lobbyValue
		}
		sendToPlayer(p, lobbyInfo)
	
	var data = {
		"message" : Message.userConnected,
		"id" : user.id,
		"host" : lobbies[lobbyID].HostID,
		"player" : lobbies[lobbyID].Players[user.id],
		"lobbyValue" : user.lobbyValue
	}
	sendToPlayer(user.id, data)

func sendToPlayer(userID, data):
	peer.get_peer(userID).put_packet(JSON.stringify(data).to_utf8_buffer())

func genRandomString():
	var result = ""
	for i in range(32):
		var index = randi() % Characters.length()
		result += Characters[index]
	return result

func startServer():
	peer.create_server(hostPort)
	print("Started Server")


func _on_start_server_button_down():
	startServer()
	pass # Replace with function body.


func _on_button_2_button_down():
	var message = {
		"message": Message.id,
		"data" : "test"
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.
