class_name WheelManager
extends Control

enum button_state{
	free,
	draw_coupon,
	shop
}

@onready var wheel_face := $"Wheel Face"
@onready var spin_button := $"Spin Button"
@onready var pointer := $Pointer
@onready var confirm_window := $"Confirm Window"
@onready var confirm_window_result_text := $"Confirm Window/Result Text"
@export var hide_y_offset := 1000.0
@export var show_y_offset := 648.0
var _button_state := button_state.free

signal draw_finished


func _ready() -> void:
	position.y = hide_y_offset
	#confirm_window.scale = Vector2.ZERO


func _process(delta: float) -> void:
	if GameManager.current_game_state != GameManager.GameState.Draw: return
	#if (Input.is_action_just_pressed("test")):
		#wheel_face.setup_wheel(PrizeItems.Source.Affairs) #for test
		#show_ui(self)
	if Input.is_action_just_pressed("right_click"):
		if not wheel_face._is_spinning:
			hide_ui(self)


func initiate_wheel(source: PrizeItems.Source):
	wheel_face.setup_wheel(source)
	show_ui(self)


func hide_ui(object):
	var hide_tween:= create_tween()
	hide_tween.tween_property(object, "position:y", hide_y_offset, 0.5).set_trans(Tween.TRANS_EXPO)
	hide_tween.tween_callback(draw_finished.emit)


func show_ui(object):
	GameManager.switch_game_state(GameManager.GameState.Draw)
	
	var hide_tween:= create_tween()  
	hide_tween.tween_property(object, "position:y", show_y_offset, 0.5).set_trans(Tween.TRANS_EXPO)
	_button_state = button_state.free
	spin_button.text = "GO"
	spin_button.icon = null


func resolve_result(prize_item: PrizeItems):
	for item in prize_item.item_list.keys():
		var item_count = prize_item.item_list[item]
		ResourceManager.change_item_count(item, item_count, pointer.global_position)
		
	if prize_item.item_list.has("draw coupon"):
		await get_tree().create_timer(1.5).timeout
		wheel_face.spin_wheel()
		await wheel_face.on_end_spin


func _on_wheel_face_on_end_spin(prize_item: PrizeItems) -> void:
	#TODO: Resolve prize & particle animation
	await resolve_result(prize_item)
	
	spin_button.disabled = false
	#stay and update button text if (origin == shop && exchange_coupon.count >= 3) or (origin == fruit && draw_coupon.count > 0) 
	match wheel_face.current_source:
		PrizeItems.Source.Banana, PrizeItems.Source.Grape, PrizeItems.Source.Apple, PrizeItems.Source.Mango, PrizeItems.Source.Watermelon, PrizeItems.Source.Strawberry:
			if (ResourceManager.get_item_count("draw coupon") > 0):
				_button_state = button_state.draw_coupon
				spin_button.text = "-1"
				spin_button.icon = ResourceManager.get_item_icon("draw coupon")
			else:
				hide_ui(self)
		PrizeItems.Source.Traffic, PrizeItems.Source.Affairs, PrizeItems.Source.Lottery, PrizeItems.Source.Trade:
			if (ResourceManager.get_item_count("exchange coupon") >= 3):
				_button_state = button_state.shop
				spin_button.text = "-3"
				spin_button.icon = ResourceManager.get_item_icon("exchange coupon")
			else:
				hide_ui(self)


func _on_spin_button_pressed() -> void:
	if (wheel_face._is_spinning): return
	match _button_state:
		button_state.free:
			spin_button.disabled = true
			wheel_face.spin_wheel()
		button_state.draw_coupon:
			if (ResourceManager.try_pay_item('draw coupon', 1, spin_button.global_position)):
				spin_button.disabled = true
				await get_tree().create_timer(1.5).timeout
				wheel_face.spin_wheel()
		button_state.shop:
			if (ResourceManager.try_pay_item('exchange coupon', 3, spin_button.global_position)):
				spin_button.disabled = true
				await get_tree().create_timer(1.5).timeout
				wheel_face.spin_wheel()


func _on_close_button_pressed() -> void:
	hide_ui(self)
