extends Node2D

# TODO: Implement manual syncronization of player's properties

# TODO: encode player's animation info etc into 2 bytes short for multiplayer
# 2 bits for movement direction, 3 for action 1 for movement direction,
# 10 for delta (+- 4 blocks) subdevided into 2^7 (128) parts
# WARNING: this may become a problem as delta's need to be sent in-order
# WARNING: we need to sync posotion (once per second) in as this is not precise


# This is to be used for testing only
const IS_SERVER: bool = false
#func _ready():
	#if IS_SERVER:
		#_on_host_pressed()
	#else:
		#_on_join_pressed()

# server's port
const PORT = 3001

# ENetMultiplayerPeer is faster but incompatiblle with browsers
var peer := WebSocketMultiplayerPeer.new()

# WARNING: `player_scene` has to be set in the ui of "Multiplayer Syncronizer"
@export var player_scene: PackedScene

func _on_host_pressed():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$Camera2D.enabled = false

func _on_join_pressed():
	peer.create_client("ws://127.0.0.1:"+str(PORT)+"/")
	multiplayer.multiplayer_peer = peer
	$Camera2D.enabled = false

func add_player(id = 1):
	var player := player_scene.instantiate()
	player.name = str(id)
	call_deferred("add_child", player)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local") func _del_player(id):
	get_node(str(id)).queue_free()
