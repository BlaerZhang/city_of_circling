extends CustomTooltip

@export var points_type: ItemForSale.ShopType
@onready var ui_icon: TextureRect = $Icon
@onready var ui_icon_shadow:= $"Icon/Icon Shadow"
@onready var ui_label:= $ResourceTextLabel
# @onready var ui_outline:= $"UI Grid Outline"
@export var item_count_change_particle_prefab: PackedScene

func _ready() -> void:
	#Setup UI
	ui_label.text = str(PointManager.get_points(points_type))
	ui_icon.tooltip_text = tr(ItemForSale.ShopType.keys()[points_type].to_upper()) + tr("PTS")
	ResourceManager.item_count_changed.connect(on_item_count_changed)


func on_item_count_changed(item_name: String, count: int, change_amount: int, source_pos: Vector2):
	if ResourceManager.get_item_pts_type(item_name) == points_type:
		if change_amount > 0:
			spawn_particle(item_name, change_amount, source_pos, ui_label.global_position)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)
			await get_tree().create_timer(1.5).timeout
			var scale_tween = create_tween()
			scale_tween.tween_property(self, "scale", Vector2.ONE * 1.25, 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
			scale_tween.tween_interval(0.25)
			scale_tween.tween_method(func(val: int): ui_label.text = str(val), ui_label.text.to_int(), PointManager.get_points(points_type), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
			scale_tween.tween_property(self, "scale", Vector2.ONE * 1, 0.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)
		elif change_amount <= 0:
			var scale_tween = create_tween()
			scale_tween.tween_property(ui_label, "text", str(PointManager.get_points(points_type)), 1.0).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
			#spawn_particle(changed_item_name, -change_amount, ui_label.global_position, source_pos)
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
