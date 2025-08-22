extends RichTextLabel



func _ready() -> void:
	TimeManager.time_changed.connect(update_time)
	update_time()


func update_time():
	self.text = "[b]DAY %s\n%s:00[/b]" % [TimeManager.current_day, TimeManager.current_hour]
	tooltip_text = "%s hours until next shop refresh" % (8 - TimeManager.current_hour % 8)
