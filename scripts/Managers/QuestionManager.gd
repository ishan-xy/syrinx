extends Node

var questions = {}
var label : RichTextLabel
func fetch_question_by_id(ques_id: int):
	if ques_id in questions:
		label.text = questions[ques_id].text
		print("ques in dict")
	else:
		var wsConn = WebsocketHandler.wsConn
		print("fetching ques")
		WebsocketHandler.data_recieved.connect(_on_data_recieved.bind(ques_id))
		wsConn.send_text(JSON.stringify({"ID":ques_id}))
		
func _on_data_recieved(data, ques_id:int):
	WebsocketHandler.data_recieved.disconnect(_on_data_recieved.bind(ques_id))

	#if data.type == Type.question:
	addQuestion(data, ques_id)
	#elif data.type == Type.ansresponse:
	
	
func addQuestion(quesText,ques_id) -> void:
	if ques_id not in questions:
		var quesObj = Question.new(ques_id, quesText)
		questions[ques_id] = quesObj
		label.text = quesObj.text

func OnPlayerEnter(question_id: int, _label: RichTextLabel) -> void:
	print("Fetch Question " + str(question_id))
	label = _label
	fetch_question_by_id(question_id)


func OnPlayerSubmit(ques_id:int, ansNode : TextEdit) -> void:
	var ans := ansNode.text
	# Now send this answer to the WebSocket server to check the answer
	var string := {
		"ID": ques_id,
		"Answer": ans
	}
	var json_string: Variant= JSON.stringify(string)
	WebsocketHandler.data_recieved.connect(_on_data_recieved.bind(ques_id))
	WebsocketHandler.wsConn.send_text(json_string)
	
