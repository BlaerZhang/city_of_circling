extends Node


#func _process(delta: float) -> void:
	#if OS.has_feature("editor"):
		#if Input.is_action_just_pressed("test_get_resources"):
			#ResourceManager.get_all_resources(1)
		#if Input.is_action_just_pressed("test_add_hour"):
			#TimeManager.add_one_hour()

func _input(event: InputEvent) -> void:
	if OS.has_feature("editor"):
		if event.is_action_pressed("test_get_resources"):
			ResourceManager.get_all_resources(1)
		if event.is_action_pressed("test_add_hour"):
			TimeManager.add_one_hour()
