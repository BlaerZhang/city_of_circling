extends Node

@export var text_play_speed: Dictionary[String, float]
@onready var tutorial_label: RichTextLabel = %"Tutorial Label"
var tutorial_label_tween: Tween
var skip_confirmed: bool = false

func _ready() -> void:
	tutorial_label.text = ""
	await SceneManager.transition_finished
	tutorial_sequence_start()


func display_text(text: String) -> void:
	tutorial_label.visible_ratio = 0
	tutorial_label.text = text
	var text_length: int = tutorial_label.get_parsed_text().length()
	var time_to_play: float = text_length / text_play_speed[TranslationServer.get_locale()]
	if tutorial_label_tween:
		tutorial_label_tween.kill()
	tutorial_label_tween = create_tween()
	tutorial_label_tween.tween_property(tutorial_label, "visible_ratio", 1, time_to_play).from(0)
	#play sound effect every fixed interval until the text is finished
	while tutorial_label_tween.is_valid():
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.TUTORIAL_PRINT)
		await get_tree().create_timer(0.06).timeout
	# await tutorial_label_tween.finished


func tutorial_sequence_start() -> void:
	await display_text(tr("TUTORIAL_1"))
	await get_tree().create_timer(1).timeout
	await display_text(tr("TUTORIAL_2"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(6, 3))
	GridManager.show_grid_at_pos(Vector2i(6, 4))
	GridManager.show_grid_at_pos(Vector2i(6, 5))
	GridManager.show_grid_at_pos(Vector2i(7, 5))
	GridManager.show_grid_at_pos(Vector2i(8, 5))
	display_text(tr("TUTORIAL_MOVE_1"))
	await %"Player Movement Manager".plan_move_started
	display_text(tr("TUTORIAL_MOVE_2"))
	await %"Player Movement Manager".move_completed
	await display_text(tr("TUTORIAL_MOVE_3"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(9, 5))
	display_text(tr("TUTORIAL_LOTTERY_1"))
	await %"Spin Wheel".wheel_face.on_end_spin
	var icon_show_tween = create_tween()
	icon_show_tween.tween_property(GridManager.grid_database[Vector2i(9, 5)].get_node("Major Fruit Icon"), "scale", Vector2.ONE, 0.2).from(Vector2.ZERO).set_trans(Tween.TRANS_EXPO)
	await display_text(tr("TUTORIAL_LOTTERY_2"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(9, 4))
	GridManager.show_grid_at_pos(Vector2i(9, 3))
	display_text(tr("TUTORIAL_NPC_1"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.fruit_quest_generated
	await display_text(tr("TUTORIAL_NPC_2"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_NPC_3"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(8, 3))
	GridManager.show_grid_at_pos(Vector2i(7, 3))
	display_text(tr("TUTORIAL_NPC_4"))
	await %"Spin Wheel".wheel_face.on_end_spin
	await display_text(tr("TUTORIAL_NPC_5"))
	await get_tree().create_timer(1).timeout
	display_text(tr("TUTORIAL_NPC_6"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.fruit_quest_completed
	await display_text(tr("TUTORIAL_NPC_7"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(9, 2))
	GridManager.show_grid_at_pos(Vector2i(9, 1))
	GridManager.show_grid_at_pos(Vector2i(8, 1))
	GridManager.show_grid_at_pos(Vector2i(7, 1))
	GridManager.show_grid_at_pos(Vector2i(6, 1))
	GridManager.show_grid_at_pos(Vector2i(6, 2))
	display_text(tr("TUTORIAL_NPC_8"))
	await GridManager.grid_database[Vector2i(7, 1)].functional_grid_component.delivery_quest_generated
	await display_text(tr("TUTORIAL_NPC_9"))
	await get_tree().create_timer(1).timeout
	display_text(tr("TUTORIAL_NPC_10"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.delivery_quest_completed
	await display_text(tr("TUTORIAL_NPC_11"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(5, 1))
	GridManager.show_grid_at_pos(Vector2i(4, 1))
	GridManager.show_grid_at_pos(Vector2i(4, 2))
	GridManager.show_grid_at_pos(Vector2i(4, 3))
	GridManager.show_grid_at_pos(Vector2i(5, 3))
	display_text(tr("TUTORIAL_SHOP_1"))
	await GridManager.grid_database[Vector2i(5, 1)].player_arrived
	display_text(tr("TUTORIAL_SHOP_2"))
	await %"Spin Wheel".wheel_face.on_end_spin
	display_text(tr("TUTORIAL_SHOP_3"))
	await %"Spin Wheel".draw_finished
	GridManager.show_grid_at_pos(Vector2i(4, 5))
	await display_text(tr("TUTORIAL_UPGRADE_1"))
	await get_tree().create_timer(2).timeout
	display_text(tr("TUTORIAL_UPGRADE_2"))
	while true:
		var signal_args = await ResourceManager.item_count_changed
		if signal_args[0] == "trade upgrade coupon" and signal_args[2] >= 1:
			break
	await display_text(tr("TUTORIAL_UPGRADE_3"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_UPGRADE_4"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(4, 4))
	GridManager.show_grid_at_pos(Vector2i(5, 5))
	display_text(tr("TUTORIAL_UPGRADE_5"))
	await GridManager.grid_database[Vector2i(4, 5)].player_arrived
	display_text(tr("TUTORIAL_UPGRADE_6"))
	await UpgradeManager.upgrade_added
	await display_text(tr("TUTORIAL_UPGRADE_7"))
	await get_tree().create_timer(2).timeout
	var sale_pool = GridManager.grid_database[Vector2i(5, 1)].functional_grid_component.sale_pool
	sale_pool[sale_pool.find_custom(func(item: ItemForSale): return item.item_name == "supplies")].weight_list_per_level[0] = 80
	sale_pool[sale_pool.find_custom(func(item: ItemForSale): return item.item_name == "trade upgrade coupon")].weight_list_per_level[0] = 0
	display_text(tr("TUTORIAL_POINTS_1"))
	while true:
		var signal_args = await ResourceManager.item_count_changed
		if signal_args[0] == "trade_supply_lv2" and signal_args[2] >= 1:
			break
	%"Success Rate UI".show_ui()
	await display_text(tr("TUTORIAL_POINTS_2"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_POINTS_3"))
	%"Success Rate UI".show_points_uis()
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_POINTS_4"))
	ResourceManager.change_item_count("affairs_supply_lv5", 1, Vector2(0, 0))
	ResourceManager.change_item_count("traffic_supply_lv5", 1, Vector2(0, 0))
	ResourceManager.change_item_count("lottery_supply_lv5", 1, Vector2(0, 0))
	ResourceManager.change_item_count("trade_supply_lv5", 1, Vector2(0, 0))
	await get_tree().create_timer(4).timeout
	await display_text(tr("TUTORIAL_POINTS_5"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_POINTS_6"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_POINTS_7"))
	await get_tree().create_timer(1).timeout
	await display_text(tr("TUTORIAL_POINTS_8"))
	await get_tree().create_timer(3).timeout
	await display_text(tr("TUTORIAL_POINTS_9"))
	await get_tree().create_timer(3).timeout
	GridManager.show_grid_at_pos(Vector2i(4, 6))
	display_text(tr("TUTORIAL_GATE"))


func _on_skip_tutorial_button_pressed() -> void:
	skip_tutorial()


func skip_tutorial() -> void:
	if !skip_confirmed:
		skip_confirmed = true
		%"Skip Tutorial Button".text = "SKIP_TUTORIAL_CONFIRM"
		await get_tree().create_timer(3).timeout
		%"Skip Tutorial Button".text = "SKIP_TUTORIAL"
		skip_confirmed = false
	else:
		SceneManager.change_scene("res://Scenes/game_2d.tscn")
