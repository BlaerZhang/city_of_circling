extends Node

@export var total_days: int = 60
@export var grids: Array[Sprite2D]
@export var bg_color_palette: Array[Color]
@export var grid_color_palette: Array[Color]
@onready var ending_animation_player: AnimationPlayer = %EndingAnimationPlayer
@onready var background: TextureRect = $BG
@onready var bg_mask: Sprite2D = %"BG Mask"
@onready var score_ui: RichTextLabel = %"Adventure Score UI"
@onready var score_delta_ui: RichTextLabel = %"Score Delta UI"
var days_left: int
var days_passed: int = 0
var success_rate: float
var daily_sr: float
var adventure_score: int = 0
var current_milestone: int = 0

@export_group("Health Related")
@export var max_player_health: int = 3
@export var hp_icons: Array[TextureRect]
@onready var hp_ui_parent: Control = %"HP UI"
var player_health: int = 3
@onready var hp_icon_texture: Texture2D = preload("res://Assets/Sprites/Icon/1x/suit_hearts.png")
@onready var damage_icon_texture: Texture2D = preload("res://Assets/Sprites/Icon/1x/suit_hearts_broken.png")

@export_group("Event Related")
@export var event_text_key_success_count: int = 40
@export var event_text_key_failure_count: int = 10
var event_text_key_failure_index_array: Array[int]
@onready var event_ui: RichTextLabel = %"Event UI"
@onready var event_location_ui: RichTextLabel = %"Location UI"

var resolving_step:= false
var ended: bool = false

func _ready() -> void:
	days_left = total_days - TimeManager.current_day
	days_passed = 0
	success_rate = PointManager.success_rate
	daily_sr = solve_dsr_from_sr_and_d(success_rate, days_left)
	current_milestone = 0
	adventure_score = 0
	player_health = max_player_health
	score_ui.text = str(adventure_score)
	score_delta_ui.text = ""
	event_location_ui.text = ""
	for i in range(event_text_key_failure_count):
		event_text_key_failure_index_array.append(i + 1)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		if not resolving_step and not ended: 
			resolving_step = true
			if days_left > 0 and player_health > 0:
				await resolve_day()
			elif player_health > 0:
				resolve_game(true)
			else:
				resolve_game(false)
			resolving_step = false
	
	if event.is_action_pressed("right_click"):
		if ended:
			SceneManager.change_scene("res://Scenes/translation_manager.tscn")


func gain_adventure_score():
	var score_delta = roundi((10 + (current_milestone - 1) * 40 + days_passed * 5) * randf_range(0.5, 2.0))
	adventure_score += score_delta
	score_delta_ui.text = "+" + str(score_delta)
	var score_tween = create_tween()
	score_tween.tween_property(score_delta_ui, "position:y", 200, 0).as_relative()
	score_tween.tween_property(score_delta_ui, "self_modulate", Color.WHITE, 0.25)
	score_tween.parallel().tween_property(score_delta_ui, "position:y", -100, 0.25).as_relative()
	score_tween.tween_callback(func(): score_delta_ui.text = "+" + str(score_delta))
	score_tween.tween_interval(0.25)
	score_tween.tween_property(score_delta_ui, "self_modulate", Color.TRANSPARENT, 0.25)
	score_tween.parallel().tween_property(score_delta_ui, "position:y", -100, 0.25).as_relative()
	score_tween.tween_method(func(val: int): score_ui.text = str(val), score_ui.text.to_int(), adventure_score, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	await score_tween.finished


func resolve_day():
	days_left -= 1
	days_passed += 1
	TimeManager.add_one_day()

	if days_passed % 10 == 1:
		current_milestone += 1
		update_stage_ui(current_milestone)
	
	if try_daily_sr(daily_sr):
		update_event(true, days_passed % 10 == 1)
		ending_animation_player.play("ending_grid_move")
		ending_animation_player.animation_finished
		await gain_adventure_score()
	else:
		update_event(false, days_passed % 10 == 1)
		await take_damage()


func resolve_game(succeeded: bool):
	ended = true
	update_stage_ui(current_milestone + 1)
	if succeeded:
		event_ui.self_modulate = Color.WHITE
		event_ui.text = ""
		event_location_ui.text = ""
		var event_end_tween = create_tween()
		event_end_tween.tween_property(event_ui, "text", tr("EVENT_SUCCESS"), 2)

		score_delta_ui.self_modulate = Color.WHITE
		score_delta_ui.text = ""
		var score_end_tween = create_tween()
		score_end_tween.tween_property(score_delta_ui, "position:y", 100, 0).as_relative()
		score_end_tween.tween_property(score_delta_ui, "text", tr("FINAL_SCORE"), 0.25)
	else:
		event_ui.self_modulate = Color.WHITE
		event_ui.text = ""
		var event_end_tween = create_tween()
		event_end_tween.tween_property(event_ui, "text", tr("EVENT_FAILURE"), 2)

		score_delta_ui.self_modulate = Color.WHITE
		score_delta_ui.text = ""
		var score_end_tween = create_tween()
		score_end_tween.tween_property(score_delta_ui, "position:y", 100, 0).as_relative()
		score_end_tween.tween_property(score_delta_ui, "text", tr("FINAL_SCORE"), 0.25)


func update_stage_ui(milestone: int):
	var stage_tween = create_tween().set_parallel(true)
	stage_tween.tween_property(bg_mask, "self_modulate", bg_color_palette[milestone - 1], 2)
	stage_tween.tween_property(background, "self_modulate", bg_color_palette[milestone - 1], 2)
	for grid in grids:
		stage_tween.tween_property(grid, "self_modulate", grid_color_palette[milestone - 1], 2)


func update_event(succeeded: bool, milestone_reached: bool = false):
	if milestone_reached: print("Milestone Reached: " + str(current_milestone))
	var event_tween = create_tween()
	event_tween.tween_property(event_ui, "self_modulate", Color.TRANSPARENT, 0.25)
	event_tween.parallel().tween_property(event_ui, "position:y", 50, 0.25).as_relative()
	event_tween.tween_callback(func(): update_event_text(succeeded))
	event_tween.tween_callback(func(): update_event_location(milestone_reached))
	event_tween.tween_callback(func(): event_location_ui.text = tr("EVENT_ARRIVE") + " " + tr("EVENT_LOCATION_" + str(current_milestone)) if milestone_reached else "")
	event_tween.tween_property(event_ui, "self_modulate", Color.WHITE, 0.25)
	event_tween.parallel().tween_property(event_ui, "position:y", -50, 0.25).as_relative()


func update_event_text(succeeded: bool):
	if succeeded:
		var event_index = days_passed if days_passed <= event_text_key_success_count else days_passed - event_text_key_success_count + 3
		event_ui.text = "EVENT_" + "SUCCESS_" + str(event_index)
	else:
		var event_index = event_text_key_failure_index_array.pick_random()
		event_text_key_failure_index_array.erase(event_index)
		event_ui.text = "EVENT_" + "FAILURE_" + str(event_index)


func update_event_location(milestone_reached: bool):
	if milestone_reached:
		event_location_ui.text = tr("EVENT_ARRIVE") + " " + tr("EVENT_LOCATION_" + str(current_milestone))
	else:
		event_location_ui.text = ""


func try_daily_sr(dsr: float) -> bool:
	return randf() < dsr


func take_damage():
	player_health -= 1
	hp_icons[player_health].texture = damage_icon_texture
	var damage_tween = create_tween()
	damage_tween.tween_property(background, "self_modulate", Color.RED, 0.1)
	damage_tween.parallel().tween_property(bg_mask, "self_modulate", Color.RED, 0.1)
	damage_tween.parallel().tween_property(hp_ui_parent, "modulate", Color.WHITE, 0.1)
	damage_tween.tween_property(background, "self_modulate", bg_color_palette[current_milestone - 1], 0.5)
	damage_tween.parallel().tween_property(bg_mask, "self_modulate", bg_color_palette[current_milestone - 1], 0.5)
	damage_tween.parallel().tween_property(hp_ui_parent, "modulate", Color.html("#EA5A47"), 0.5)
	damage_tween.tween_property(hp_icons[player_health], "position:y", -50, 0.5).as_relative()
	damage_tween.parallel().tween_property(hp_icons[player_health], "self_modulate", Color.TRANSPARENT, 0.25)
	await damage_tween.finished


## 根据冒险成功率(SR)和剩余天数(D)求解每日冒险成功率(DSR)
## @param SR: 冒险成功率 (Success Rate)
## @param D: 剩余天数 (Days Left)
## @param tolerance: 容差值，默认1e-12
## @param max_iterations: 最大迭代次数，默认200
## @return: 计算得出的每日冒险成功率(DSR)
func solve_dsr_from_sr_and_d(sr: float, d: int, tolerance: float = 1e-12, max_iterations: int = 200) -> float:
	# 特殊情况处理
	if d == 1:
		return sr
	if d == 2:
		# 原式化为 x = sqrt(SR)
		return sqrt(sr)
	
	# 计算系数
	var a: float = float(d - 1) * float(d - 2) / 2.0
	var b: float = -float(d) * float(d - 2)
	var c: float = float(d) * float(d - 1) / 2.0
	
	# 定义多项式函数P(x)
	var p_function = func(x: float) -> float:
		return pow(x, d - 2) * (a * x * x + b * x + c) - sr
	
	# 二分法求解
	var lo: float = 0.0
	var hi: float = 1.0
	
	# 检查边界值
	if p_function.call(lo) == 0:
		return lo
	if p_function.call(hi) == 0:
		return hi
	
	# 确保在[0,1]区间内有符号变化，否则在给定D的情况下SR超出可行范围
	if p_function.call(lo) * p_function.call(hi) > 0:
		push_error("在区间[0,1]内没有符号变化 — 对于给定的D值，SR超出可行范围")
		return 0.0
	
	# 二分法迭代
	for i in range(max_iterations):
		var mid: float = 0.5 * (lo + hi)
		var val: float = p_function.call(mid)
		
		if abs(val) < tolerance:
			return mid
		
		if p_function.call(lo) * val < 0:
			hi = mid
		else:
			lo = mid
	
	return 0.5 * (lo + hi)
