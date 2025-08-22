extends FunctionalGridComponent

@export var prize_source: PrizeItems.Source
@onready var wheel_manager: WheelManager
var is_bypass_draw_unlocked:= false

@export_group("UI Related")
@onready var lottery_preview:= $"Preview Icon"
var bypass_tween: Tween
var preview_target_scale: Vector2 = Vector2.ZERO


func _ready() -> void:
	wheel_manager = get_tree().root.get_node("Game2d/UI/Spin Wheel")
	UpgradeManager.upgrade_added.connect(on_upgrade_added)


func bypass() -> void:
	if is_bypass_draw_unlocked:
		wheel_manager.initiate_wheel(prize_source)
		await wheel_manager.draw_finished


func arrive() -> void:
	wheel_manager.initiate_wheel(prize_source)
	await wheel_manager.draw_finished


func try_bypass(forward: bool) -> void:
	if !is_bypass_draw_unlocked: return
	var new_target = Vector2(1.0, 1.4) if forward else Vector2.ZERO
	var ease = Tween.EASE_OUT if forward else Tween.EASE_IN
	
	if preview_target_scale == new_target:
		return
	preview_target_scale = new_target
		
	if bypass_tween and bypass_tween.is_valid():
		bypass_tween.kill()
		
	bypass_tween = create_tween()
	bypass_tween.tween_property(
		lottery_preview,
		"scale",
		new_target,
		0.2
	).set_ease(ease).set_trans(Tween.TRANS_EXPO)


func try_arrive(arrive: bool):
	var new_target = Vector2(1.0, 1.4) if arrive else Vector2.ZERO
	var ease = Tween.EASE_OUT if arrive else Tween.EASE_IN
	
	if preview_target_scale == new_target:
		return
	preview_target_scale = new_target
		
	if bypass_tween and bypass_tween.is_valid():
		bypass_tween.kill()
		
	bypass_tween = create_tween()
	bypass_tween.tween_property(
		lottery_preview,
		"scale",
		new_target,
		0.2
	).set_ease(ease).set_trans(Tween.TRANS_EXPO)


func on_upgrade_added(upgrade: Upgrade):
	if upgrade.upgrade_name == "lottery bypass":
		is_bypass_draw_unlocked = true
