extends Node

@export var total_days: int = 60
@export var grids: Array[Sprite2D]
@export var bg_color_palette: Array[Color]
@export var grid_color_palette: Array[Color]
@onready var ending_animation_player: AnimationPlayer = %EndingAnimationPlayer
@onready var background: TextureRect = $BG
@onready var bg_mask: Sprite2D = %"BG Mask"
var days_left: int
var success_rate: float
var daily_sr: float
var adventure_score: int = 0
var player_health: int = 3

var resolving:= false

func _ready() -> void:
	days_left = total_days - TimeManager.current_day
	success_rate = PointManager.success_rate
	daily_sr = solve_dsr_from_sr_and_d(success_rate, days_left)
	print(daily_sr)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		if not resolving: 
			resolving = true
			await resolve_day()
			resolving = false


func gain_adventure_score():
	adventure_score += 1


func resolve_day():
	days_left -= 1
	TimeManager.add_one_day()
	
	if try_daily_sr(daily_sr):
		gain_adventure_score()
		ending_animation_player.play("ending_grid_move")
		await ending_animation_player.animation_finished
		if days_left == 0:
			resolve_game(true)
	else:
		await take_damage()
		if player_health == 0:
			resolve_game(false)

func resolve_game(succeeded: bool):
	if succeeded:
		pass
	else:
		pass


func try_daily_sr(dsr: float) -> bool:
	return randf() < dsr


func take_damage():
	player_health -= 1


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
