extends RichTextLabel

var success_rate_tween: Tween
var current_displayed_success_rate: float

func _ready() -> void:
	current_displayed_success_rate = PointManager.success_rate
	PointManager.points_changed.connect(func(shop_type: ItemForSale.ShopType, points: int): update_success_rate())
	update_success_rate()


func update_success_rate():
	var target_rate = PointManager.success_rate
	
	# 如果目标值和当前值相同，直接更新文本，不做动画
	if abs(target_rate - current_displayed_success_rate) < 0.001:
		self.text = tr("SUCCESS_RATE") % [target_rate * 100]
		return
	
	if success_rate_tween:
		success_rate_tween.kill()
	
	success_rate_tween = create_tween()
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
