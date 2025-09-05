extends Node

@onready var tutorial_label: RichTextLabel = %"Tutorial Label"
var tutorial_label_tween: Tween

func _ready() -> void:
	tutorial_label.text = ""
	await SceneManager.transition_finished
	tutorial_sequence_start()
	

func display_text(text: String) -> void:
	var text_play_speed: float = 15.0
	var text_length: int = text.length()
	var time_to_play: float = text_length / text_play_speed
	if tutorial_label_tween:
		tutorial_label_tween.kill()
	tutorial_label_tween = create_tween()
	tutorial_label.text = ""
	tutorial_label_tween.tween_property(tutorial_label, "text", text, time_to_play)
	await tutorial_label_tween.finished

func tutorial_sequence_start() -> void:
	GridManager.show_grid_at_pos(Vector2i(6, 3))
	GridManager.show_grid_at_pos(Vector2i(6, 4))
	GridManager.show_grid_at_pos(Vector2i(6, 5))
	GridManager.show_grid_at_pos(Vector2i(7, 5))
	GridManager.show_grid_at_pos(Vector2i(8, 5))
	await display_text(tr("TUTORIAL_1"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_MOVE_1"))
	await %"Player Movement Manager".plan_move_started
	await display_text(tr("TUTORIAL_MOVE_2"))
	await %"Player Movement Manager".move_completed
	await display_text(tr("TUTORIAL_MOVE_3"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(9, 5))
	await display_text(tr("TUTORIAL_LOTTERY_1"))
	await %"Spin Wheel".wheel_face.on_end_spin
	await display_text(tr("TUTORIAL_LOTTERY_2"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(9, 4))
	GridManager.show_grid_at_pos(Vector2i(9, 3))
	await display_text(tr("TUTORIAL_NPC_1"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.fruit_quest_generated
	await display_text(tr("TUTORIAL_NPC_2"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_NPC_3"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(8, 3))
	GridManager.show_grid_at_pos(Vector2i(7, 3))
	await display_text(tr("TUTORIAL_NPC_4"))
	await %"Spin Wheel".wheel_face.on_end_spin
	await display_text(tr("TUTORIAL_NPC_5"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.fruit_quest_completed
	await display_text(tr("TUTORIAL_NPC_6"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(9, 2))
	GridManager.show_grid_at_pos(Vector2i(9, 1))
	GridManager.show_grid_at_pos(Vector2i(8, 1))
	GridManager.show_grid_at_pos(Vector2i(7, 1))
	GridManager.show_grid_at_pos(Vector2i(6, 1))
	GridManager.show_grid_at_pos(Vector2i(6, 2))
	await display_text(tr("TUTORIAL_NPC_7"))
	await GridManager.grid_database[Vector2i(7, 1)].functional_grid_component.delivery_quest_generated
	await display_text(tr("TUTORIAL_NPC_8"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_NPC_9"))
	await get_tree().create_timer(2).timeout
	await display_text(tr("TUTORIAL_NPC_10"))
	await GridManager.grid_database[Vector2i(9, 3)].functional_grid_component.delivery_quest_completed
	await display_text(tr("TUTORIAL_NPC_11"))
	await get_tree().create_timer(2).timeout
	GridManager.show_grid_at_pos(Vector2i(5, 1))
	await display_text(tr("TUTORIAL_SHOP_1"))
	# await 
