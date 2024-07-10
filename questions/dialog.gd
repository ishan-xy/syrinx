extends MarginContainer


@export_file("*.json") var d_file
var dialogue = []
var current_dialogue_id=0
var d_active=false

const max_width=256
# Called when the node enters the scene tree for the first time.
func _ready():
	$MarginContainer/TextEdit.visible=false
	$NinePatchRect.visible=false
	d_file = "res://questions/json/questions.json"


func start():
	if d_active:
		return
	d_active=true
	$MarginContainer/TextEdit.visible=true	
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
		$MarginContainer/TextEdit.visible=false	
		return
	$MarginContainer/Label.text=dialogue[current_dialogue_id]['question']
	$MarginContainer/Label.visibility_layer=false
	$MarginContainer/TextEdit.text=dialogue[current_dialogue_id]['question']
	
	await resized
	custom_minimum_size.x=min(size.x,max_width)
	if size.x> max_width:
		$MarginContainer/Label.autowrap_mode=TextServer.AUTOWRAP_WORD
		await resized
		await resized
		custom_minimum_size.y=size.y
	
	
		
func _on_timer_timeout():
	d_active=false
