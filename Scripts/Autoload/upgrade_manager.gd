extends Node

var upgrade_database: Dictionary[String, Upgrade]
var upgrades_owned: Dictionary[String, int]
signal upgrade_added(upgrade: Upgrade)


func _ready() -> void:
	load_all_upgrades()
	SceneManager.scene_loaded_with_name.connect(on_scene_loaded_with_name)


func on_scene_loaded_with_name(scene_name: String):
	upgrades_owned.clear()


# Load all resources in the folder to dict
func load_all_upgrades():
	var folder := "res://Resources/Upgrades/"
	var files := ResourceLoader.list_directory(folder)
	for file_name in files:
		if file_name.ends_with(".tres"):
			var path = folder + file_name
			var res: Upgrade = ResourceLoader.load(path)
			if res:
				var key = res.upgrade_name.to_lower()
				upgrade_database.get_or_add(key, res)


func add_upgrade(upgrade):
	var upgrade_name: String
	if upgrade is Upgrade:
		upgrade_name = upgrade_database.find_key(upgrade)
	elif upgrade is String:
		upgrade_name = upgrade.to_lower()
	
	if upgrades_owned.has(upgrade_name):
		upgrades_owned[upgrade_name] += 1
	else:
		upgrades_owned.get_or_add(upgrade_name, 1)
	
	upgrade_added.emit(upgrade)


func get_upgrade_level(upgrade) -> int:
	if (upgrade is not String) and (upgrade is not Upgrade): return -1
	
	var _current_level: int = 0
	
	var _upgrade_name: String
	if upgrade is Upgrade:
		_upgrade_name = upgrade_database.find_key(upgrade)
	elif upgrade is String:
		_upgrade_name = upgrade.to_lower()
		
	if upgrades_owned.has(_upgrade_name):
		_current_level = upgrades_owned[_upgrade_name]
		
	return _current_level


# func get_upgrade_level_by_slot_index_and_order(upgrade_type: ItemForSale.ShopType, slot_index: int, order: int) -> int:
	
# 	return 0
