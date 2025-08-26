extends RichTextLabel



func _ready() -> void:
	TimeManager.time_changed.connect(update_time)
	update_time()


func update_time():
	self.text = tr("TIME_DAY_HOUR_REFRESH") % [TimeManager.current_day, TimeManager.current_hour, 8 - TimeManager.current_hour % 8]
	#tooltip_text = "%s hours until next shop refresh" % (8 - TimeManager.current_hour % 8)
