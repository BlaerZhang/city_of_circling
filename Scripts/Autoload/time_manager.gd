extends Node

@export var start_time: Vector3i = Vector3i(1, 19, 0)
var current_minute: int
var current_hour: int
var current_day: int
var current_subminute: int
var step_taken: int = 0

signal time_changed(day: int, hour: int, minute: int)
signal manual_refresh_refill_time(day: int)
signal wheel_speedup_time
signal shop_refresh_time
signal stepped(step: int)


func _ready() -> void:
	reset_data()
	SceneManager.scene_loaded_with_name.connect(on_scene_loaded_with_name)
	ResourceManager.item_count_changed.connect(on_item_count_changed)


func on_scene_loaded_with_name(scene_name: String):
	if scene_name != "Ending":
		reset_data()


func reset_data():
	current_minute = start_time.z
	current_hour = start_time.y
	current_day = start_time.x
	step_taken = 0
	manual_refresh_refill_time.emit()
	time_changed.emit()


func add_one_minute():
	current_minute += 1
	if current_minute >= 60:
		add_one_hour()
		current_minute = 0
	time_changed.emit()

	if step_taken == 72:
		wheel_speedup_time.emit()

	if step_taken % 8 == 0:
		shop_refresh_time.emit()
	
	if step_taken % 24 == 0:
		manual_refresh_refill_time.emit()


func add_one_hour():
	current_hour += 1
	if current_hour >= 24:
		add_one_day()
		current_hour = 0
	time_changed.emit()
	
	# if current_hour % 8 == 0:
	# 	shop_refresh_time.emit()


func add_one_day():
	current_day += 1
	time_changed.emit()


func add_step_time():
	step_taken += 1
	stepped.emit(step_taken)
	add_one_minute()


func on_item_count_changed(item_name: String, count: int, change_amount: int, source_pos: Vector2):
	if item_name == "mystery box" && change_amount > 0:
		add_step_time()
		add_step_time()