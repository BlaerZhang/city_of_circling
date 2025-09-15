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

# 优惠券图标映射
const COUPON_MAP: Dictionary = {
	ItemForSale.ShopType.Affairs: "affairs upgrade coupon",
	ItemForSale.ShopType.Traffic: "traffic upgrade coupon",
	ItemForSale.ShopType.Lottery: "lottery upgrade coupon",
	ItemForSale.ShopType.Trade: "trade upgrade coupon",
}


func _ready() -> void:
	init()
	UpgradeManager.upgrade_added.connect(update_icon_and_tooltip)


func init() -> void:
	upgrade_icon.texture = upgrade.upgrade_icon
	update_icon_and_tooltip(null)


func update_icon_and_tooltip(added_upgrade: Upgrade) -> void:
	var current_level: int = UpgradeManager.get_upgrade_level(upgrade)
	
	match upgrade_type:
		UpgradeType.level_up:
			_update_level_up_upgrade(current_level)
		UpgradeType.one_time:
			_update_one_time_upgrade(current_level, added_upgrade)


## 更新等级提升型升级的UI和提示
func _update_level_up_upgrade(current_level: int) -> void:
	lock_icon.texture = null
	self.modulate = Color.GRAY if current_level == 0 else Color.WHITE
	
	var upgrade_name: String = upgrade.upgrade_name_display.to_upper()
	var description: String = upgrade.description
	
	if current_level < upgrade.upgrade_max_level:
		var current_effect: int = current_level * upgrade.effect_delta_per_level
		var next_effect: int = (current_level + 1) * upgrade.effect_delta_per_level
		var cost: int = upgrade.upgrade_cost_per_level[current_level]
		var coupon_icon: String = COUPON_MAP[upgrade.upgrade_type]
		
		tooltip_text = _build_level_up_tooltip_with_cost(
			upgrade_name, 
			description, 
			coupon_icon, 
			cost, 
			current_effect, 
			next_effect, 
			current_level, 
			current_level + 1, 
			upgrade.upgrade_max_level
		)
	else:
		var max_effect: int = current_level * upgrade.effect_delta_per_level
		tooltip_text = _build_level_up_tooltip_maxed(upgrade_name, description, max_effect, current_level)


## 更新一次性升级的UI和提示
func _update_one_time_upgrade(current_level: int, added_upgrade: Upgrade) -> void:
	if upgrade.slot_order == 0:
		_update_first_slot_upgrade(current_level)
	else:
		_update_chained_slot_upgrade(current_level, added_upgrade)


## 更新第一个槽位的升级
func _update_first_slot_upgrade(current_level: int) -> void:
	var upgrade_name: String = upgrade.upgrade_name_display.to_upper()
	var description: String = upgrade.description
	
	if current_level == 0:
		lock_icon.texture = null
		self.modulate = Color.GRAY
		tooltip_text = _build_one_time_tooltip_with_cost(
			upgrade_name, 
			description, 
			COUPON_MAP[upgrade.upgrade_type], 
			upgrade.upgrade_cost_per_level[0]
		)
	elif current_level == 1:
		lock_icon.texture = null
		self.modulate = Color.WHITE
		tooltip_text = _build_one_time_tooltip_purchased(upgrade_name, description)


## 更新链式槽位的升级
func _update_chained_slot_upgrade(current_level: int, added_upgrade: Upgrade) -> void:
	var upgrade_name: String = upgrade.upgrade_name_display.to_upper()
	var description: String = upgrade.description
	
	if current_level == 1:
		# 已购买状态
		lock_icon.texture = null
		self.modulate = Color.WHITE
		tooltip_text = _build_one_time_tooltip_purchased(upgrade_name, description)
	elif _is_upgrade_unlocked(added_upgrade):
		# 刚解锁状态
		lock_icon.texture = null
		self.modulate = Color.GRAY
		tooltip_text = _build_one_time_tooltip_with_cost(
			upgrade_name, 
			description, 
			COUPON_MAP[upgrade.upgrade_type], 
			upgrade.upgrade_cost_per_level[0]
		)
	else:
		# 锁定状态（初始化或未解锁）
		lock_icon.texture = lock_sprite
		self.modulate = Color.GRAY
		tooltip_text = _build_one_time_tooltip_locked(
			upgrade_name, 
			description, 
			COUPON_MAP[upgrade.upgrade_type], 
			upgrade.upgrade_cost_per_level[0]
		)


## 检查升级是否已解锁
func _is_upgrade_unlocked(added_upgrade: Upgrade) -> bool:
	if added_upgrade == null:
		return false
	
	return (added_upgrade.upgrade_type == upgrade.upgrade_type and 
			added_upgrade.shop_slot_index == upgrade.shop_slot_index and 
			added_upgrade.slot_order + 1 == upgrade.slot_order)


## 构建等级提升型升级的提示文本（有升级费用）
func _build_level_up_tooltip_with_cost(
	upgrade_name: String, 
	desc: String, 
	coupon_icon: String, 
	cost: int, 
	current_effect: int, 
	next_effect: int, 
	current_level: int, 
	next_level: int, 
	max_level: int
) -> String:
	var formatted_desc: String = desc % [current_effect, next_effect, current_level, next_level, max_level]
	return "[center][font_size=24]%s[/font_size]\n\n%s[/center][right][img=40]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30][b]%d[/b][/font_size][/right]" % [
		upgrade_name, formatted_desc, coupon_icon, cost
	]


## 构建等级提升型升级的提示文本（已满级）
func _build_level_up_tooltip_maxed(upgrade_name: String, desc: String, max_effect: int, max_level: int) -> String:
	var formatted_desc: String = desc % [max_effect, "-", max_level, "-", "-"]
	return "[center][font_size=24]%s[/font_size]\n\n%s[/center]" % [upgrade_name, formatted_desc]


## 构建一次性升级的提示文本（有购买费用）
func _build_one_time_tooltip_with_cost(upgrade_name: String, desc: String, coupon_icon: String, cost: int) -> String:
	return "[u]%s[/u]\n\n%s\n[right][img=40]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30][b]%d[/b][/font_size][/right]" % [
		upgrade_name, desc, coupon_icon, cost
	]


## 构建一次性升级的提示文本（已购买）
func _build_one_time_tooltip_purchased(upgrade_name: String, desc: String) -> String:
	return "[u]%s[/u]\n\n%s\n" % [upgrade_name, desc]


## 构建一次性升级的提示文本（锁定状态）
func _build_one_time_tooltip_locked(upgrade_name: String, desc: String, coupon_icon: String, cost: int) -> String:
	return "[u]%s[/u]\n\n%s\n[right][img=40]res://Assets/Sprites/Icon/1x/%s.png[/img] [font_size=30]%d[/font_size][/right]" % [
		upgrade_name, desc, coupon_icon, cost
	]
