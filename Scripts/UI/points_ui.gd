extends CustomTooltip

@export var points_type: ItemForSale.ShopType
@onready var ui_icon: TextureRect = $Icon
@onready var ui_icon_shadow:= $"Icon/Icon Shadow"
@onready var ui_points_label:= $PointsTextLabel
@onready var ui_rating_label:= $PointsRatingLabel
# @onready var ui_outline:= $"UI Grid Outline"
var original_pos: Vector2
var show_hide_tween: Tween
var points_tween: Tween
@export var item_count_change_particle_prefab: PackedScene
@export var rating_to_color: Dictionary[Item.Rarity, Color] = {
	Item.Rarity.Common: Color.WHITE,
	Item.Rarity.Uncommon: Color.GREEN,
	Item.Rarity.Rare: Color.BLUE,
	Item.Rarity.Epic: Color.PURPLE,
	Item.Rarity.Legendary: Color.YELLOW,
}
@export var rating_division_dict: Dictionary[Item.Rarity, int] = {
	Item.Rarity.Legendary: 100,
	Item.Rarity.Epic: 75,
	Item.Rarity.Rare: 50,
	Item.Rarity.Uncommon: 25,
	Item.Rarity.Common: 0,
	
}

func _ready() -> void:
	#Setup UI
	ui_points_label.text = str(PointManager.get_points(points_type))
	# tooltip_text = tr(ItemForSale.ShopType.keys()[points_type].to_upper() + "_TITLE") + tr("PTS")
	ResourceManager.item_count_changed.connect(on_item_count_changed)
	original_pos = position
	position = Vector2(0, 0)


func on_item_count_changed(item_name: String, count: int, change_amount: int, source_pos: Vector2):
	if ResourceManager.get_item_pts_type(item_name) == points_type:
		if change_amount > 0:
			var current_pos = position
			position = original_pos
			spawn_particle(item_name, change_amount, source_pos, ui_points_label.global_position)
			position = current_pos
			await show_ui()
			if points_tween:
				points_tween.kill()
			points_tween = create_tween()
			points_tween.tween_interval(1.75)
			points_tween.tween_callback(func(): AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN))
			points_tween.tween_callback(func(): update_rating(get_rating(PointManager.get_points(points_type))))
			points_tween.tween_method(func(val: int): ui_points_label.text = str(val), ui_points_label.text.to_int(), PointManager.get_points(points_type), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
			points_tween.tween_interval(0.25)
			await points_tween.finished
			await hide_ui()
		elif change_amount <= 0:
			if points_tween:
				points_tween.kill()
			points_tween = create_tween()
			points_tween.tween_property(ui_points_label, "text", str(PointManager.get_points(points_type)), 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
			#spawn_particle(changed_item_name, -change_amount, ui_points_label.global_position, source_pos)
			#AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)
			#await get_tree().create_timer(1.5).timeout
			#AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)


func spawn_particle(item_name: String, change_amount: int, start_pos: Vector2, end_pos: Vector2):
	if item_count_change_particle_prefab:
		var key = item_name.to_lower()
		var particle_instance: GPUParticles2D = item_count_change_particle_prefab.instantiate()
		particle_instance.texture = ResourceManager.get_item_icon(key)
		particle_instance.amount = change_amount
		particle_instance.position = end_pos
		particle_instance.process_material = particle_instance.process_material.duplicate(true)
		particle_instance.process_material.set("emission_shape_offset", start_pos - end_pos)
		get_tree().root.add_child(particle_instance)
		particle_instance.emitting = true
		#debug
		#print("----Particle Spawn----")
		#print("Start Pos: " + str(start_pos))
		#print("End Pos: " + str(end_pos))
		#print("Offset: " + str(start_pos - end_pos))
		await particle_instance.finished
		particle_instance.queue_free()


func get_rating(points: int) -> Item.Rarity:
	for rarity_minimum_points in rating_division_dict.values():
		if points >= rarity_minimum_points:
			return rating_division_dict.find_key(rarity_minimum_points)
	return Item.Rarity.Common


func update_rating(rating: Item.Rarity):
	var rating_tween = create_tween()
	rating_tween.tween_property(self, "self_modulate", rating_to_color[rating], 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	var rating_text:= "D"
	match rating:
		Item.Rarity.Common:
			rating_text = "D"
		Item.Rarity.Uncommon:
			rating_text = "C"
		Item.Rarity.Rare:
			rating_text = "B"
		Item.Rarity.Epic:
			rating_text = "A"
		Item.Rarity.Legendary:
				rating_text = "S"
	ui_rating_label.text = rating_text


func show_ui():
	if show_hide_tween:
		show_hide_tween.kill()
	show_hide_tween = create_tween()
	show_hide_tween.tween_property(self, "position", original_pos, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	await show_hide_tween.finished


func hide_ui():
	if show_hide_tween:
		show_hide_tween.kill()
	show_hide_tween = create_tween()
	show_hide_tween.tween_property(self, "position", Vector2(0, 0), 0.25).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)
	# AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIDE_SHOP)
	await show_hide_tween.finished
