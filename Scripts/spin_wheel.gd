@tool
extends Control

@export var background_color: Color
@export var line_color: Color
@export var sector_color_palette: Array[Color]

@export var outer_radius: int = 256
@export var inner_radius: int = 64
@export var line_width: int = 4

var prize_item_label_scene = preload("res://Scenes/prize_item_rich_text_label.tscn")
@export var text_font: Font
@export var text_width: float = 36
@export var text_size: float = 16
@export var text_color: Color = Color.BLACK
@export var text_radius: float = 8

var prize_list: Array[PrizeItems]
@export var current_source: PrizeItems.Source:
	set(value):
		current_source = value
		load_prize_list(value)
var current_total_weight: float = 0.0


func _ready() -> void:
	load_prize_list(current_source) #for test
	pass

func _draw() -> void:
	#draw background
	draw_circle(Vector2.ZERO, outer_radius, background_color)
	
	#draw sectors and content
	var cumulative_weight := 0.0
	for i in len(prize_list):
		var prize_item = prize_list[i]
		var start_rads = TAU * cumulative_weight / current_total_weight
		cumulative_weight += prize_item.weight_in_pool
		var end_rads = TAU * cumulative_weight / current_total_weight
		var mid_rads = (start_rads + end_rads) / 2.0
		var radius_mid = (inner_radius + outer_radius) / 2
		
		var points_per_arc = 32
		var points_inner = PackedVector2Array()
		var points_outer = PackedVector2Array()
		
		for j in range(points_per_arc + 1):
			var angle = start_rads + j * (end_rads - start_rads) / points_per_arc
			points_inner.append(inner_radius * Vector2.from_angle(angle))
			points_outer.append(outer_radius * Vector2.from_angle(angle))
			
		points_outer.reverse()
		
		draw_polygon(
			points_inner + points_outer,
			PackedColorArray([sector_color_palette[i%len(sector_color_palette)]])
		)
		
		#var label_instance: RichTextLabel = prize_item_label_scene.instantiate()
		#label_instance.position = Vector2.from_angle(mid_rads) * radius_mid
		#label_instance.rotation = mid_rads
		#label_instance.text = prize_item.prize_name_text
		#add_child(label_instance)
		
	
		var text_size_factor = clampf(sqrt((end_rads - start_rads) * 4 / TAU), 0.5, 1)
		
		var font = ThemeDB.fallback_font
		var font_size = text_size * text_size_factor

		# 获取文本尺寸
		var text_size_vec = font.get_string_size(prize_item.prize_name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var ascent = font.get_ascent(font_size)

		# 水平居中 + 垂直居中修正
		var draw_offset = Vector2(-text_size_vec.x / 2.0, ascent / 2.0)

		# 设置局部变换（先平移再旋转）
		draw_set_transform(Vector2.from_angle(mid_rads) * radius_mid, mid_rads)

		# 使用左对齐 + 居中位置偏移绘制
		draw_string(
			font,
			draw_offset,
			prize_item.prize_name_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			font_size,
			text_color
		)

		draw_set_transform(Vector2.ZERO, 0.0)
		
	#draw separator lines
	for i in len(prize_list):
		var prize_item = prize_list[i]
		cumulative_weight += prize_item.weight_in_pool
		var end_rads = TAU * cumulative_weight / current_total_weight
		var radius_mid = (inner_radius + outer_radius) / 2
		var line_point = Vector2.from_angle(end_rads)
		
		draw_line(
			line_point * inner_radius,
			line_point * outer_radius,
			line_color,
			line_width,
			true
		)
		
	#draw inner & outer circle
	draw_arc(Vector2.ZERO, inner_radius, 0, TAU, 128, line_color, line_width, true)
	draw_arc(Vector2.ZERO, outer_radius, 0, TAU, 128, line_color, line_width, true)

func _process(delta: float) -> void:
	queue_redraw()	
	pass
	
func load_prize_list(source: PrizeItems.Source):
	#clear list
	prize_list.clear()
	
	#load from folder
	var dir = DirAccess.open("res://Resources/PrizeItems/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://Resources/PrizeItems/" + file_name
				var res:PrizeItems = load(path)
				if res:
					if res.sources_of_prize.has(source):
						prize_list.append(res)
			file_name = dir.get_next()
		dir.list_dir_end()
		
		update_current_total_weight()

func update_current_total_weight():
	if len(prize_list) > 0:
		current_total_weight = 0.0
		for prize_item in prize_list:
			current_total_weight += prize_item.weight_in_pool
