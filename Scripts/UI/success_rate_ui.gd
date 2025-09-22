extends RichTextLabel

var success_rate_tween: Tween
var current_displayed_success_rate: float
var is_tween_playing: bool
@export var points_uis: Array[Control]

func _ready() -> void:
	current_displayed_success_rate = PointManager.success_rate
	PointManager.points_changed.connect(func(_shop_type: ItemForSale.ShopType, _points: int): update_success_rate())
	PointManager.points_reset.connect(on_points_reset)
	text = tr("SUCCESS_RATE") % [current_displayed_success_rate * 100]
	is_tween_playing = false


func on_points_reset() -> void:
	# 重置成功率显示
	current_displayed_success_rate = 0.0
	text = tr("SUCCESS_RATE") % [0]
	# 停止正在进行的动画
	if success_rate_tween:
		success_rate_tween.kill()
	is_tween_playing = false


func update_success_rate():
	var target_rate = PointManager.success_rate
	
	# 如果目标值和当前值相同，直接更新文本，不做动画
	# if abs(target_rate - current_displayed_success_rate) < 0.001:
	# 	self.text = tr("SUCCESS_RATE") % [target_rate * 100]
	# 	return
	
	if success_rate_tween:
		success_rate_tween.kill()
	is_tween_playing = true
	success_rate_tween = create_tween()
	success_rate_tween.tween_interval(4)
	success_rate_tween.tween_callback(func(): is_tween_playing = false)
	success_rate_tween.tween_method(
		func(val: float): 
			self.text = tr("SUCCESS_RATE") % [val * 100]
			current_displayed_success_rate = val, 
		current_displayed_success_rate, 
		target_rate, 
		2.0
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)


func _notification(what : int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		update_success_rate()


func _on_mouse_entered() -> void:
	if is_tween_playing: return
	show_points_uis()


func _on_mouse_exited() -> void:
	if is_tween_playing: return
	hide_points_uis()


func show_ui():
	var show_tween = create_tween()
	show_tween.tween_property(self, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC)
	await show_tween.finished


func hide_ui():
	var hide_tween = create_tween()
	hide_tween.tween_property(self, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_ELASTIC)
	await hide_tween.finished


func show_points_uis():
	for points_ui in points_uis:
		points_ui.show_ui()


func hide_points_uis():
	for points_ui in points_uis:
		points_ui.hide_ui()
