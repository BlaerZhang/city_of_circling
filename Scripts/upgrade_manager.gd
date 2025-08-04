extends Node

var upgrade_database: Dictionary[String, Upgrade]
var upgrades_owned: Dictionary[String, int]
signal upgrade_added(upgrade: Upgrade)


func _ready() -> void:
	load_all_upgrades()


# Load all resources in the folder to dict
func load_all_upgrades():
	var dir = DirAccess.open("res://Resources/Upgrades/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://Resources/Upgrades/" + file_name
				var res:Upgrade = load(path)
				if res:
					var key = res.upgrade_name.to_lower()
					upgrade_database.get_or_add(key, res)
			file_name = dir.get_next()
		dir.list_dir_end()


func add_upgrade(upgrade: Upgrade):
	
	if (upgrades_owned.has(upgrade.upgrade_name)):
		upgrades_owned[upgrade.upgrade_name] += 1
	else:
		upgrades_owned[upgrade.upgrade_name] = 1
	
	upgrade_added.emit(upgrade)


func get_upgrade_level(upgrade) -> int:
	if (upgrade is not String) or (!upgrade is not Upgrade): return -1
	
	var _current_level: int = 0
	
	var _upgrade_name: String
	if upgrade is Upgrade:
		_upgrade_name = upgrade_database.find_key(upgrade)
	elif upgrade is String:
		_upgrade_name = upgrade
		
	if upgrades_owned.has(_upgrade_name):
		_current_level = upgrades_owned[_upgrade_name]
		
	return _current_level
