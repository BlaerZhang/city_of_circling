extends FunctionalGridComponent

@export var shop_type: ItemForSale.ShopType
@export var shop_slot_button_scene: PackedScene
@export var shop_ui_panel_offset: Vector2
@export var rarity_to_color: Dictionary[Item.Rarity, Color] = {
	Item.Rarity.Not_Applicable: Color.WHITE,
	Item.Rarity.Common: Color.WHITE,
	Item.Rarity.Uncommon: Color.GREEN,
	Item.Rarity.Rare: Color.BLUE,
	Item.Rarity.Epic: Color.PURPLE,
	Item.Rarity.Legendary: Color.YELLOW,
}
var wheel_manager: WheelManager
@onready var shop_ui_panel:= $"Shop UI Panel"
@onready var item_slots_parent:= $"Shop UI Panel/HBoxContainer"
@onready var refresh_button:= $"Shop UI Panel/Refresh Button"
@onready var arrive_preview:= $"Preview Icon"
var bypass_tween: Tween
var preview_target_scale: Vector2 = Vector2.ZERO
var prize_source_type: PrizeItems.Source:
	get:
		return shop_type as PrizeItems.Source
var sale_pool: Array[ItemForSale]
var sub_pools: Dictionary[String, Array]
var current_items_for_sale_and_slots: Dictionary[Button, Dictionary]

var is_remote_view_unlocked:= false
var is_rainbow_white_ball_unlocked:= false


func _ready() -> void:
	load_items_for_sale_to_pools()
	restock_shop()
	update_slots_state()
	update_refresh_button()
	shop_ui_panel.position = shop_ui_panel_offset
	shop_ui_panel.scale = Vector2.ZERO
	GameManager.game_state_changed.connect(update_slots_state)
	GameManager.game_state_changed.connect(update_refresh_button)
	UpgradeManager.upgrade_added.connect(on_upgrade_added)
	TimeManager.shop_refresh_time.connect(restock_shop)
	ResourceManager.item_count_changed.connect(func(item_name: String, count: int, change_amount: int, source_pos: Vector2): update_refresh_button())
	await get_tree().process_frame
	wheel_manager = %"Spin Wheel"


func load_items_for_sale_to_pools():
	var folder := "res://Resources/ItemsForSale/"
	var files := ResourceLoader.list_directory(folder)
	for file_name in files:
		if file_name.ends_with(".tres"):
			var path = folder + file_name
			var res: ItemForSale = ResourceLoader.load(path)
			if res:
				if res.belonging_shops.has(self.shop_type):
					if res.abstract_collection:
						var sub_pool: Array[ItemForSale] = []
						sub_pools.get_or_add(res.item_name, sub_pool)

						var sub_folder := "res://Resources/ItemsForSale/%s/" % [res.item_name.to_pascal_case()]
						var sub_files := ResourceLoader.list_directory(sub_folder)
						for sub_file_name in sub_files:
							if sub_file_name.ends_with(".tres"):
								var sub_path = sub_folder + sub_file_name
								var sub_res: ItemForSale = ResourceLoader.load(sub_path)
								if sub_res:
									if sub_res.belonging_shops.has(self.shop_type):
										sub_pools[res.item_name].append(sub_res)
					sale_pool.append(res)


func draw_items_from_pool(pool: Array) -> ItemForSale:
	var total_weight := 0.0
	for item_for_sale in pool:
		var weight_in_pool: float
		if item_for_sale.dynamic_weight:
			weight_in_pool = item_for_sale.weight_list_per_level[UpgradeManager.get_upgrade_level(item_for_sale.weight_affecting_upgrade_name)]
		else:
			weight_in_pool = item_for_sale.weight_list_per_level[0]
		total_weight += weight_in_pool

	var random_value := randf_range(0.0, total_weight)
	var cumulative_weight := 0.0
	for item_for_sale in pool:
		var weight_in_pool: float
		if item_for_sale.dynamic_weight:
			weight_in_pool = item_for_sale.weight_list_per_level[UpgradeManager.get_upgrade_level(item_for_sale.weight_affecting_upgrade_name)]
		else:
			weight_in_pool = item_for_sale.weight_list_per_level[0]
		cumulative_weight += weight_in_pool
		if random_value <= cumulative_weight:
			if item_for_sale.abstract_collection:
				return draw_items_from_pool(sub_pools[item_for_sale.item_name])
			else:
				return item_for_sale

	return null


func restock_shop(quantity: int = 2):
	var items_in_slots: Array[Dictionary] = []
	for i in quantity:
		var item_for_sale: ItemForSale = draw_items_from_pool(sale_pool)
		var price = randi_range(item_for_sale.price_range.x, item_for_sale.price_range.y)
		items_in_slots.append({"item": item_for_sale, "price": price})
	
	# 查找盲盒并添加
	var mystery_box = sale_pool[sale_pool.find_custom(func(item: ItemForSale): return item.item_name.to_lower() == "mystery box")]
	if mystery_box != null:
		items_in_slots.append({"item": mystery_box, "price": mystery_box.price_range.x})
	else:
		print("警告：未找到盲盒物品！")
	
	generate_item_slots(items_in_slots)


func generate_item_slots(items_in_slots_list: Array[Dictionary]):
	for slot in item_slots_parent.get_children():
		slot.queue_free()
	current_items_for_sale_and_slots.clear()
	
	for item_data in items_in_slots_list:
		var item_for_sale: ItemForSale = item_data["item"]
		var price: int = item_data["price"]
		var item_slot: Button = shop_slot_button_scene.instantiate()
		item_slots_parent.add_child(item_slot)
		
		var item: Item = ResourceManager.item_database[item_for_sale.item_name]
		var price_label: RichTextLabel = item_slot.get_node("Price Label")
		var item_icon: TextureRect = item_slot.get_node("Shop Button Icon")
		# var quantity_label: RichTextLabel = item_icon.get_node("Quantity Label")
		price_label.text = "%s [img=15x25]res://Assets/Sprites/Icon/1x/exchange coupon.png[/img]" % price
		# quantity_label.text = "x%s" % item_for_sale.item_count
		item_icon.texture = ResourceManager.get_item_sprite(item_for_sale.item_name)
		item_slot.self_modulate = rarity_to_color[item.rarity]
		item_slot.pressed.connect(on_item_slot_pressed.bind(item_slot, item_for_sale, price))
		if item.item_type == Item.ItemType.Supply:
			item_slot.tooltip_text = "%s\n%s%s: %s\n%s: %s" % [tr(ResourceManager.get_item_display_key(item_for_sale.item_name)).capitalize(), tr(ItemForSale.ShopType.keys()[item.pts_type].to_upper()), tr("PTS"), item.pts_value, tr("PRICE"), price]
		else:
			item_slot.tooltip_text = "%s\n%s: %s" % [tr(ResourceManager.get_item_display_key(item_for_sale.item_name)).capitalize(), tr("PRICE"), price]
		current_items_for_sale_and_slots.get_or_add(item_slot, item_data)
	
	update_slots_state()


func update_slots_state():
	#Idle State && Player at shop
	for item_slot: Button in current_items_for_sale_and_slots.keys():
		var price_label: RichTextLabel = item_slot.get_node("Price Label")
		if is_player_arrived && GameManager.current_game_state == GameManager.GameState.Idle:
			item_slot.disabled = false
		else:
			item_slot.disabled = true
		#set all sold slots
		if current_items_for_sale_and_slots[item_slot] == null or current_items_for_sale_and_slots[item_slot].is_empty():
			item_slot.disabled = true
			price_label.text = "SOLD"
		#set locked slots
		# elif current_items_for_sale_and_slots[item_slot].item_name.to_lower() in ["rainbow", "white"]:
		# 	if !is_rainbow_white_ball_unlocked:
		# 		item_slot.disabled = true
		# 		price_label.text = "[img=25x25]res://Assets/Sprites/Icon/1x/lock_icon.png[/img]"
		# 	else:
		# 		price_label.text = "%d [img=15x25]res://Assets/Sprites/Icon/1x/exchange coupon.png[/img]" % current_items_for_sale_and_slots[item_slot].price


func update_refresh_button():
	#update ui
	if UpgradeManager.get_upgrade_level("shop manual refresh") > 0:
		refresh_button.visible = true
		refresh_button.text = "\nx%s " % ResourceManager.get_item_count("shop refresh")
	else:
		refresh_button.visible = false
	
	#update state
	if is_player_arrived && GameManager.current_game_state == GameManager.GameState.Idle && ResourceManager.get_item_count("shop refresh") > 0:
		refresh_button.disabled = false
	else:
		refresh_button.disabled = true


func on_item_slot_pressed(item_slot: Button, item_for_sale: ItemForSale, price: int):
	if ResourceManager.try_buy_item(item_for_sale.item_name, 1, "exchange coupon", price, item_slot.global_position):
		if item_for_sale.item_name.to_lower() == "mystery box":
			if price != 3:
				current_items_for_sale_and_slots[item_slot] = {}
			wheel_manager.initiate_wheel(PrizeItems.Source[ItemForSale.ShopType.keys()[shop_type]])
			await wheel_manager.draw_finished
			GameManager.switch_game_state(GameManager.GameState.Idle)
		else:
			current_items_for_sale_and_slots[item_slot] = {}
		update_slots_state()
	else:
		var slot_tween = create_tween().set_loops(2)
		slot_tween.tween_property(item_slot, "modulate", Color.RED, 0.1).set_trans(Tween.TRANS_EXPO)
		slot_tween.tween_property(item_slot, "modulate", Color.WHITE, 0.1).set_trans(Tween.TRANS_EXPO)


func arrive() -> void:
	#print("Show Shop UI:" + str(shop_type))
	var show_shop_tween = create_tween()
	show_shop_tween.tween_property(shop_ui_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_EXPO)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.DISPLAY_SHOP)
	update_slots_state()
	update_refresh_button()


func depart() -> void:
	if !is_remote_view_unlocked:
		#print("Hide Shop UI:" + str(shop_type))
		var hide_shop_tween = create_tween()
		hide_shop_tween.tween_property(shop_ui_panel, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_EXPO)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIDE_SHOP)
	update_slots_state()
	update_refresh_button()


func try_arrive(arrive: bool):
	var new_target = Vector2(1.0, 1.4) if arrive else Vector2.ZERO
	var ease = Tween.EASE_OUT if arrive else Tween.EASE_IN
	
	if preview_target_scale == new_target:
		return
	preview_target_scale = new_target
	
	if bypass_tween and bypass_tween.is_valid():
		bypass_tween.kill()
		
	bypass_tween = create_tween()
	bypass_tween.tween_property(
		arrive_preview,
		"scale",
		new_target,
		0.2
	).set_ease(ease).set_trans(Tween.TRANS_EXPO)


func on_upgrade_added(upgrade: Upgrade):
	match upgrade.upgrade_name:
		"remote view store":
			is_remote_view_unlocked = true
			var show_shop_tween = create_tween()
			show_shop_tween.tween_property(shop_ui_panel, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_EXPO)
			update_slots_state()
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.DISPLAY_SHOP)
		"unlock rainbow white ball":
			is_rainbow_white_ball_unlocked = true
			update_slots_state()
		"shop refresh +":
			await get_tree().create_timer(0.1).timeout


func _on_refresh_button_pressed() -> void:
	if ResourceManager.try_pay_item("shop refresh", 1, Vector2.ZERO):
		restock_shop()
