# Question.gd
extends Resource

class_name Question

var id: int
var text: String

func _init(_id: int, _text: String):
	id = _id
	text = _text
