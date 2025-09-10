extends Node

var current_hour: int
var current_day: int

signal time_changed(day: int, hour: int)
signal day_changed(day: int)
signal day_9
signal shop_refresh_time


func _ready() -> void:
	reset_data()
	SceneManager.scene_loaded_with_name.connect(on_scene_loaded_with_name)


func on_scene_loaded_with_name(scene_name: String):
	if scene_name != "Ending":
		reset_data()


func reset_data():
	current_hour = 0
	current_day = 1
	day_changed.emit()
	time_changed.emit()


func add_step_hour():
	current_hour += 3
	if current_hour >= 24:
		current_day += 1
		current_hour = 0
		day_changed.emit()
		shop_refresh_time.emit()
		if current_day == 9:
			day_9.emit()
	time_changed.emit()
	
	# if current_hour % 8 == 0:
	# 	shop_refresh_time.emit()
