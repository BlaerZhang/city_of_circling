extends Node


func _input(event: InputEvent) -> void:
	if OS.has_feature("editor"):
		if event.is_action_pressed("test_get_resources"):
			ResourceManager.get_all_resources(1)
		if event.is_action_pressed("test_add_hour"):
			TimeManager.add_one_hour()
