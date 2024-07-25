extends Node

var questions = {}
var label : RichTextLabel
var ansNode : TextEdit
var submitBtn : Button
var _ques_id: int
var hintLabel
var err_solved: bool

func _ready():
	WebsocketHandler.data_recieved.connect(_on_data_recieved)

func fetch_question_by_id(_id: int):
	_ques_id = _id
	if _id in questions and questions[_id].validate_text():
		setQuestionText(questions[_id])
		print("ques in dict")
	else:
		print("fetching ques")
		WebsocketHandler.wsConn.send_text(JSON.stringify({"ID":_id}))

func _on_data_recieved(data):
	#WebsocketHandler.data_recieved.disconnect(_on_data_recieved)
	var json := JSON.new()
	var err = json.parse(data)
	if err == OK:
		var result = json.parse_string(data)
		if result.has("Question"):
			handleQuestionResponse(_ques_id, str(result["Question"]))
		elif result.has("correct"):
			handleAnswerResponse(_ques_id, bool(result["correct"]))
		elif result.has("Hint"):
			handleHintResponse(_ques_id, str(result["Hint"]))
		elif result.has("Error"):
			handleErrorResponse(_ques_id, str(result["Error"]))
	else:
		print("JSON parse error: ", err)
		
func handleQuestionResponse(_id: int, _text: String) -> void:
	print(str(_id) + " " + _text)
	var quesObj = Question.new(_id, _text)
	if not _id in questions:
		questions[_id] = quesObj
	else:
		questions[_id].add_text(quesObj.text)
	setQuestionText(questions[_id])

func handleAnswerResponse(_id:int, ansflag:bool):
	if not _id in questions:
		questions[_id] = Question.new(_id, "", ansflag)
	questions[_id].isAnswered = ansflag
	if not ansflag:
		label.text = "You are Wromg!"
		await get_tree().create_timer(1).timeout
	setQuestionText(questions[_id])

func handleHintResponse(_id: int, _hint: String):
	print(_hint)
	if not questions.has(_id):
		questions[_id] = Question.new(_id)
	questions[_id].add_hint(_hint)
	hintLabel.text = "Hint: " + _hint

func handleErrorResponse(_id: int, _err: String):
	if _err == "Solved":
		if not _id in questions:
			questions[_id] = Question.new(_id)
		questions[_id].isAnswered = true
		setQuestionText(questions[_id])
	print(_err)

func setQuestionText(ques: Question):
	if ques.isAnswered:
		label.text = "You are Correct!"
		submitBtn.get_parent().visible = false
		ansNode.get_parent().visible = false
	else:
		label.text = ques.text
		ansNode.get_parent().visible = true
		submitBtn.get_parent().visible = true

		#else:
			#if _is_submit:
				#label.text = "You are wrong!"
				#ansNode.get_parent().visible = false
				#submitBtn.get_parent().visible = false
				#_is_submit = false
		#ansNode.text = _user_ans
	#elif err_solved:
		#label.text = "You are Correct!"
		#submitBtn.get_parent().visible = false
		#ansNode.get_parent().visible = false
		#err_solved = false


func OnPlayerAskHint(_hintLabel):
	hintLabel = _hintLabel
	if questions.has(_ques_id) and questions[_ques_id].validate_hint():
		_hintLabel.text = questions[_ques_id].hintText
		return
	WebsocketHandler.wsConn.send_text(JSON.stringify({"ID":_ques_id, "Hint":"true"}))

func OnPlayerEnter(question_id: int, _label: RichTextLabel, _submitBtn: Button, _user_ans: TextEdit) -> void:
	print("Fetch Question " + str(question_id))
	label = _label
	submitBtn = _submitBtn
	ansNode = _user_ans
	if label != null:
		label.text = "Loading..."
	fetch_question_by_id(question_id)

func OnPlayerToggle(question_id: int):
	label.text = "Loading..."
	fetch_question_by_id(question_id)

func OnPlayerSubmit(ques_id:int, _ansNode : TextEdit) -> void:
	_ques_id = ques_id
	var ans := _ansNode.text
	ans = ans.strip_edges().replace("\n", "")
	# Now send this answer to the WebSocket server to check the answer
	var string := {
		"ID": ques_id,
		"Answer": ans
	}
	var json_string: Variant= JSON.stringify(string)
	WebsocketHandler.wsConn.send_text(json_string)
	if questions.has(ques_id):
		questions[ques_id].userAns = ans
