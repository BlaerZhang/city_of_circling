extends CustomTooltip

enum UpgradeType{
	level_up,
	one_time,
}

@export var upgrade: Upgrade
@export var upgrade_type: UpgradeType
@export var lock_sprite: Texture2D
@export var unlock_sprite: Texture2D
@onready var upgrade_icon: TextureRect = $"Upgrade Icon"
@onready var lock_icon: TextureRect = $"Lock Icon"
var coupon_map = {
		ItemsForSale.ShopType.Affairs: "affairs upgrade coupon",
		ItemsForSale.ShopType.Traffic: "traffic upgrade coupon",
		ItemsForSale.ShopType.Lottery: "lottery upgrade coupon",
		ItemsForSale.ShopType.Trade: "trade upgrade coupon",
	}


func _ready() -> void:
	init()
	UpgradeManager.upgrade_added.connect(update_icon_and_tooltip)


func init():
	upgrade_icon.texture = upgrade.upgrade_icon
	update_icon_and_tooltip(null)


func update_icon_and_tooltip(added_upgrade: Upgrade):
	match upgrade_type:
		UpgradeType.level_up:
			lock_icon.texture = null
			self.modulate = Color.WHITE
			var current_level = UpgradeManager.get_upgrade_level(upgrade)
			if current_level < upgrade.upgrade_max_level:
				tooltip_text = "[center][b][font_size=24]%s[/font_size][/b]\n\n%s[/center][right][img=20]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30][b]%d[/b][/font_size][/right]" % [
					upgrade.upgrade_name_display.to_upper(), 
					upgrade.description, 
					coupon_map[upgrade.upgrade_type], 
					upgrade.upgrade_cost_per_level[UpgradeManager.get_upgrade_level(upgrade)]] % [
					UpgradeManager.get_upgrade_level(upgrade) * upgrade.effect_delta_per_level, 
					(UpgradeManager.get_upgrade_level(upgrade) + 1) * upgrade.effect_delta_per_level, 
					UpgradeManager.get_upgrade_level(upgrade), 
					UpgradeManager.get_upgrade_level(upgrade) + 1, 
					upgrade.upgrade_max_level]
			else:
				tooltip_text = "[center][b][font_size=24]%s[/font_size][/b]\n\n%s[/center]" % [
					upgrade.upgrade_name_display.to_upper(), 
					upgrade.description] % [
					UpgradeManager.get_upgrade_level(upgrade) * upgrade.effect_delta_per_level, 
					"-", 
					UpgradeManager.get_upgrade_level(upgrade), 
					"-", 
					"-"]
		UpgradeType.one_time:
			if upgrade.slot_order == 0:
				if UpgradeManager.get_upgrade_level(upgrade) == 0:
					lock_icon.texture = unlock_sprite
					self.modulate = Color.WHITE
					tooltip_text = "[b][u]%s[/u][/b]\n\n%s\n[right][img=20]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30][b]%d[/b][/font_size][/right]" % [
					upgrade.upgrade_name_display.to_upper(), 
					upgrade.description, 
					coupon_map[upgrade.upgrade_type], 
					upgrade.upgrade_cost_per_level[0]]
				elif UpgradeManager.get_upgrade_level(upgrade) == 1:
					lock_icon.texture = null
					self.modulate = Color.WHITE
					tooltip_text = "[b][u]%s[/u][/b]\n\n%s\n" % [
					upgrade.upgrade_name_display.to_upper(), 
					upgrade.description]
			else:
				if added_upgrade == null:
					#init state
					lock_icon.texture = lock_sprite
					self.modulate = Color.GRAY
					tooltip_text = "[b][u]%s[/u][/b]\n\n%s\n[right][img=20]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30]%d[/font_size][/right]" % [
					upgrade.upgrade_name_display.to_upper(), 
					upgrade.description, 
					coupon_map[upgrade.upgrade_type], 
					upgrade.upgrade_cost_per_level[0]]
				elif added_upgrade.upgrade_type == upgrade.upgrade_type && added_upgrade.shop_slot_index == upgrade.shop_slot_index && added_upgrade.slot_order + 1 == upgrade.slot_order:
					lock_icon.texture = unlock_sprite
					self.modulate = Color.WHITE
					tooltip_text = "[b][u]%s[/u][/b]\n\n%s\n[right][img=20]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30]%d[/font_size][/right]" % [
					upgrade.upgrade_name_display.to_upper(), 
					upgrade.description, 
					coupon_map[upgrade.upgrade_type], 
					upgrade.upgrade_cost_per_level[0]]
				elif UpgradeManager.get_upgrade_level(upgrade) == 1:
					lock_icon.texture = null
					self.modulate = Color.WHITE
					tooltip_text = "[b][u]%s[/u][/b]\n\n%s\n" % [
					upgrade.upgrade_name_display.to_upper(), 
					upgrade.description]
