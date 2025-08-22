class_name Item
extends Resource

enum ItemType
{
	Fruit,
	Coupon,
	Supply,
	Upgrade_Coupon,
	Other,
}

@export var item_name: String
@export var icon: Texture2D
@export var item_type: ItemType
