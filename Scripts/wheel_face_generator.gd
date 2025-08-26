#@tool
extends Control

@export var weight_based_angle := true

@export_group("Color")
@export var background_color: Color
@export var line_color: Color
@export var sector_color_palette: Array[Color]

@export_group("Size")
@export var outer_radius: int = 256
@export var inner_radius: int = 64
@export var line_width: int = 4

var prize_items_label_scene = preload("res://Scenes/prize_item_rich_text_label.tscn")
@export_group("Text")
@export var text_font: Font
@export var text_width: float = -1
@export var text_size: float = 16
@export var text_color: Color = Color.BLACK
@export var text_radius: float = 8
@export_group("Icon")
@export var icon_height: float = 24.0
@export var icon_spacing: float = 4.0
@export var icon_radius: float = 8.0  # 控制图标沿半径的偏移


var prize_list: Array[PrizeItems]
var current_source: PrizeItems.Source
var _current_total_weight: float = 0.0
var _target_prize: PrizeItems
var _tween: Tween
var _is_spinning: bool = false
signal on_end_spin(prize_items: PrizeItems)

var _current_spinning_audio: AudioStreamPlayer

# -------------------- 绘制 --------------------
func _draw() -> void:
	draw_set_transform(pivot_offset, 0.0)
	# 背景
	draw_circle(Vector2.ZERO, outer_radius, background_color)

	var cumulative_weight := 0.0
	for i in range(prize_list.size()):
		var prize_items: PrizeItems = prize_list[i]

		# 根据模式计算扇区角度
		var start_rads: float
		var end_rads: float
		if weight_based_angle:
			start_rads = TAU * cumulative_weight / _current_total_weight
			cumulative_weight += prize_items.weight_in_pool
			end_rads = TAU * cumulative_weight / _current_total_weight
		else:
			start_rads = TAU * i / prize_list.size()
			end_rads = TAU * (i + 1) / prize_list.size()

		var mid_rads = (start_rads + end_rads) / 2.0
		var radius_mid = (inner_radius + outer_radius) / 2

		# 绘制扇区
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
			PackedColorArray([sector_color_palette[i % sector_color_palette.size()]])
		)

		# --- 绘制文字 ---
		#var text_size_factor = clampf(sqrt((end_rads - start_rads) * 4 / TAU), 0.5, 1)
		#var font = ThemeDB.fallback_font
		#var font_size = text_size * text_size_factor
		#var text_size_vec = font.get_string_size(prize_items.prize_name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		#var ascent = font.get_ascent(font_size)
		#var text_offset = Vector2(-text_size_vec.x / 2.0, ascent / 2.0)
		#draw_set_transform(Vector2.from_angle(mid_rads) * radius_mid + pivot_offset, mid_rads)
		#draw_string(font, text_offset, prize_items.prize_name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

		# --- 绘制图标 ---
		var icon_count = 0
		var scaled_widths: Array[float] = []
		for item: String in prize_items.item_list.keys():
			var count: int = prize_items.item_list[item]
			var icon_tex: Texture2D = ResourceManager.get_item_icon(item.to_lower())
			if icon_tex:
				var tex_size = icon_tex.get_size()
				var scale = icon_height / tex_size.y
				var new_width = tex_size.x * scale
				for k in count:
					scaled_widths.append(new_width)
					icon_count += 1

		var total_icon_width = 0.0
		for w in scaled_widths:
			total_icon_width += w
		if icon_count > 0:
			total_icon_width += (icon_count - 1) * icon_spacing

		var start_x = -total_icon_width / 2.0
		var current_x = start_x
		var radius_for_icons = (inner_radius + outer_radius)/2 - icon_radius  # 使用 icon_radius 调整位置

		for item: String in prize_items.item_list.keys():
			var count: int = prize_items.item_list[item]
			var icon_tex: Texture2D = ResourceManager.get_item_icon(item.to_lower())
			if icon_tex:
				var tex_size = icon_tex.get_size()
				var scale = icon_height / tex_size.y
				var draw_size = Vector2(tex_size.x * scale, icon_height)
				for k in count:
					var pos = Vector2(current_x, -draw_size.y)  # 底部对齐
					draw_set_transform(Vector2.from_angle(mid_rads) * radius_for_icons + pivot_offset, mid_rads + PI/2)
					draw_texture_rect(icon_tex, Rect2(pos, draw_size), false)
					current_x += draw_size.x + icon_spacing

		# 恢复默认变换
		draw_set_transform(pivot_offset, 0.0)

	# 绘制分隔线
	cumulative_weight = 0.0
	for i in range(prize_list.size()):
		var prize_items = prize_list[i]
		var end_rads: float
		if weight_based_angle:
			cumulative_weight += prize_items.weight_in_pool
			end_rads = TAU * cumulative_weight / _current_total_weight
		else:
			end_rads = TAU * (i + 1) / prize_list.size()
		var line_point = Vector2.from_angle(end_rads)
		draw_line(line_point * inner_radius, line_point * outer_radius, line_color, line_width, true)

	# 绘制内外圈
	draw_arc(Vector2.ZERO, inner_radius, 0, TAU, 128, line_color, line_width, true)
	draw_arc(Vector2.ZERO, outer_radius, 0, TAU, 128, line_color, line_width, true)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()


func get_random_angle_in_sector(target: PrizeItems) -> float:
	var cumulative := 0.0
	for i in range(prize_list.size()):
		var prize_items = prize_list[i]
		var start_rads: float
		var end_rads: float

		if weight_based_angle:
			start_rads = TAU * cumulative / _current_total_weight
			cumulative += prize_items.weight_in_pool
			end_rads = TAU * cumulative / _current_total_weight
		else:
			start_rads = TAU * i / prize_list.size()
			end_rads = TAU * (i + 1) / prize_list.size()

		if prize_items == target:
			return randf_range(start_rads, end_rads)
	return 0.0



func load_prize_list(source: PrizeItems.Source):
	#clear list
	prize_list.clear()
	
	#load from folder
	var folder := "res://Resources/PrizeItems/"
	var files := ResourceLoader.list_directory(folder)
	for file_name in files:
		if file_name.ends_with(".tres"):
			var path = folder + file_name
			var res: PrizeItems = ResourceLoader.load(path)
			if res:
				if res.sources_of_prize.has(source):
					prize_list.append(res)

		current_source = source
		update_current_total_weight()


func update_current_total_weight():
	if len(prize_list) > 0:
		_current_total_weight = 0.0
		for prize_items in prize_list:
			_current_total_weight += prize_items.weight_in_pool


func setup_wheel(prize_source: PrizeItems.Source):
	if _is_spinning: return
	rotation = 0.0
	load_prize_list(prize_source)
	queue_redraw()


func pick_random_prize() -> PrizeItems:
	var rand = randf() * _current_total_weight
	var cumulative := 0.0
	for prize_items in prize_list:
		cumulative += prize_items.weight_in_pool
		if rand <= cumulative:
			return prize_items
	return prize_list.back()


func spin_wheel(animation_duration: float = 3) -> void:
	if not is_inside_tree() or _is_spinning: return
	
	_is_spinning = true
	
	if _tween:
		_tween.kill()

	# 抽奖
	_target_prize = pick_random_prize()
	var target_angle = get_random_angle_in_sector(_target_prize)

	# 当前角度
	var current_rot = rotation
	# 多加几圈的随机旋转（完整圈数）
	var extra_rotations = randi_range(5, 10)
	var pointer_angle_offset = -TAU / 4  # 指针在12点方向
	var target_rot = current_rot - fposmod(current_rot, TAU) + extra_rotations * TAU - target_angle + pointer_angle_offset

	# 创建 Tween
	_tween = create_tween()
	# 第一段动画
	_tween.tween_property(self, "rotation", rotation - TAU / 12, animation_duration / 6) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)
	# 中途音效（会在第一段结束后执行）
	_tween.tween_callback(func(): _current_spinning_audio = AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SPINNING))
	# 第二段动画
	_tween.tween_property(self, "rotation", target_rot, animation_duration * 2/3) \
		.set_trans(Tween.TRANS_EXPO) \
		.set_ease(Tween.EASE_OUT)
	# 最后一段停顿
	_tween.tween_interval(animation_duration / 6)
	# 结束回调
	_tween.tween_callback(_on_spin_finished.bind(_target_prize))


func _on_spin_finished(prize_items: PrizeItems):
	_is_spinning = false
	print("Spin Wheel Result: " + prize_items.prize_name_text)
	on_end_spin.emit(prize_items)
	if _current_spinning_audio: _current_spinning_audio.volume_db = -9999999
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SPIN_END)
