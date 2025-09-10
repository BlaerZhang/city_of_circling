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

enum Rarity
{
	Not_Applicable,
	Common,
	Uncommon,
	Rare,
	Epic,
	Legendary,
}

@export var item_name: String
@export var item_name_display_key: String
@export var icon: Texture2D
@export var item_type: ItemType
@export var rarity: Rarity = Rarity.Not_Applicable
@export var pts_value: int = 0
@export var pts_type: ItemForSale.ShopType = ItemForSale.ShopType.None
