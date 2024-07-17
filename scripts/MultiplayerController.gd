extends Control

@export var Address := '127.0.0.1'
@export var port := 6969
@export var no_of_player_peers := 4
var peer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		hostGame()
		
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	return


# This gets called on the server and clients
func peer_connected(id: int) -> void:
	print("Player Connected " + str(id))
# This gets called on the server and clients
func peer_disconnected(id: int) -> void:
	print("Player Disconnected " + str(id))
	GameManager.Players.erase(id)
	var players := get_tree().get_nodes_in_group("Player")
	for i in players:
		i.queue_free()

# called only from clients
func connected_to_server() -> void:
	print("Connected to Server")
	SendPlayerInformation.rpc_id(1, $LineEdit.text, multiplayer.get_unique_id())

# called only from clients
func connection_failed() -> void:
	print("Couldn't Connect")

@rpc("any_peer")
func SendPlayerInformation(name, id) -> void:
	if !GameManager.Players.has(id):
		GameManager.Players[id] ={
			"name" : name,
			"id" : id,
			"score": 0
		}
	
	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[i].name, i)

@rpc("any_peer", "call_local")
func Startgame() -> void:
	var scene := load("res://scenes/environments/g_block.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

func hostGame() -> void:
	peer = ENetMultiplayerPeer.new()
	var error := peer.create_server(port, no_of_player_peers)
	if error != OK:
		print("cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for Players!")

func _on_host_button_down() -> void:
	hostGame()
	SendPlayerInformation($LineEdit.text, multiplayer.get_unique_id())
	pass # Replace with function body.


func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client(Address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	pass # Replace with function body.


func _on_start_game_button_down() -> void:
	Startgame.rpc()
	pass # Replace with function body.
