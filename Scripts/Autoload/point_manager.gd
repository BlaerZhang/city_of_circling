extends Node

var points_data: Dictionary[ItemForSale.ShopType, int]
var success_rate: float:
	get:
		return 1.0 - exp(-0.02 * geo_mean(points_data.values()))
signal points_changed(shop_type: ItemForSale.ShopType, points: int)	

func _ready() -> void:
	SceneManager.scene_loaded_with_name.connect(on_scene_loaded_with_name)
	ResourceManager.item_count_changed.connect(on_item_count_changed)


func on_scene_loaded_with_name(scene_name: String) -> void:
	if scene_name != "Ending":
		reset_points()


func change_points(shop_type: ItemForSale.ShopType, points: int) -> void:
	points_data[shop_type] += points
	points_changed.emit( shop_type, points_data[shop_type])


func get_points(shop_type: ItemForSale.ShopType) -> int:
	return points_data[shop_type]


func reset_points() -> void:
	points_data = {
		ItemForSale.ShopType.Affairs: 0, 
		ItemForSale.ShopType.Traffic: 0, 
		ItemForSale.ShopType.Lottery: 0, 
		ItemForSale.ShopType.Trade: 0,
	}


func on_item_count_changed(item_name: String, count: int, change_amount: int, source_pos: Vector2):
	if change_amount == 0: return
	if ResourceManager.get_item_pts_type(item_name) != ItemForSale.ShopType.None:
		change_points(ResourceManager.get_item_pts_type(item_name), ResourceManager.get_item_pts_value(item_name) * change_amount)


func geo_mean(data: Array[int]) -> float:
	var current_multiplied: float = 1
	for i in data:
		current_multiplied *= i
	return pow(current_multiplied, 1.0 / data.size())
