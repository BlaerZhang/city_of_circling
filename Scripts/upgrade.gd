class_name Upgrade
extends Resource

enum UpgradeType
{
	Affairs,
	Traffic,
	Lottery,
	Trade,
}

@export var upgrade_name: String
@export_multiline var description: String
@export var upgrade_type: UpgradeType
@export var upgrade_cost_per_level: Array[int]
var upgrade_max_level: int:
	get:
		return upgrade_cost_per_level.size()
