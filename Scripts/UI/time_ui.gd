extends RichTextLabel


func _ready() -> void:
	TimeManager.time_changed.connect(update_time)
	update_time()


func update_time():
	self.text = tr("TIME_DAY_HOUR_MINUTE") % [TimeManager.current_day, TimeManager.current_hour, TimeManager.current_minute]
	# self.text += tr("TIME_REFRESH") % [8 - TimeManager.current_hour % 8]
	#tooltip_text = "%s hours until next shop refresh" % (8 - TimeManager.current_hour % 8)


func _notification(what : int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_time()


func _on_add_hour_pressed() -> void:
	for i in 60:
		TimeManager.add_step_time()


func _on_add_minute_pressed() -> void:
	TimeManager.add_step_time()
