extends Node2D


@export_file("*.json") var d_file
var dialogue = []
var current_dialogue_id=0
var d_active=false
var question: TextEdit
var answer:TextEdit
var submit:Button
var post_url = "http://example.com/submit"
# Called when the node enters the scene tree for the first time.
func _ready():
	question=$question
	answer=$answer
	submit=$submit
	submit.visible=false
	question.visible=false
	answer.visible=false
	

	$NinePatchRect.visible=false
	d_file = "res://questions/json/questions.json"
	start()


func start():
	if d_active:
		return
	d_active=true
	submit.visible=true
	question.visible=true
	answer.visible=true
	
	$NinePatchRect.visible=true
	dialogue = load_dialogue()
	current_dialogue_id=-1
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
	
	current_dialogue_id+=1
	if current_dialogue_id>=len(dialogue):
		$Timer.start()
		$NinePatchRect.visible=false
		submit.visible=false
		question.visible=false
		answer.visible=false
		return
	question.text=dialogue[current_dialogue_id]['question']

func _on_timer_timeout():
	d_active=false

 # Replace with function body.

func _on_submit_button_down():
	var ans=$answer.text 
# now send this ans to web socket to server to check the ans
	print(ans)
	var http_request = $HTTPRequest
	var body={
		"user":"USERSID",
		"answer":ans
	}
	var json_body=JSON.stringify(body)
	var headers = ["Content-Type: application/json"]
	http_request.request(post_url,headers,HTTPClient.METHOD_POST,json_body)

func _on_http_request_request_completed(result, response_code, headers, body):
	if response_code==200:
		print("connected")
	else:
		print("not connected") # Replace with function body.
