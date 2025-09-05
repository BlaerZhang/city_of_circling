extends FunctionalGridComponent

@onready var exit_button: Button = $"Exit button"

func _ready() -> void:
	exit_button.scale = Vector2.ZERO


func arrive() -> void:
	var show_exit_button_tween = create_tween()
	show_exit_button_tween.tween_property(exit_button, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_EXPO)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GATE_DISPLAY)


func depart() -> void:
	var hide_exit_button_tween = create_tween()
	hide_exit_button_tween.tween_property(exit_button, "scale", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_EXPO)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GATE_HIDE)


func _on_exit_button_pressed() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GATE_HIDE)

	if get_tree().current_scene.name == "Tutorial":
		SceneManager.change_scene("res://Scenes/game_2d.tscn", {"pattern": "circle"})
	else:
		print("Left the city through gate")
		SceneManager.change_scene("res://Scenes/ending.tscn", {"pattern": "fade"})
