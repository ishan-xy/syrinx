extends Node

var questions = {}
var label : RichTextLabel
var ansNode : TextEdit
var submitBtn : Button
var _ques_id
var hintLabel
var err_solved: bool
func fetch_question_by_id(ques_id: int):
	if ques_id in questions:
		setQuestionText(ques_id)
		print("ques in dict")
	else:
		var wsConn = WebsocketHandler.wsConn
		print("fetching ques")
		WebsocketHandler.data_recieved.connect(_on_data_recieved.bind(ques_id))
		wsConn.send_text(JSON.stringify({"ID":ques_id}))
		
func _on_data_recieved(data, ques_id:int):
	WebsocketHandler.data_recieved.disconnect(_on_data_recieved.bind(ques_id))
	var json := JSON.new()
	var err = json.parse(data)
	if err == OK:
		var result = json.parse_string(data)
		if result.has("Question"):
			addQuestion(ques_id, str(result["Question"]))
			print(str(ques_id) + " " + str(result["Question"]))
		elif result.has("correct"):
			handleAnswerResponse(ques_id, bool(result["correct"]))
		elif result.has("Hint"):
			print(str(result["Hint"]))
			if questions.has(ques_id):
				questions[ques_id]._add_hint(str(result["Hint"]))
			hintLabel.text = "Hint: " + questions[ques_id].hintText
		elif result.has("Error"):
			if result["Error"] == "Solved":
				err_solved = true
				print(err_solved)
				setQuestionText(_ques_id)
			print(str(result["Error"]))
	else:
		print("JSON parse error: ", err)
		
func addQuestion(_id: int, _text: String) -> void:
	if _id not in questions:
		var quesObj = Question.new(_id, _text)
		questions[_id] = quesObj
		setQuestionText(_id)


func handleAnswerResponse(_id:int, ansflag:bool):
	if ansflag:
		questions[_id].isAnswered = true
		setQuestionText(_id,"",true)
	elif not ansflag:
		questions[_id].isAnswered = false
		setQuestionText(_id,"",true)
	

func setQuestionText(_ques_id: int, _user_ans: String = "", _is_submit:bool=false):
	if questions.has(_ques_id):
		if questions[_ques_id].isAnswered or err_solved:
			label.text = "You are Correct!"
			submitBtn.get_parent().visible = false
			ansNode.get_parent().visible = false
			questions[_ques_id].isAnswered = true
			err_solved = false
		else:
			if _is_submit:
				label.text = "You are wrong!"
				ansNode.get_parent().visible = false
				submitBtn.get_parent().visible = false
				_is_submit = false
			else:
				label.text = questions[_ques_id].text
				ansNode.get_parent().visible = true
				submitBtn.get_parent().visible = true
	
		ansNode.text = _user_ans
	elif err_solved:
		label.text = "You are Correct!"
		submitBtn.get_parent().visible = false
		ansNode.get_parent().visible = false
		err_solved = false
		

func OnPlayerAskHint(_hintLabel):
	hintLabel = _hintLabel
	if questions.has(_ques_id):
		if questions[_ques_id].hintText != "":
			_hintLabel.text = questions[_ques_id].hintText
			return
	WebsocketHandler.data_recieved.connect(_on_data_recieved.bind(_ques_id))
	WebsocketHandler.wsConn.send_text(JSON.stringify({"ID":_ques_id, "Hint":"true"}))
func OnPlayerEnter(question_id: int, _label: RichTextLabel, _submitBtn: Button, _user_ans: TextEdit) -> void:
	print("Fetch Question " + str(question_id))
	label = _label
	submitBtn = _submitBtn
	ansNode = _user_ans
	_ques_id = question_id
	fetch_question_by_id(question_id)

func OnPlayerToggle(question_id: int):
	fetch_question_by_id(question_id)

func OnPlayerSubmit(ques_id:int, _ansNode : TextEdit) -> void:
	var ans := _ansNode.text
	ans = ans.strip_edges().replace("\n", "")
	# Now send this answer to the WebSocket server to check the answer
	var string := {
		"ID": ques_id,
		"Answer": ans
	}
	var json_string: Variant= JSON.stringify(string)
	WebsocketHandler.data_recieved.connect(_on_data_recieved.bind(ques_id))
	WebsocketHandler.wsConn.send_text(json_string)
	if questions.has(ques_id):
		questions[ques_id].userAns = ans
