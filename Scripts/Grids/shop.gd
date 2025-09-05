extends FunctionalGridComponent

@export var shop_type: ItemsForSale.ShopType
@export var shop_slot_button_scene: PackedScene
@export var shop_ui_panel_offset: Vector2
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
var sale_pools: Dictionary[int, Array]
var items_in_slots: Array[ItemsForSale]
var current_items_for_sale_and_slots: Dictionary[Button, ItemsForSale]

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
			var res: ItemsForSale = ResourceLoader.load(path)
			if res:
				if res.belonging_shops.has(self.shop_type):
					sale_pools.get_or_add(res.pool_index, Array())
					sale_pools[res.pool_index].append(res)

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
	
	for items_for_sale in items_in_slots_list:
		var item_slot: Button = shop_slot_button_scene.instantiate()
		item_slots_parent.add_child(item_slot)
		
		var price_label: RichTextLabel = item_slot.get_node("Price Label")
		var item_icon: TextureRect = item_slot.get_node("Shop Button Icon")
		var quantity_label: RichTextLabel = item_icon.get_node("Quantity Label")
		price_label.text = "%s [img=15x25]res://Assets/Sprites/Icon/1x/exchange coupon.png[/img]" % items_for_sale.price
		quantity_label.text = "x%s" % items_for_sale.item_count
		item_icon.texture = ResourceManager.get_item_sprite(items_for_sale.item_name)
		item_slot.pressed.connect(on_item_slot_pressed.bind(item_slot, items_for_sale))
		item_slot.tooltip_text = "%s x%s\n%s: %s" % [tr(ResourceManager.get_item_display_key(items_for_sale.item_name)).capitalize(), items_for_sale.item_count, tr("PRICE"), items_for_sale.price]
		
		current_items_for_sale_and_slots.get_or_add(item_slot, items_for_sale)
	
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
		if current_items_for_sale_and_slots[item_slot] == null:
			item_slot.disabled = true
			price_label.text = "SOLD"
		#set locked slots
		elif current_items_for_sale_and_slots[item_slot].item_name.to_lower() in ["rainbow", "white"]:
			if !is_rainbow_white_ball_unlocked:
				item_slot.disabled = true
				price_label.text = "[img=25x25]res://Assets/Sprites/Icon/1x/lock_icon.png[/img]"
			else:
				price_label.text = "%d [img=15x25]res://Assets/Sprites/Icon/1x/exchange coupon.png[/img]" % current_items_for_sale_and_slots[item_slot].price


func update_refresh_button():
	#update ui
	if UpgradeManager.get_upgrade_level("shop refresh +") > 0:
		refresh_button.visible = true
		refresh_button.text = "\nx%s " % ResourceManager.get_item_count("shop refresh")
	else:
		refresh_button.visible = false
	
	#update state
	if is_player_arrived && GameManager.current_game_state == GameManager.GameState.Idle && ResourceManager.get_item_count("shop refresh") > 0:
		refresh_button.disabled = false
	else:
		refresh_button.disabled = true


func on_item_slot_pressed(item_slot: Button, item_for_sale: ItemsForSale):
	if ResourceManager.try_buy_item(item_for_sale.item_name, item_for_sale.item_count, "exchange coupon", item_for_sale.price, item_slot.global_position):
		#TODO:play sound
		if item_for_sale.item_name.to_lower() == "mystery box":
			if item_for_sale.price != 3:
				current_items_for_sale_and_slots[item_slot] = null
			if shop_type as PrizeItems.Source == PrizeItems.Source.Traffic:
				if is_rainbow_white_ball_unlocked:
					wheel_manager.initiate_wheel(shop_type as PrizeItems.Source)
				else:
					wheel_manager.initiate_wheel(PrizeItems.Source.Traffic_Locked)
			else:
				wheel_manager.initiate_wheel(shop_type as PrizeItems.Source)
			await wheel_manager.draw_finished
			GameManager.switch_game_state(GameManager.GameState.Idle)
		else:
			current_items_for_sale_and_slots[item_slot] = null
		update_slots_state()
	else: #Insufficient Money feedback
		#TODO:play sound
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
