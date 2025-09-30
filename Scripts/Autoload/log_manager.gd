extends Node

var log_data: Array[Dictionary]
var end_game_item_data: Array[Dictionary]
var end_game_upgrade_data: Dictionary[String, int]
var end_game_stats_data: Dictionary[String, float]
var current_step: int
var spin_wheel_in_scene
var ending_manager_in_scene

func _ready() -> void:
	TimeManager.stepped.connect(on_stepped)
	SceneManager.scene_loaded_with_name.connect(on_scene_loaded_with_name)
	UpgradeManager.upgrade_added.connect(on_upgrade_purchased)
	ResourceManager.item_purchased.connect(on_item_purchased)


func on_scene_loaded_with_name(scene_name: String):
	if scene_name != "Ending":
		reset_data()


func compress_to_string(text: String) -> String:
	var data := text.to_utf8_buffer()
	# 使用 DEFLATE 压缩
	var compressed := data.compress(FileAccess.COMPRESSION_DEFLATE)
	# 转成 Base64 方便粘贴
	return Marshalls.raw_to_base64(compressed)


func decompress_from_string(b64: String) -> String:
	var compressed := PackedByteArray()
	compressed = Marshalls.base64_to_raw(b64)
	# 解压回原文
	var data := compressed.decompress(compressed.size() * 10, FileAccess.COMPRESSION_DEFLATE)
	return data.get_string_from_utf8()


func on_stepped(step: int):
	current_step = step
	log_data.append({
		"Step": step,
		"Total gained exchange coupon": ResourceManager.get_item_total_gained_count("exchange coupon"),
		"Action": "[Move]"
	})


func on_upgrade_purchased(upgrade: Upgrade):
	log_data.append({
		"Step": current_step,
		"Total gained exchange coupon": ResourceManager.get_item_total_gained_count("exchange coupon"),
		"Action": "[Upgrade Purchased]: " + upgrade.upgrade_name.capitalize() + " (lv." + str(UpgradeManager.get_upgrade_level(upgrade)) + ")",
	})


func on_item_purchased(item_to_buy_name: String, buy_count: int, item_to_pay_name: String, pay_count: int):
	if item_to_buy_name == "fruit draw":
		return
	if item_to_buy_name == "mystery box":
		var prize_item: PrizeItems = await spin_wheel_in_scene.wheel_face.on_end_spin
		log_data.append({
			"Step": current_step,
			"Total gained exchange coupon": ResourceManager.get_item_total_gained_count("exchange coupon"),
			"Action": "[Item Purchased]: " + item_to_buy_name.capitalize() + "(%d)" % pay_count + " -> " + prize_item.prize_name_text,
		})
	elif item_to_buy_name == "upgrade coupon of your choice" or item_to_pay_name == "fruit of your choice":
		log_data.append({
			"Step": current_step,
			"Total gained exchange coupon": ResourceManager.get_item_total_gained_count("exchange coupon"),
			"Action": "[Item Chosen]: " + item_to_buy_name.capitalize(),
		})
	else:
		log_data.append({
			"Step": current_step,
			"Total gained exchange coupon": ResourceManager.get_item_total_gained_count("exchange coupon"),
			"Action": "[Item Purchased]: " + item_to_buy_name.capitalize() + "(%d)" % pay_count,
		})


func resolve_end_game_data():
	for item_name in ResourceManager.items_owned.keys():
		end_game_item_data.append({
			"Item": item_name.capitalize(),
			"Total Gained": ResourceManager.items_total_gained[item_name],
			"Endgame Left": ResourceManager.items_owned[item_name],
		})
	
	for upgrade_name in UpgradeManager.upgrades_owned.keys():
		end_game_upgrade_data.get_or_add(upgrade_name.capitalize(), UpgradeManager.upgrades_owned[upgrade_name])

	end_game_stats_data = {
		"Total Steps": TimeManager.step_taken,
		"Fruit Draw": ResourceManager.items_total_gained["fruit draw"],
		"Success Rate": ending_manager_in_scene.success_rate * 100,
		"Shop Pts": PointManager.get_points(ItemForSale.ShopType.Trade),
		"Quest Pts": PointManager.get_points(ItemForSale.ShopType.Affairs),
		"Move Pts": PointManager.get_points(ItemForSale.ShopType.Traffic),
		"Luck Pts": PointManager.get_points(ItemForSale.ShopType.Lottery),
		"Adventure Score": ending_manager_in_scene.adventure_score,
	}


func reset_data():
	log_data.clear()


func log_data_to_string(_log_data: Array[Dictionary]) -> String:
	var log_string := ""

	#create table header from dictionary keys
	var header := _log_data[0].keys()
	for key in header:
		log_string += key + ","
	log_string += "\n"

	#convert line by line to string
	for data_line in _log_data:
		for key in header:
			log_string += str(data_line[key]) + ","
		log_string += "\n"
	
	log_string += "\n"

	return log_string


func end_game_data_to_string() -> String:
	var end_game_string := ""

	#create item table header from dictionary keys
	var header := end_game_item_data[0].keys()
	for key in header:
		end_game_string += key + ","
	end_game_string += "\n"

	#convert line by line to string
	for data_line in end_game_item_data:
		for key in header:
			end_game_string += str(data_line[key]) + ","
		end_game_string += "\n"
	
	end_game_string += "\n"

	#create upgrade list
	for upgrade in end_game_upgrade_data.keys():
		end_game_string += upgrade + "," + str(end_game_upgrade_data[upgrade]) + "\n"

	end_game_string += "\n"

	#create stats list
	for stat in end_game_stats_data.keys():
		end_game_string += stat + "," + str(end_game_stats_data[stat]) + "\n"

	return end_game_string


func on_resolve_ended():
	resolve_end_game_data()
	print(log_data_to_string(log_data) + end_game_data_to_string())


func copy_log_to_clipboard():
	DisplayServer.clipboard_set(log_data_to_string(log_data) + end_game_data_to_string())
