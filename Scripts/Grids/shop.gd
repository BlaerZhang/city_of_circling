extends FunctionalGridComponent

@export var shop_type: ItemsForSale.ShopType
@export var shop_slot_button_scene: PackedScene
@export var shop_ui_panel_offset: Vector2
var wheel_manager: WheelManager
@onready var shop_ui_panel:= $"Shop UI Panel"
@onready var item_slots_parent:= $"Shop UI Panel/HBoxContainer"
var prize_source_type: PrizeItems.Source:
	get:
		return shop_type as PrizeItems.Source
var sale_pools: Dictionary[int, Array]
var items_in_slots: Array[ItemsForSale]
var current_items_for_sale_and_slots: Dictionary[Button, ItemsForSale]

var is_remote_view_unlocked:= false
var is_rainbow_white_ball_unlocked:= false


func _ready() -> void:
	wheel_manager = get_tree().root.get_node("Game2d/UI/Spin Wheel")
	load_items_for_sale_to_pools()
	restock_shop()
	update_slots_state()
	shop_ui_panel.position = shop_ui_panel_offset
	shop_ui_panel.scale = Vector2.ZERO
	GameManager.game_state_changed.connect(update_slots_state)


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
					if res.belonging_shops.has(self.shop_type):
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
	sale_pools.sort()
	for pool in sale_pools.values():
		var items_for_sale = draw_items_from_pool(pool)
		if items_for_sale:
			items_in_slots.append(items_for_sale)
	
	generate_item_slots(items_in_slots)


func generate_item_slots(items_in_slots_list: Array[ItemsForSale]):
	for slot in item_slots_parent.get_children():
		slot.queue_free()
	current_items_for_sale_and_slots.clear()
	
	for item_for_sale in items_in_slots_list:
		var item_slot: Button = shop_slot_button_scene.instantiate()
		item_slots_parent.add_child(item_slot)
		
		var price_label: RichTextLabel = item_slot.get_node("Price Label")
		price_label.text = "%d [img=30x30]res://Assets/Sprites/Icon/1x/exchange coupon.png[/img]" % item_for_sale.price
		item_slot.text = "\nx%d" % item_for_sale.item_count
		item_slot.icon = ResourceManager.get_item_sprite(item_for_sale.item_name)
		item_slot.pressed.connect(on_item_slot_pressed.bind(item_slot, item_for_sale))
		item_slot.tooltip_text = "%s x%d\nPrice: %d" % [item_for_sale.item_name.capitalize(), item_for_sale.item_count, item_for_sale.price]
		
		current_items_for_sale_and_slots.get_or_add(item_slot, item_for_sale)
	
	update_slots_state()


func update_slots_state():
	#Idle State && Player at shop
	for item_slot: Button in current_items_for_sale_and_slots.keys():
		var price_label: RichTextLabel = item_slot.get_node("Price Label")
		if is_player_at_this_grid && GameManager.current_game_state == GameManager.GameState.Idle:
			item_slot.disabled = false
		else:
			item_slot.disabled = true
		#set all sold slots
		if current_items_for_sale_and_slots[item_slot] == null:
			item_slot.disabled = true
			price_label.text = "SOLD"
		#set locked slots
		elif current_items_for_sale_and_slots[item_slot].item_name.to_lower() in ["rainbow", "white"]:
			if !is_rainbow_white_ball_unlocked:
				item_slot.disabled = true
				price_label.text = "LOCKED"


func on_item_slot_pressed(item_slot: Button, item_for_sale: ItemsForSale):
	if ResourceManager.try_buy_item(item_for_sale.item_name, item_for_sale.item_count, "exchange coupon", item_for_sale.price, item_slot.global_position):
		#TODO:play sound
		if item_for_sale.item_name.to_lower() == "mystery box":
			if item_for_sale.price != 3:
				current_items_for_sale_and_slots[item_slot] = null
			wheel_manager.initiate_wheel(shop_type as PrizeItems.Source)
			await wheel_manager.draw_finished
			GameManager.switch_game_state(GameManager.GameState.Idle)
		else:
			current_items_for_sale_and_slots[item_slot] = null
		update_slots_state()
	else:
		#TODO:play sound
		var slot_tween = create_tween().set_loops(2)
		slot_tween.tween_property(item_slot, "modulate", Color.RED, 0.1).set_trans(Tween.TRANS_EXPO)
		slot_tween.tween_property(item_slot, "modulate", Color.WHITE, 0.1).set_trans(Tween.TRANS_EXPO)


func arrive() -> void:
	#print("Show Shop UI:" + str(shop_type))
	var show_shop_tween = create_tween()
	show_shop_tween.tween_property(shop_ui_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_EXPO)
	update_slots_state()


func depart() -> void:
	if !is_remote_view_unlocked:
		#print("Hide Shop UI:" + str(shop_type))
		var hide_shop_tween = create_tween()
		hide_shop_tween.tween_property(shop_ui_panel, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_EXPO)
	update_slots_state()
