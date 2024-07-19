extends Node

var questions = {}
var wsConn
signal question_updated(question_id: int, label: RichTextLabel)

func _ready() -> void:
	# Connect to the signal from all question areas
	for area in get_tree().get_nodes_in_group("QuestionAreas"):
		print("Node Connected")
		area.connect("player_entered_area", _on_player_entered_area)

func fetch_question_by_id(question_id: int, label: RichTextLabel) -> void:
	if question_id in questions:
		label.text = questions[question_id].text
	else:
	#fetch question from db
		var question
		wsConn.send(question_id)
		while wsConn.get_available_packet_count():
			var packet = wsConn.get_packet()
			question=packet.get_string_from_ascii()
		print(question)
		if(question):
			_on_request_completed(question,question_id,label)

func _on_request_completed(result, question_id, label) -> void:
	var question = Question.new(question_id, result)
	questions[question.id] = question
	label.text = question.text
	emit_signal("question_updated", question.id, label)

func _on_player_entered_area(question_id: int, label: RichTextLabel) -> void:
	#fetch_question_by_id(question_id, label)
	print("Fetch Question " + str(question_id))



	
	
#func _on_submit_button_down() -> void:
	#var ans: String = $answer.text
	## Now send this answer to the WebSocket server to check the answer
	#var string := {
		#"QuestionID": "questionId",
		#"Answer": ans
	#}
	#var json_string: Variant= JSON.stringify(string)
	##print(json_string)
	##var byte_array: Variant = json_string.to_utf8_buffer()
	##print(byte_array)
	#wsConn.send(json_string)
