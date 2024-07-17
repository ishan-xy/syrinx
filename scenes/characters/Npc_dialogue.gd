extends Area2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and len(get_overlapping_bodies())>0:
		use_dialogue()

func use_dialogue() -> void:
	var dialogue := get_parent().get_node("Questions")
	if dialogue:
		dialogue.start()
