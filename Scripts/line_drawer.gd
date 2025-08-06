class_name LineDrawer
extends Node2D

@export var outline_width: float = 5
@export var outline_color: Color = Color.BLACK
@export var inline_width: float = 10
@export var inline_color: Color = Color.WHITE
@export var point_radius: float = 10
@export var animation_duration: float = 0.25

@onready var line2d_outer: Line2D = $Line2D_Outer
@onready var line2d_inner: Line2D = $Line2D_Inner

# 数据层（用户逻辑点）
var target_points: Array[Vector2] = []


func _ready() -> void:
	line2d_inner.width = inline_width
	line2d_outer.width = inline_width + 2 * outline_width


func _process(delta: float) -> void:
	queue_redraw()


func _draw():
	for point in line2d_outer.points:
		draw_circle(point, point_radius + outline_width, outline_color)
		draw_circle(point, point_radius, inline_color)


# 供外部调用：添加新点
func add_draw_point(point: Vector2) -> void:
	target_points.append(point)
	update_line()


# 供外部调用：撤销最后一个点
func withdraw_point() -> void:
	if target_points.size() > 0:
		target_points.remove_at(target_points.size() - 1)
		update_line()


# 供外部调用：清除所有点
func finish_draw():
	target_points.clear()
	line2d_outer.clear_points()
	line2d_inner.clear_points()
	queue_redraw()


# 自动更新显示层，使其向 target_points 过渡
func update_line() -> void:
	var current_count = line2d_outer.get_point_count()
	var target_count = target_points.size()

	# 1. 移除多余点（动画后删除）
	if current_count > target_count:
		for i in range(current_count - 1, target_count - 1, -1):
			var from_point = line2d_outer.get_point_position(i)
			var to_point = line2d_outer.get_point_position(i - 1)
			var tween = create_tween()
			tween.tween_method(
				func(val): 
					line2d_outer.set_point_position(i, val),
				from_point, to_point, animation_duration
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.parallel().tween_method(
				func(val): 
					line2d_inner.set_point_position(i, val),
				from_point, to_point, animation_duration
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_callback(func():
				line2d_outer.remove_point(i)
				line2d_inner.remove_point(i)
				queue_redraw()
			)

	# 2. 添加新点
	elif current_count < target_count:
		for i in range(current_count, target_count):
			var from_point = target_points[i - 1] if i > 0 else target_points[i]
			line2d_outer.add_point(from_point)
			line2d_inner.add_point(from_point)
			var tween = create_tween()
			tween.tween_method(
				func(val): 
					line2d_outer.set_point_position(i, val),
				from_point, target_points[i], animation_duration
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.parallel().tween_method(
				func(val): 
					line2d_inner.set_point_position(i, val),
				from_point, target_points[i], animation_duration
			).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tween.tween_callback(queue_redraw)

	# 3. 如果数量相等，检查是否有位移变化（可选：为了支持更新点）
	else:
		for i in range(target_count):
			var current_point = line2d_outer.get_point_position(i)
			var target_point = target_points[i]
			if current_point != target_point:
				var tween = create_tween()
				tween.tween_method(
					func(val): 
						line2d_outer.set_point_position(i, val),
					current_point, target_point, animation_duration
				).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tween.parallel().tween_method(
					func(val): 
						line2d_inner.set_point_position(i, val),
					current_point, target_point, animation_duration
				).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tween.tween_callback(queue_redraw)
