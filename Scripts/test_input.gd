extends Node


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("test_get_resources"):
		ResourceManager.get_all_resources(1)
	if Input.is_action_just_pressed("test_add_hour"):
		TimeManager.add_one_hour()
