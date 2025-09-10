class_name ItemForSale
extends Resource

enum ShopType
{
	Affairs,
	Traffic,
	Lottery,
	Trade,
	Tutorial_Shop,
	None,
}

@export var abstract_collection:= false
@export var item_name: String
@export var price_range: Vector2i
@export var belonging_shops: Array[ShopType]

@export_group("Weight Settings")
@export var dynamic_weight:= false
@export var weight_affecting_upgrade_name: String
@export var weight_list_per_level: Array[float]
