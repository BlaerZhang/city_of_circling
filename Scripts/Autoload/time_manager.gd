extends Node

var current_timer: int
var current_hour: int
var current_day: int

signal time_changed(day: int, hour: int)
signal day_changed(day: int)
signal day_3
signal shop_refresh_time


func _ready() -> void:
	reset_data()
	SceneManager.scene_loaded_with_name.connect(on_scene_loaded_with_name)


func on_scene_loaded_with_name(scene_name: String):
	if scene_name != "Ending":
		reset_data()


func reset_data():
	current_timer = 0
	current_hour = 0
	current_day = 19
	day_changed.emit()
	time_changed.emit()


func add_one_hour():
	current_timer += 1
	current_hour += 1
	if current_timer >= 24:
		current_timer = 0
		day_changed.emit()
		if current_day == 3 :
			day_3.emit()
	if current_hour >= 60:
		current_hour = 0
		current_day += 1
	time_changed.emit()
	
	if current_hour % 8 == 0:
		shop_refresh_time.emit()
