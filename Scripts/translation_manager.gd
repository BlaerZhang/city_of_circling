extends Control

@export var language: String


func _enter_tree() -> void:
	TranslationServer.set_locale(language)


func _on_button_zh_pressed() -> void:
	TranslationServer.set_locale("zh")
	SceneManager.change_scene("res://Scenes/game_2d.tscn")


func _on_button_en_pressed() -> void:
	TranslationServer.set_locale("en")
	SceneManager.change_scene("res://Scenes/game_2d.tscn")
