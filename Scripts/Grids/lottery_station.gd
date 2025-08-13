extends FunctionalGridComponent

@export var prize_source: PrizeItems.Source
@onready var wheel_manager: WheelManager
var is_bypass_draw_unlocked:= false

@export_group("UI Related")
@onready var lottery_preview:= $"Preview Icon"


func _ready() -> void:
	wheel_manager = get_tree().root.get_node("Game2d/UI/Spin Wheel")


func bypass() -> void:
	if is_bypass_draw_unlocked:
		wheel_manager.initiate_wheel(prize_source)
		await wheel_manager.draw_finished


func arrive() -> void:
	wheel_manager.initiate_wheel(prize_source)
	await wheel_manager.draw_finished


func try_bypass(forward: bool) -> void:
	if !is_bypass_draw_unlocked: return
	var tween = create_tween()
	if forward:
		tween.tween_property(lottery_preview, "scale", Vector2(1.0, 1.4), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	else:
		tween.tween_property(lottery_preview, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
