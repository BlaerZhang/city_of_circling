extends Node

var item_database: Dictionary[String, Item]
var items_owned: Dictionary[String, int]
signal item_count_changed(item_name: String, count: int, changeAmount: int)

func _ready() -> void:
	load_all_items()

# Load all resources in the folder to dict
func load_all_items():
	var dir = DirAccess.open("res://Resources/Items/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://Resources/Items/" + file_name
				var res:Item = load(path)
				if res:
					var key = res.item_name.to_lower()
					item_database.get_or_add(key, res)
					items_owned.get_or_add(key, 0)
					item_count_changed.emit(key, 0, 0)
			file_name = dir.get_next()
		dir.list_dir_end()

func change_item_count(item_name: String, count: int):
	var key = item_name.to_lower()
	items_owned[key] = maxi(items_owned[key] + count, 0)
	item_count_changed.emit(key, items_owned[key], count)

func get_item_count(item_name: String) -> int:
	var key = item_name.to_lower()
	var count := items_owned[key]
	return count

func set_item_count(item_name: String, count: int):
	var key = item_name.to_lower()
	items_owned[key] = count
	item_count_changed.emit(key, items_owned[key], 0)

func get_item_icon(item_name: String) -> Texture2D:
	var key = item_name.to_lower()
	return item_database[key].icon

# Use this when you only want to pay items while not getting anything
func try_pay_item(item_to_pay_name: String, pay_count: int) -> bool:
	var key_pay = item_to_pay_name.to_lower()
	if (pay_count > items_owned[key_pay]):
		return false
	else:
		change_item_count(item_to_pay_name, -pay_count)
		return true

# Use this to trade items with items
func try_buy_item(item_to_buy_name: String, buy_count: int, item_to_pay_name: String, pay_count: int) -> bool:
	var key_buy = item_to_buy_name.to_lower()
	var key_pay = item_to_pay_name.to_lower()
	if (try_pay_item(item_to_pay_name, pay_count)):
		change_item_count(item_to_buy_name, buy_count)
		return true
	else:
		return false
