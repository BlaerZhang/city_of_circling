extends FunctionalGridComponent

@export var upgrade_shop_type: ItemsForSale.ShopType
var slots_upgrade_list: Array[Array]
var current_upgrades_in_slot: Array[Upgrade]
@export var upgrade_button_list: Array[Button]
@onready var upgrade_available_icon:= $"Upgrade Available Icon"
@onready var arrive_preview:= $"Preview Icon"
var bypass_tween: Tween
var preview_target_scale: Vector2 = Vector2.ZERO
var coupon_map = {
		ItemsForSale.ShopType.Affairs: "affairs upgrade coupon",
		ItemsForSale.ShopType.Traffic: "traffic upgrade coupon",
		ItemsForSale.ShopType.Lottery: "lottery upgrade coupon",
		ItemsForSale.ShopType.Trade: "trade upgrade coupon",
	}


func _ready() -> void:
	load_upgrades_to_slots()
	update_slots_state()
	for button in upgrade_button_list:
		button.scale = Vector2.ZERO
	GameManager.game_state_changed.connect(update_slots_state)
	ResourceManager.item_count_changed.connect(update_available_icon)
	
	var upgrade_available_tween = create_tween().set_loops(-1)
	upgrade_available_tween.tween_property(upgrade_available_icon, "position", Vector2(20,-20), 1).as_relative().set_trans(Tween.TRANS_QUAD)
	upgrade_available_tween.tween_property(upgrade_available_icon, "position", Vector2(-20,20), 1).as_relative().set_trans(Tween.TRANS_QUAD)
	upgrade_available_icon.visible = false


func load_upgrades_to_slots():
	var folder := "res://Resources/Upgrades/"
	var files := ResourceLoader.list_directory(folder)
	for file_name in files:
		if file_name.ends_with(".tres"):
			var path = folder + file_name
			var res: Upgrade = ResourceLoader.load(path)
			if res:
				if res.upgrade_type == self.upgrade_shop_type:
					while slots_upgrade_list.size() <= res.shop_slot_index:
						slots_upgrade_list.append([])
					slots_upgrade_list[res.shop_slot_index].append(res)
	#sort all upgrade lists
	for slot_list in slots_upgrade_list:
		slot_list.sort_custom(func(a: Upgrade,b: Upgrade): return a.slot_order < b.slot_order)


func update_slots_state():
	current_upgrades_in_slot.clear()
	#Idle State && Player at shop
	for i in slots_upgrade_list.size():
		var button_to_update: Button = upgrade_button_list[i]
		if is_player_arrived && GameManager.current_game_state == GameManager.GameState.Idle:
			upgrade_button_list[i].disabled = false
		else:
			upgrade_button_list[i].disabled = true
		#get current upgrade to sell
		var current_available_upgrade: Upgrade = null
		for j in slots_upgrade_list[i].size():
			var upgrade_to_check: Upgrade = slots_upgrade_list[i][j]
			if UpgradeManager.get_upgrade_level(upgrade_to_check) < upgrade_to_check.upgrade_max_level:
				current_available_upgrade = upgrade_to_check
				break
			else: continue
		current_upgrades_in_slot.append(current_available_upgrade)
		
		#setup button based on current_available_upgrade
		if current_available_upgrade:
			button_to_update.icon = current_available_upgrade.upgrade_icon
			if button_to_update.pressed.is_connected(on_upgrade_button_pressed): button_to_update.pressed.disconnect(on_upgrade_button_pressed)
			button_to_update.pressed.connect(on_upgrade_button_pressed.bind(button_to_update, current_available_upgrade))
			if current_available_upgrade.upgrade_max_level != 1: #for level-up upgrade
				button_to_update.text = " LV%d\n\n" % (UpgradeManager.get_upgrade_level(current_available_upgrade) + 1)
				button_to_update.tooltip_text = "[center][font_size=24]%s[/font_size]\n\n%s[/center][right][img=20]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30][b]%d[/b][/font_size][/right]" % [
					current_available_upgrade.upgrade_name_display.to_upper(), 
					current_available_upgrade.description, 
					coupon_map[upgrade_shop_type], 
					current_available_upgrade.upgrade_cost_per_level[UpgradeManager.get_upgrade_level(current_available_upgrade)]] % [
					UpgradeManager.get_upgrade_level(current_available_upgrade) * current_available_upgrade.effect_delta_per_level, 
					(UpgradeManager.get_upgrade_level(current_available_upgrade) + 1) * current_available_upgrade.effect_delta_per_level, 
					UpgradeManager.get_upgrade_level(current_available_upgrade), 
					UpgradeManager.get_upgrade_level(current_available_upgrade) + 1, 
					current_available_upgrade.upgrade_max_level]
			else: #for one-time upgrade
				button_to_update.text = ""
				button_to_update.tooltip_text = "[u]%s[/u]\n\n%s\n[right][img=20]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30][b]%d[/b][/font_size][/right]" % [
					current_available_upgrade.upgrade_name_display.to_upper(), 
					current_available_upgrade.description, 
					coupon_map[upgrade_shop_type], 
					current_available_upgrade.upgrade_cost_per_level[0]]
		else: #if not available
			button_to_update.visible = false
			
	update_available_icon(coupon_map[upgrade_shop_type], 0, 0, Vector2.ZERO)


func update_available_icon(item_name: String, count: int, change_amount: int, source_pos: Vector2):
	if ResourceManager.item_database[item_name].item_type == Item.ItemType.Upgrade_Coupon:
		#await get_tree().process_frame
		var can_upgrade = false
		for upgrade in current_upgrades_in_slot:
			if upgrade and if_player_has_enough_coupon_to_buy(upgrade):
				can_upgrade = true
				break
		upgrade_available_icon.visible = can_upgrade


func if_player_has_enough_coupon_to_buy(upgrade: Upgrade) -> bool:
	var level_to_buy:= UpgradeManager.get_upgrade_level(upgrade) + 1
	if level_to_buy > upgrade.upgrade_max_level: return false
	else: 
		#print("%s: %s >= %s" % [upgrade.upgrade_name, ResourceManager.get_item_count(coupon_map[upgrade.upgrade_type]), upgrade.upgrade_cost_per_level[level_to_buy - 1]])
		return ResourceManager.get_item_count(coupon_map[upgrade.upgrade_type]) >= upgrade.upgrade_cost_per_level[level_to_buy - 1]


func on_upgrade_button_pressed(upgrade_button: Button, upgrade: Upgrade):
	var item_to_pay = coupon_map[upgrade_shop_type]
	var level_to_buy = UpgradeManager.get_upgrade_level(upgrade) + 1
	if ResourceManager.try_pay_item(item_to_pay, upgrade.upgrade_cost_per_level[level_to_buy - 1], self.global_position):
		UpgradeManager.add_upgrade(upgrade)
		update_slots_state()
	else: #Insufficient Money feedback
		var slot_tween = create_tween().set_loops(2)
		slot_tween.tween_property(upgrade_button, "modulate", Color.RED, 0.1).set_trans(Tween.TRANS_EXPO)
		slot_tween.tween_property(upgrade_button, "modulate", Color.WHITE, 0.1).set_trans(Tween.TRANS_EXPO)


func arrive() -> void:
	#print("Show Shop UI:" + str(shop_type))
	for button in upgrade_button_list:
		var show_button_tween = create_tween()
		show_button_tween.tween_property(button, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_EXPO)
		update_slots_state()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.DISPLAY_SHOP)


func depart() -> void:
	#print("Hide Shop UI:" + str(shop_type))
	for button in upgrade_button_list:
		var hide_button_tween = create_tween()
		hide_button_tween.tween_property(button, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_EXPO)
		update_slots_state()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIDE_SHOP)


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
