class_name WheelManager
extends Control

enum button_state{
	free,
	draw_coupon,
	shop
}

@onready var wheel_face := $"Wheel Face"
@onready var spin_button := $"Spin Button"
@onready var spin_button_label := $"Spin Button/ButtonSprite/ButtonLabel"
@onready var spin_button_animation_tree := $"Spin Button/ButtonSprite/AnimationTree"
@onready var pointer := $Pointer
@onready var confirm_window := $"Confirm Window"
@onready var confirm_window_result_text := $"Confirm Window/Result Text"
@export var hide_y_offset := 1000.0
@export var show_y_offset := 648.0
@export var spin_animation_duration := 3.0
@export var spin_animation_duration_after_day3 := 1.0
var _button_state := button_state.free
var is_in_draw = false:
	set(value):
		spin_button.disabled = value
		is_in_draw = value
var spin_speed_up:= false
var is_mouse_over:= false
signal draw_finished
signal choice_made
signal choice_finished


func _ready() -> void:
	position.y = hide_y_offset
	TimeManager.day_3.connect(func(): spin_speed_up = true)
	#confirm_window.scale = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if GameManager.current_game_state != GameManager.GameState.Draw: return
	if event.is_action_pressed("left_click") && !is_mouse_over:
		if not wheel_face._is_spinning && not is_in_draw && not _button_state == button_state.free:
			spin_button.disabled = true
			hide_ui(self)


func initiate_wheel(source: PrizeItems.Source):
	wheel_face.setup_wheel(source)
	is_in_draw = false
	show_ui(self)


func hide_ui(object):
	var hide_tween:= create_tween()
	hide_tween.tween_property(object, "position:y", hide_y_offset, 0.5).set_trans(Tween.TRANS_EXPO)
	hide_tween.tween_callback(draw_finished.emit)


func show_ui(object):
	GameManager.switch_game_state(GameManager.GameState.Draw)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SHOW_WHEEL)
	var hide_tween:= create_tween()  
	hide_tween.tween_property(object, "position:y", show_y_offset, 0.5).set_trans(Tween.TRANS_EXPO)
	_button_state = button_state.free
	spin_button_label.text = "GO"


func resolve_result(prize_item: PrizeItems):
	for item in prize_item.item_list.keys():
		var item_count: int
		if ResourceManager.item_database[item].item_type == Item.ItemType.Fruit:
			item_count = prize_item.item_list[item] + UpgradeManager.get_upgrade_level("fruit production +") * UpgradeManager.upgrade_database["fruit production +"].effect_delta_per_level
		else:
			item_count = prize_item.item_list[item]
		ResourceManager.change_item_count(item, item_count, pointer.global_position)
		
	if prize_item.item_list.has("draw coupon"):
		await get_tree().create_timer(1).timeout
		if spin_speed_up:
			wheel_face.spin_wheel(spin_animation_duration_after_day3)
		else:
			wheel_face.spin_wheel(spin_animation_duration)
		await wheel_face.on_end_spin
	
	if prize_item.item_list.has("fruit of your choice"):
		var choice_count: int = prize_item.item_list["fruit of your choice"]
		for i in choice_count:
			await choice_made
		choice_finished.emit()
		await get_tree().create_timer(1).timeout
	
	if prize_item.item_list.has("upgrade coupon of your choice"):
		var choice_count: int = prize_item.item_list["upgrade coupon of your choice"]
		for i in choice_count:
			await choice_made
		choice_finished.emit()
		await get_tree().create_timer(1).timeout


func _on_wheel_face_on_end_spin(prize_item: PrizeItems) -> void:
	await resolve_result(prize_item)
	if prize_item.item_list.has("draw coupon"): return
	spin_button_animation_tree.set("parameters/conditions/is_spin_end", true)
	spin_button_animation_tree.set("parameters/conditions/is_pressed", false)
	is_in_draw = false
	#stay and update button text if (origin == shop && exchange_coupon.count >= 3) or (origin == fruit && draw_coupon.count > 0) 
	match wheel_face.current_source:
		PrizeItems.Source.Banana, PrizeItems.Source.Grape, PrizeItems.Source.Apple, PrizeItems.Source.Mango, PrizeItems.Source.Watermelon, PrizeItems.Source.Strawberry:
			if (ResourceManager.get_item_count("draw coupon") > 0):
				_button_state = button_state.draw_coupon
				spin_button_label.text = "[img=150x150]res://Assets/Sprites/Icon/1x/draw coupon italic.png[/img] [font_size=100]x[/font_size]1"
			else:
				hide_ui(self)
		PrizeItems.Source.Traffic, PrizeItems.Source.Affairs, PrizeItems.Source.Lottery, PrizeItems.Source.Trade, PrizeItems.Source.Traffic_Locked:
			if (ResourceManager.get_item_count("exchange coupon") >= 3):
				_button_state = button_state.shop
				spin_button_label.text = "[img=150x150]res://Assets/Sprites/Icon/1x/exchange coupon italic.png[/img] [font_size=100]x[/font_size]3"
			else:
				hide_ui(self)


func _on_spin_button_pressed() -> void:
	if (wheel_face._is_spinning): return
	match _button_state:
		button_state.free:
			is_in_draw = true
			spin_button_animation_tree.set("parameters/conditions/is_pressed", true)
			spin_button_animation_tree.set("parameters/conditions/is_spin_end", false)
			wheel_face.spin_wheel(spin_animation_duration)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SPIN_START)
		button_state.draw_coupon:
			if (ResourceManager.try_pay_item('draw coupon', 1, spin_button.global_position)):
				is_in_draw = true
				spin_button_animation_tree.set("parameters/conditions/is_pressed", true)
				spin_button_animation_tree.set("parameters/conditions/is_spin_end", false)
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SPIN_START)
				#await get_tree().create_timer(1).timeout
				if spin_speed_up:
					wheel_face.spin_wheel(spin_animation_duration_after_day3)
				else:
					wheel_face.spin_wheel(spin_animation_duration)
		button_state.shop:
			if (ResourceManager.try_pay_item('exchange coupon', 3, spin_button.global_position)):
				is_in_draw = true
				spin_button_animation_tree.set("parameters/conditions/is_pressed", true)
				spin_button_animation_tree.set("parameters/conditions/is_spin_end", false)
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SPIN_START)
				#await get_tree().create_timer(1).timeout
				if spin_speed_up:
					wheel_face.spin_wheel(spin_animation_duration_after_day3)
				else:
					wheel_face.spin_wheel(spin_animation_duration)


func _on_close_button_pressed() -> void:
	hide_ui(self)


func _on_mouse_entered() -> void:
	is_mouse_over = true
	#print("Mouse Enter Face")


func _on_mouse_exited() -> void:
	is_mouse_over = false
	#print("Mouse Exit Face")


func _on_spin_button_mouse_entered() -> void:
	spin_button_animation_tree.set("parameters/conditions/is_hovering", true)
	spin_button_animation_tree.set("parameters/conditions/is_not_hovering", false)


func _on_spin_button_mouse_exited() -> void:
	spin_button_animation_tree.set("parameters/conditions/is_hovering", false)
	spin_button_animation_tree.set("parameters/conditions/is_not_hovering", true)
