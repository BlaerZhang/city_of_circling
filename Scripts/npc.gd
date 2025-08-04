extends Node

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


func generate_delivery_quest():
	is_in_delivery_quest = true
	var _target = randi() % npc_name.size() as npc_name
	while _target == npc:
		_target = randi() % npc_name.size() as npc_name
	
	current_delivery_quest_target = _target
	delivery_quest_generated.emit(npc, _target)


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
		ResourceManager.change_item_count(i, -fruit_quest_required_items[i])
	complete_quest()
	return true


func complete_delivery_quest(from: npc_name, to: npc_name):
	if (from == npc):
		complete_quest()


func complete_quest(reward_coupon_count:= 1):
	#Reset quest status
	is_in_fruit_quest = false
	is_in_delivery_quest = false
	
	ResourceManager.change_item_count('exchange coupon', reward_coupon_count)

#func _process(delta: float) -> void:
	#if (Input.is_action_just_pressed("test")):
		#generate_fruit_quest()
		#print(is_fruit_quest_submittable())
