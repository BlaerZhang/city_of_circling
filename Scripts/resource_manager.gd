extends Node

var item_database: Dictionary[String, Item]
var items_owned: Dictionary[String, int]
signal item_count_changed(item_name: String, count: int, change_amount: int, source_pos: Vector2)

func _ready() -> void:
	load_all_items()
	
	#Temp: shop refresh related
	TimeManager.day_changed.connect(refill_shop_refresh)
	UpgradeManager.upgrade_added.connect(adjust_shop_refresh)


# Load all resources in the folder to dict
func load_all_items():
	var folder := "res://Resources/Items/"
	var files := ResourceLoader.list_directory(folder)
	for file_name in files:
		if file_name.ends_with(".tres"):
			var path = folder + file_name
			var res: Item = ResourceLoader.load(path)
			if res:
				var key = res.item_name.to_lower()
				item_database.get_or_add(key, res)
				items_owned.get_or_add(key, 0)
				item_count_changed.emit(key, 0, 0)
				#print(res.item_name + " resource loaded")


func get_item_sprite(item_name: String) -> Texture2D:
	var key = item_name.to_lower()
	if key not in item_database: return
	var item_sprite = item_database[key].icon
	return item_sprite


func change_item_count(item_name: String, count: int, sourece_pos: Vector2):
	var key = item_name.to_lower()
	if key not in items_owned: 
		print("change_item_count: key not found ->", key)
		return
	items_owned[key] = maxi(items_owned[key] + count, 0)
	item_count_changed.emit(key, items_owned[key], count, sourece_pos)


func get_item_count(item_name: String) -> int:
	var key = item_name.to_lower()
	if key not in items_owned: 
		print("get_item_count: key not found ->", key)
		return -1
	var count := items_owned[key]
	return count


func set_item_count(item_name: String, count: int):
	var key = item_name.to_lower()
	if key not in items_owned: return
	items_owned[key] = count
	item_count_changed.emit(key, items_owned[key], 0, Vector2.ZERO)


func get_item_icon(item_name: String) -> Texture2D:
	var key = item_name.to_lower()
	if key not in item_database: return
	return item_database[key].icon


# Use this when you only want to pay items while not getting anything
func try_pay_item(item_to_pay_name: String, pay_count: int, sourece_pos: Vector2) -> bool:
	var key_pay = item_to_pay_name.to_lower()
	if key_pay not in items_owned: return false
	if pay_count > items_owned[key_pay]:
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.NOT_ENOUGH_TO_BUY)
		return false
	else:
		change_item_count(item_to_pay_name, -pay_count, sourece_pos)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.PURCHASE)
		return true


# Use this to trade items with items
func try_buy_item(item_to_buy_name: String, buy_count: int, item_to_pay_name: String, pay_count: int, sourece_pos: Vector2) -> bool:
	var key_buy = item_to_buy_name.to_lower()
	var key_pay = item_to_pay_name.to_lower()
	if key_buy not in items_owned: return false
	if key_pay not in items_owned: return false
	if try_pay_item(key_pay, pay_count, sourece_pos):
		change_item_count(key_buy, buy_count, sourece_pos)
		return true
	else:
		return false


#test func editor only
func get_all_resources(count: int):
	print("hack pressed")
	for item in items_owned.keys():
		if item != "fruit of your choice" and item != "upgrade coupon of your choice":
			change_item_count(item, count, Vector2.ZERO)


#Temp: shop refresh related
func refill_shop_refresh():
	set_item_count("shop refresh", UpgradeManager.get_upgrade_level("shop refresh +"))


func adjust_shop_refresh(upgrade: Upgrade):
	if upgrade.upgrade_name != "shop refresh +": return
	change_item_count("shop refresh", 1, Vector2.ZERO)
