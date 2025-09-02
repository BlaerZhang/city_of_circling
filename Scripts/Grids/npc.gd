class_name NPC
extends FunctionalGridComponent

enum npc_name{
	moleo,
	loogy,
	princess_pooch,
	puppy_kong,
	shoyu,
	boyler,
}

@export var npc: npc_name
var is_in_fruit_quest := false
var is_in_delivery_quest := false
var is_in_quest: bool:
	get:
		return is_in_fruit_quest or is_in_delivery_quest
		
var is_remote_quest_acceptance_unlocked:= false
var is_remote_quest_submission_unlocked:= false
		
@export_group("Fruit Quest")
@export_range(0.0, 1.0, 0.001) var fruit_quest_probability := 0.65
var delivery_quest_probability: float:
		get:
			return 1 - fruit_quest_probability
@export var required_fruit_type_1: String
@export var required_fruit_type_2: String
var fruit_quest_required_items: Dictionary[String, int]
@export var fruit_quest_reward_coupon_count: int = 2

@export_group("Delivery Quest")
@export var delivery_quest_reward_coupon_count: int = 1
var delivery_quest_available_npc_list: Array[npc_name]
var current_delivery_quest_target: npc_name
var current_delivery_sender_list: Dictionary[npc_name, Texture2D]
signal delivery_quest_generated(from: npc_name, to: npc_name, sender_icon: Texture2D)
signal delivery_quest_completed(from: npc_name, to: npc_name)

@export_group("UI Related")
@onready var bypass_submit_preview:= $"Preview Icon"
@onready var quest_status_icon:= $"Quest Icon"
@onready var delivery_sender_icon:= $"Delivery Sender"
@export var quest_status_sprite_new_quest: Texture2D
@export var quest_status_sprite_complete: Texture2D
@export var quest_status_sprite_delivery: Texture2D
@export var quest_status_sprite_fruit: Texture2D
var bypass_tween: Tween
var preview_target_scale: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("NPCs")
	for npc: NPC in get_tree().get_nodes_in_group("NPCs"):
		npc.delivery_quest_generated.connect(set_as_delivery_target)
		npc.delivery_quest_completed.connect(complete_delivery_quest)
		delivery_quest_available_npc_list.append(npc.npc)
	UpgradeManager.upgrade_added.connect(on_upgrade_added)
	ResourceManager.item_count_changed.connect(on_item_count_changed)
	
	quest_status_icon.texture = quest_status_sprite_new_quest
	
	#start quest_icon_tween
	var quest_icon_tween = create_tween().set_loops(-1)
	quest_icon_tween.tween_property(quest_status_icon, "position", Vector2(20,-20), 1).as_relative().set_trans(Tween.TRANS_QUAD)
	quest_icon_tween.tween_property(quest_status_icon, "position", Vector2(-20,20), 1).as_relative().set_trans(Tween.TRANS_QUAD)
	
	#start sender_icon_tween
	var sender_icon_tween = create_tween().set_loops(-1)
	sender_icon_tween.tween_callback(next_texture).set_delay(0.5)


func generate_random_quest():
	if is_in_quest: return
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ACCEPT_QUEST)
	if (randf() < fruit_quest_probability):
		generate_fruit_quest()
	else:
		generate_delivery_quest()


func generate_fruit_quest():
	is_in_fruit_quest = true
	fruit_quest_required_items.clear()
	fruit_quest_required_items[required_fruit_type_1] = 1
	fruit_quest_required_items[required_fruit_type_2] = 1
	
	#update icon
	quest_status_icon.texture = quest_status_sprite_complete if is_fruit_quest_submittable() else quest_status_sprite_fruit


func generate_delivery_quest():
	is_in_delivery_quest = true
	var _target = delivery_quest_available_npc_list[randi() % delivery_quest_available_npc_list.size()]
	while _target == npc:
		_target = delivery_quest_available_npc_list[randi() % delivery_quest_available_npc_list.size()]
	
	current_delivery_quest_target = _target
	delivery_quest_generated.emit(npc, _target, get_parent().texture)
	
	#update icon
	quest_status_icon.texture = quest_status_sprite_delivery


func set_as_delivery_target(from: npc_name, to: npc_name, sender_icon: Texture2D):
	if to == npc:
		current_delivery_sender_list.get_or_add(from, sender_icon)
		refresh_textures()
		
		#update icon
		delivery_sender_icon.visible = true
		delivery_sender_icon.texture = sender_icon


var current_icon_textures: Array[Texture2D]
var current_sender_icon_index: int = 0
func next_texture() -> void:
	if current_icon_textures.is_empty():
		return
	delivery_sender_icon.texture = current_icon_textures[current_sender_icon_index]
	current_sender_icon_index = (current_sender_icon_index + 1) % current_icon_textures.size()
func refresh_textures() -> void:
	current_icon_textures = current_delivery_sender_list.values()
	current_sender_icon_index = 0


func is_fruit_quest_submittable() -> bool:
	if not is_in_fruit_quest: return false
	
	for i in fruit_quest_required_items:
		if (ResourceManager.get_item_count(i) < fruit_quest_required_items[i]):
			return false
	return true


func try_complete_fruit_quest() -> bool:
	if not is_in_fruit_quest: return false
	if not is_fruit_quest_submittable(): return false
	for i in fruit_quest_required_items:
		ResourceManager.change_item_count(i, -fruit_quest_required_items[i], global_position)
	complete_quest(fruit_quest_reward_coupon_count)
	return true


func complete_delivery_quest(from: npc_name, to: npc_name):
	if from == npc && current_delivery_quest_target == to:
		complete_quest(delivery_quest_reward_coupon_count)


func complete_quest(reward_coupon_count:= 1):
	#Reset quest status
	is_in_fruit_quest = false
	is_in_delivery_quest = false
	
	var final_reward_count:= reward_coupon_count + UpgradeManager.get_upgrade_level("quest reward +") * UpgradeManager.upgrade_database["quest reward +"].effect_delta_per_level
	ResourceManager.change_item_count('exchange coupon', final_reward_count, global_position)
	#update icon
	quest_status_icon.texture = quest_status_sprite_new_quest
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.COMPLETE_QUEST)


func bypass() -> void:
	if is_in_fruit_quest:
		try_complete_fruit_quest()

	#complete all delivery quests that set this npc as target
	for sender: npc_name in current_delivery_sender_list:
		delivery_quest_completed.emit(sender, npc)
		print("Delivery signal sent - from:%s to:%s" % [sender as npc_name, npc as npc_name]) 
	current_delivery_sender_list.clear()
	refresh_textures()
	#update icon
	delivery_sender_icon.visible = false


func arrive() -> void:
	bypass()
	generate_random_quest()


func interact(base_grid_pos: Vector2) -> void:
	#print("Player arrived: %s" % is_player_arrived) 
	#print("is_remote_quest_acceptance_unlocked: %s" % is_remote_quest_acceptance_unlocked) 
	#print("is_remote_quest_submission_unlocked: %s" % is_remote_quest_submission_unlocked) 
	if not is_in_quest:
		if is_player_arrived or is_remote_quest_acceptance_unlocked:
			generate_random_quest()
	elif is_in_fruit_quest:
		if is_player_arrived or is_remote_quest_submission_unlocked:
			try_complete_fruit_quest()
	
	if is_player_arrived:
		#complete all delivery quests that set this npc as target
		for sender: npc_name in current_delivery_sender_list:
			delivery_quest_completed.emit(sender, npc)
			print("Delivery signal sent - from:%s to:%s" % [sender as npc_name, npc as npc_name]) 
		current_delivery_sender_list.clear()
		refresh_textures()
		#update icon
		delivery_sender_icon.visible = false


func try_bypass(forward: bool) -> void:
	if is_fruit_quest_submittable() or !current_delivery_sender_list.is_empty():
		var new_target = Vector2(1.0, 1.4) if forward else Vector2.ZERO
		var ease = Tween.EASE_OUT if forward else Tween.EASE_IN
		bypass_submit_preview.texture = quest_status_sprite_complete
		
		if preview_target_scale == new_target:
			return
		preview_target_scale = new_target
		
		if bypass_tween and bypass_tween.is_valid():
			bypass_tween.kill()
		
		bypass_tween = create_tween()
		bypass_tween.tween_property(
			bypass_submit_preview,
			"scale",
			new_target,
			0.2
		).set_ease(ease).set_trans(Tween.TRANS_EXPO)


func try_arrive(arrive: bool):
	if is_fruit_quest_submittable() or !current_delivery_sender_list.is_empty() or !is_in_quest:
		var new_target = Vector2(1.0, 1.4) if arrive else Vector2.ZERO
		var ease = Tween.EASE_OUT if arrive else Tween.EASE_IN
		if not is_in_quest:
			bypass_submit_preview.texture = quest_status_sprite_new_quest
		else:
			bypass_submit_preview.texture = quest_status_sprite_complete
		
		if preview_target_scale == new_target:
			return
		preview_target_scale = new_target
		
		if bypass_tween and bypass_tween.is_valid():
			bypass_tween.kill()
		
		bypass_tween = create_tween()
		bypass_tween.tween_property(
			bypass_submit_preview,
			"scale",
			new_target,
			0.2
		).set_ease(ease).set_trans(Tween.TRANS_EXPO)


func on_item_count_changed(item_name: String, count: int, change_amount: int, source: Vector2):
	if is_in_fruit_quest:
		#update icon
		quest_status_icon.texture = quest_status_sprite_complete if is_fruit_quest_submittable() else quest_status_sprite_fruit


func on_upgrade_added(upgrade: Upgrade):
	match upgrade.upgrade_name:
		"remote quest acceptance":
			is_remote_quest_acceptance_unlocked = true
		"remote quest completion":
			is_remote_quest_submission_unlocked = true
