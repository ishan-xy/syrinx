extends Node

var questions = {}

signal question_updated(question_id: int, label: RichTextLabel)

func _ready() -> void:
	# Connect to the signal from all question areas
	for area in get_tree().get_nodes_in_group("QuestionAreas"):
		print("Node Connected")
		area.connect("player_entered_area", _on_player_entered_area)

func fetch_question_by_id(question_id: int, label: RichTextLabel) -> void:
# if ques_id in questions:
#	label.text = questions[question_id].text
#else:
#	fetch question from db
	pass

func _on_request_completed(result, response_code, headers, body, question_id, label) -> void:
#	if result is OK:
#		var question = Question.new(question_data.id, question_data.text)
#		questions[question.id] = question
#		label.text = question.text
#		emit_signal("question_updated", question.id, label)
	pass

func _on_player_entered_area(question_id: int, label: RichTextLabel) -> void:
	#fetch_question_by_id(question_id, label)
	print("Fetch Question " + str(question_id))

