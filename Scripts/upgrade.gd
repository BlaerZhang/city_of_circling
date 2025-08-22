class_name Upgrade
extends Resource


@export var upgrade_name: String
@export var upgrade_icon: Texture2D
@export_multiline var description: String
@export var effect_delta_per_level: int = 1
@export var upgrade_type: ItemsForSale.ShopType
@export var shop_slot_index: int
@export var slot_order: int
@export var upgrade_cost_per_level: Array[int]
var upgrade_max_level: int:
	get:
		return upgrade_cost_per_level.size()
