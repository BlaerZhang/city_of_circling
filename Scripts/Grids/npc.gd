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
@export_range(0.0, 1.0, 0.001) var fruit_quest_probability := 0.5
var delivery_quest_probability: float:
		get:
			return 1 - fruit_quest_probability
@export var required_fruit_type_1: String
@export var required_fruit_type_2: String
var fruit_quest_required_items: Dictionary[String, int]
@export var fruit_quest_reward_coupon_count: int = 2

@export_group("Delivery Quest")
@export var delivery_quest_reward_coupon_count: int = 1
var current_delivery_quest_target: npc_name
var current_delivery_sender_list: Array[npc_name]
signal delivery_quest_generated(from: npc_name, to: npc_name)
signal delivery_quest_completed(from: npc_name, to: npc_name)

@export_group("UI Related")
@onready var bypass_submit_preview:= $"Preview Icon"
@onready var quest_status_icon:= $"Quest Icon"
@onready var delivery_sender_icon:= $"Delivery Sender"
@export var quest_status_sprite_new_quest: Texture2D
@export var quest_status_sprite_complete: Texture2D
@export var quest_status_sprite_delivery: Texture2D
@export var quest_status_sprite_fruit: Texture2D


func _ready() -> void:
	add_to_group("NPCs")
	for npc: NPC in get_tree().get_nodes_in_group("NPCs"):
		npc.delivery_quest_generated.connect(set_as_delivery_target)
		npc.delivery_quest_completed.connect(complete_delivery_quest)
	
	quest_status_icon.texture = quest_status_sprite_new_quest
	
	var quest_icon_tween = create_tween().set_loops(-1)
	quest_icon_tween.tween_property(quest_status_icon, "position", Vector2(20,-20), 1).as_relative().set_trans(Tween.TRANS_QUAD)
	quest_icon_tween.tween_property(quest_status_icon, "position", Vector2(-20,20), 1).as_relative().set_trans(Tween.TRANS_QUAD)


func generate_random_quest():
	if is_in_quest: return
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
	var _target = randi() % npc_name.size() as npc_name
	while _target == npc:
		_target = randi() % npc_name.size() as npc_name
	
	current_delivery_quest_target = _target
	delivery_quest_generated.emit(npc, _target)
	
	#update icon
	quest_status_icon.texture = quest_status_sprite_delivery


func set_as_delivery_target(from: npc_name, to: npc_name):
	if to == npc:
		current_delivery_sender_list.append(from)
		
		#update icon
		delivery_sender_icon.visible = true


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
	
	ResourceManager.change_item_count('exchange coupon', reward_coupon_count, global_position)
	#update icon
	quest_status_icon.texture = quest_status_sprite_new_quest


func bypass() -> void:
	if is_in_fruit_quest:
		try_complete_fruit_quest()

	#complete all delivery quests that set this npc as target
	for sender: npc_name in current_delivery_sender_list:
		delivery_quest_completed.emit(sender, npc)
		print("Delivery signal sent - from:%d to:%d" % [sender as npc_name, npc as npc_name]) 
	current_delivery_sender_list.clear()
	#update icon
	delivery_sender_icon.visible = false


func arrive() -> void:
	generate_random_quest()


func interact(base_grid_pos: Vector2) -> void:
	if is_player_at_this_grid:
		if is_in_quest: bypass()
		else: generate_random_quest()
	else:
		if not is_in_quest and is_remote_quest_acceptance_unlocked:
			generate_random_quest()
		elif is_in_quest and is_remote_quest_submission_unlocked:
			bypass()


func try_bypass(forward: bool) -> void:
	if is_fruit_quest_submittable() or !current_delivery_sender_list.is_empty():
		var tween = create_tween()
		if forward:
			tween.tween_property(bypass_submit_preview, "scale", Vector2(1.0, 1.4), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		else:
			tween.tween_property(bypass_submit_preview, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)


func on_item_count_changed(item_name: String, count: int, change_amount: int):
	if is_in_fruit_quest:
		#update icon
		quest_status_icon.texture = quest_status_sprite_complete if is_fruit_quest_submittable() else quest_status_sprite_fruit


#func _process(delta: float) -> void:
	#if (Input.is_action_just_pressed("test")):
		#generate_fruit_quest()
		#print(is_fruit_quest_submittable())
