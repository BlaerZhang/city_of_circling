class_name ItemsForSale
extends Resource

enum ShopType
{
	Affairs,
	Traffic,
	Lottery,
	Trade,
}

@export var item_list: Dictionary[String, int]
@export var price: int
@export var belonging_shop: ShopType
@export var pool_index: int
@export var weight_in_pool: float = 1.0
