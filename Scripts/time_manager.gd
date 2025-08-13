extends Node

var current_hour: int
var current_day: int

signal day_changed


func _ready() -> void:
	current_hour = 0
	current_day = 1
	day_changed.emit()


func add_one_hour():
	current_hour += 1
	if current_hour >= 24:
		current_day += 1
		current_hour = 0
		day_changed.emit()
