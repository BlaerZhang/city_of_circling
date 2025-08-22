extends CustomTooltip

@export var item_name: String
var item_type: Item.ItemType
@onready var ui_icon:= $Icon
@onready var ui_icon_shadow:= $"Icon/Icon Shadow"
@onready var ui_label:= $ResourceTextLabel
@onready var ui_outline:= $"UI Grid Outline"
@export var item_count_change_particle_prefab: PackedScene
var is_in_choice:= false


func _ready() -> void:
	item_type = ResourceManager.item_database[item_name.to_lower()].item_type
	
	#Setup UI
	ui_icon.texture = ResourceManager.get_item_icon(item_name)
	ui_icon_shadow.texture = ui_icon.texture
	ui_label.text = '0'
	ui_icon.tooltip_text = item_name.capitalize()
	
	#Setup Outline
	var outline_tween = create_tween().set_loops()
	outline_tween.tween_property(ui_outline, "modulate", Color.WHITE, 0.375).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	outline_tween.tween_interval(0.25)
	outline_tween.tween_property(ui_outline, "modulate", Color.TRANSPARENT, 0.375).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	toggle_outline(false)
	
	ResourceManager.item_count_changed.connect(on_item_count_changed)


func on_item_count_changed(changed_item_name: String, count: int, change_amount: int, source_pos: Vector2):
	if changed_item_name == item_name.to_lower():
		if change_amount > 0:
			spawn_particle(changed_item_name, change_amount, source_pos, ui_label.global_position)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)
			await get_tree().create_timer(1.5).timeout
			ui_label.text = str(count)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)
		elif change_amount < 0:
			ui_label.text = str(count)
			spawn_particle(changed_item_name, -change_amount, ui_label.global_position, source_pos)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)
			await get_tree().create_timer(1.5).timeout
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.RESOURCE_GAIN)
	elif changed_item_name == "fruit of your choice" && item_type == Item.ItemType.Fruit:
		if change_amount > 0:
			await get_tree().create_timer(1.5).timeout
			is_in_choice = true
			toggle_outline(true)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CHOICE_START)
		if count <= 0:
			is_in_choice = false
			toggle_outline(false)
	elif changed_item_name == "upgrade coupon of your choice" && item_type == Item.ItemType.Upgrade_Coupon:
		if change_amount > 0:
			await get_tree().create_timer(1.5).timeout
			is_in_choice = true
			toggle_outline(true)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CHOICE_START)
		if count <= 0:
			is_in_choice = false
			toggle_outline(false)


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


func toggle_outline(switch: bool):
	match switch:
		true:
			var show_outline_tween = create_tween()
			show_outline_tween.tween_property(ui_outline, "self_modulate", Color.WHITE, 0.1)
		false:
			var hide_outline_tween = create_tween()
			hide_outline_tween.tween_property(ui_outline, "self_modulate", Color.TRANSPARENT, 0.2)


func _on_gui_input(event: InputEvent) -> void:
	if !is_in_choice: return
	if event.is_action_pressed("left_click"):
		var item_to_pay: String
		match item_type:
			Item.ItemType.Fruit:
				item_to_pay = "fruit of your choice"
			Item.ItemType.Upgrade_Coupon:
				item_to_pay = "upgrade coupon of your choice"
		ResourceManager.try_buy_item(item_name.to_lower(), 1, item_to_pay.to_lower(), 1, %"Spin Wheel".pointer.global_position)
		#ResourceManager.change_item_count(item_name.to_lower(), 1, %"Spin Wheel".pointer.global_position)
		%"Spin Wheel".choice_made.emit()
