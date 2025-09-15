extends FunctionalGridComponent

@export var prize_source: PrizeItems.Source
@onready var wheel_manager: WheelManager
var is_bypass_draw_unlocked:= false
var is_remote_draw_unlocked:= true

@export_group("UI Related")
@onready var lottery_preview:= $"Preview Icon"
var bypass_tween: Tween
var preview_target_scale: Vector2 = Vector2.ZERO


func _ready() -> void:
	await get_tree().process_frame
	wheel_manager = %"Spin Wheel"
	UpgradeManager.upgrade_added.connect(on_upgrade_added)


func bypass() -> void:
	if is_bypass_draw_unlocked:
		wheel_manager.initiate_wheel(prize_source)
		await wheel_manager.draw_finished


func arrive() -> void:
	wheel_manager.initiate_wheel(prize_source)
	await wheel_manager.draw_finished


func interact(base_grid_pos: Vector2) -> void:
	if (is_remote_draw_unlocked and ResourceManager.items_owned["draw coupon"] > 0) or is_player_arrived:
		#update preview
		try_interact(false)
		wheel_manager.initiate_wheel(prize_source, WheelManager.button_state.draw_coupon)
		await wheel_manager.draw_finished
		GameManager.switch_game_state(GameManager.GameState.Idle)


## 检查是否可以显示预览
func _can_show_preview_bypass() -> bool:
	return is_bypass_draw_unlocked

func _can_show_preview_interact() -> bool:
	return (is_remote_draw_unlocked and ResourceManager.items_owned["draw coupon"] > 0) or is_player_arrived

## 统一的预览动画处理函数
func _animate_preview(is_shown: bool, can_show_condition: bool) -> void:
	if not can_show_condition and is_shown:
		_animate_preview_scale(Vector2.ZERO, Tween.EASE_IN)
		return
	
	var target_scale = Vector2(1.0, 1.4) if is_shown else Vector2.ZERO
	var ease_type = Tween.EASE_OUT if is_shown else Tween.EASE_IN
	_animate_preview_scale(target_scale, ease_type)

## 执行缩放动画
func _animate_preview_scale(target_scale: Vector2, ease_type: Tween.EaseType) -> void:
	if preview_target_scale == target_scale:
		return
	
	preview_target_scale = target_scale
	
	if bypass_tween and bypass_tween.is_valid():
		bypass_tween.kill()
	
	bypass_tween = create_tween()
	bypass_tween.tween_property(
		lottery_preview,
		"scale",
		target_scale,
		0.2
	).set_ease(ease_type).set_trans(Tween.TRANS_EXPO)

func try_bypass(forward: bool) -> void:
	_animate_preview(forward, _can_show_preview_bypass())

func try_arrive(should_arrive: bool) -> void:
	_animate_preview(should_arrive, true)  # arrive 总是可以显示

func try_interact(should_interact: bool) -> void:
	_animate_preview(should_interact, _can_show_preview_interact())


func on_upgrade_added(upgrade: Upgrade):
	match upgrade.upgrade_name:
		"lottery bypass":
			is_bypass_draw_unlocked = true
		"lottery remote draw":
			is_remote_draw_unlocked = true
