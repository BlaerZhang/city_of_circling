extends Node

@export var text_play_speed: Dictionary[String, float]
@onready var tutorial_label: RichTextLabel = %"Tutorial Label"
var tutorial_label_tween: Tween

func _ready() -> void:
	tutorial_label.text = ""
	await SceneManager.transition_finished
	tutorial_sequence_start()
	

func display_text(text: String) -> void:
	var text_length: int = text.length()
	var time_to_play: float = text_length / text_play_speed[TranslationServer.get_locale()]
	if tutorial_label_tween:
		tutorial_label_tween.kill()
	tutorial_label_tween = create_tween()
	tutorial_label.text = ""
	tutorial_label_tween.tween_property(tutorial_label, "text", text, time_to_play)
	#play sound effect every fixed interval until the text is finished
	while tutorial_label_tween.is_valid():
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.TUTORIAL_PRINT)
		await get_tree().create_timer(0.06).timeout
	# await tutorial_label_tween.finished

func tutorial_sequence_start() -> void:
	await display_text(tr("TUTORIAL_1"))
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
	display_text(tr("TUTORIAL_NPC_5"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.fruit_quest_completed
	await display_text(tr("TUTORIAL_NPC_6"))
	await get_tree().create_timer(2).timeout
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
	display_text(tr("TUTORIAL_NPC_9"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.delivery_quest_completed
	await display_text(tr("TUTORIAL_NPC_10"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_NPC_11"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_NPC_12"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(5, 1))
	display_text(tr("TUTORIAL_SHOP_1"))
	await GridManager.grid_database[Vector2i(5, 1)].player_arrived
	display_text(tr("TUTORIAL_SHOP_2"))
	await %"Spin Wheel".wheel_face.on_end_spin
	display_text(tr("TUTORIAL_SHOP_3"))
	await %"Spin Wheel".draw_finished
	GridManager.show_grid_at_pos(Vector2i(4, 1))
	GridManager.show_grid_at_pos(Vector2i(4, 2))
	GridManager.show_grid_at_pos(Vector2i(4, 3))
	GridManager.show_grid_at_pos(Vector2i(5, 3))
	await display_text(tr("TUTORIAL_UPGRADE_1"))
	await get_tree().create_timer(2).timeout
	display_text(tr("TUTORIAL_UPGRADE_2"))
	while true:
		var signal_args = await ResourceManager.item_count_changed
		if signal_args[0] == "trade upgrade coupon" and signal_args[2] >= 1:
			break
	display_text(tr("TUTORIAL_UPGRADE_3"))
	await GridManager.grid_database[Vector2i(4, 3)].player_arrived
	display_text(tr("TUTORIAL_UPGRADE_4"))
	await UpgradeManager.upgrade_added
	await display_text(tr("TUTORIAL_UPGRADE_5"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_UPGRADE_6"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_UPGRADE_7"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_UPGRADE_8") % "[img=40]res://Assets/Sprites/Icon/1x/exchange coupon italic.png[/img]")
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_UPGRADE_9"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_UPGRADE_10"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(4, 4))
	GridManager.show_grid_at_pos(Vector2i(4, 5))
	GridManager.show_grid_at_pos(Vector2i(5, 5))
	display_text(tr("TUTORIAL_GATE"))
