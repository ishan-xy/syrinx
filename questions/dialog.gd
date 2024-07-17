extends Node

@export_file("*.json") var d_file
var dialogue = []
var current_dialogue_id = 0
var d_active = false
var question: TextEdit
var answer: TextEdit
var submit: Button
@export var websocket_url = "ws://localhost:8000"
var socket = WebSocketPeer.new()
#var post_url = "http://example.com/submit"

# Called when the node enters the scene tree for the first time.
func _ready():
	question = $question
	answer = $answer
	submit = $submit
	#$NinePatchRect.visible = false
	#submit.visible = false
	#question.visible = false
	#answer.visible = false
	var err=socket.connect_to_url(websocket_url)	
	if err!=OK:
		print("unable to connect")
		set_process(false)
	d_file = "res://questions/json/questions.json"
	
	
func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			var packet = socket.get_packet()
			if packet.size() > 0:
				var reply = packet.get_string_from_utf8()
				print(reply)
	elif state == WebSocketPeer.STATE_CLOSING:
		# Keep polling to achieve proper close.
		pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code = socket.get_close_code()
		var reason = socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) 
	
func start():
	if d_active:
		return
	d_active = true
	submit.visible = true
	question.visible = true
	answer.visible = true
	$NinePatchRect.visible = true
	dialogue = load_dialogue()
	current_dialogue_id = -1
	next_script()

func load_dialogue():
	var file = FileAccess.open(d_file, FileAccess.READ)
	if file.file_exists(d_file):
		var content = file.get_as_text()
		return JSON.parse_string(content)

func _input(event):
	if not d_active:
		return
	if event.is_action_pressed("ui_accept"):
		next_script()

func next_script():
	current_dialogue_id += 1
	if current_dialogue_id >= len(dialogue):
		$Timer.start()
		$NinePatchRect.visible = false
		submit.visible = false
		question.visible = false
		answer.visible = false
		return
	question.text = dialogue[current_dialogue_id]['question']

func _on_timer_timeout():
	d_active = false

func _on_submit_button_down():
	var ans = $answer.text
	# Now send this answer to the WebSocket server to check the answer
	var string = {
		"QuestionID": "questionId",
		"Answer": ans
	}
	
	var json_string = JSON.stringify(string)
	#print(json_string)
	var byte_array = json_string.to_utf8_buffer()
	#print(byte_array)
	socket.send(byte_array, WebSocketPeer.WRITE_MODE_BINARY)
