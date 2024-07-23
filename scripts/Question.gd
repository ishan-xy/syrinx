# Question.gd
extends Resource

class_name Question

var id: int
var text: String
var hintText: String
var hintPoints: int
var isAnswered: bool
var userAns: String


func _init(_id: int, _text: String, _isAnswered: bool = false,  _userAns: String = ""):
	id = _id
	text = _text
	isAnswered = _isAnswered
	userAns = _userAns
