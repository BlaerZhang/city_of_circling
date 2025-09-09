class_name ItemsForSale
extends Resource

enum ShopType
{
	Affairs,
	Traffic,
	Lottery,
	Trade,
	Tutorial_Shop,
}

@export var item_name: String
@export var item_count: int
@export var price: int
@export var belonging_shops: Array[ShopType]
@export var pool_index: int
@export var weight_in_pool: float = 1.0
