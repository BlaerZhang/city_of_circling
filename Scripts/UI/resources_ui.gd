extends Control

@export var item_name: String
@onready var ui_icon:= $Icon
@onready var ui_icon_shadow:= $"Icon/Icon Shadow"
@onready var ui_label:= $ResourceTextLabel
@export var item_count_change_particle_prefab: PackedScene


func _ready() -> void:
	#Setup UI
	ui_icon.texture = ResourceManager.get_item_icon(item_name)
	ui_icon_shadow.texture = ui_icon.texture
	ui_label.text = '0'
	ui_icon.tooltip_text = item_name.capitalize()
	
	ResourceManager.item_count_changed.connect(on_item_count_changed)


func _process(delta: float) -> void:
	pass


func on_item_count_changed(changed_item_name: String, count: int, change_amount: int, source_pos: Vector2):
	if changed_item_name != item_name.to_lower(): return
	if change_amount > 0:
		spawn_particle(changed_item_name, change_amount, source_pos, ui_label.global_position)
		await get_tree().create_timer(1.5).timeout
		ui_label.text = str(count)
	elif change_amount < 0:
		ui_label.text = str(count)
		spawn_particle(changed_item_name, -change_amount, ui_label.global_position, source_pos)


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
		print("----Particle Spawn----")
		print("Start Pos: " + str(start_pos))
		print("End Pos: " + str(end_pos))
		print("Offset: " + str(start_pos - end_pos))
		await particle_instance.finished
		particle_instance.queue_free()
