extends Node

@export var shop_type: ItemsForSale.ShopType
var sale_pools: Dictionary[int, Array]
var items_in_slots: Array[ItemsForSale]

func _ready() -> void:
	load_items_for_sale_to_pools()
	restock_shop()

func load_items_for_sale_to_pools():
	var dir = DirAccess.open("res://Resources/ItemsForSale/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var path = "res://Resources/ItemsForSale/" + file_name
				var res:ItemsForSale = load(path)
				if res:
					if res.belonging_shop == self.shop_type:
						sale_pools.get_or_add(res.pool_index, Array())
						sale_pools[res.pool_index].append(res)
			file_name = dir.get_next()
		dir.list_dir_end()

func draw_items_from_pool(pool: Array) -> ItemsForSale:
	var total_weight := 0.0
	for items_for_sale in pool:
		total_weight += items_for_sale.weight_in_pool
	
	var random_value := randf_range(0.0, total_weight)
	var cumulative_weight := 0.0
	for items_for_sale in pool:
		cumulative_weight += items_for_sale.weight_in_pool
		if random_value <= cumulative_weight:
			return items_for_sale
			
	return null

func restock_shop():
	items_in_slots.clear()
	for pool in sale_pools.values():
		var items_for_sale = draw_items_from_pool(pool)
		if items_for_sale:
			items_in_slots.append(items_for_sale)
	
	#TODO: 接UI
