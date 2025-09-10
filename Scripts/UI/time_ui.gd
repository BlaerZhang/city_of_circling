extends RichTextLabel


func _ready() -> void:
	TimeManager.time_changed.connect(update_time)
	update_time()


func update_time():
	self.text = tr("TIME_DAY_HOUR") % [TimeManager.current_day, TimeManager.current_hour]
	# self.text += tr("TIME_REFRESH") % [8 - TimeManager.current_hour % 8]
	#tooltip_text = "%s hours until next shop refresh" % (8 - TimeManager.current_hour % 8)


func _notification(what : int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_time()
