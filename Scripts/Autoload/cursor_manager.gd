extends Node

var cursor = preload("res://Assets/Sprites/Cursor/cursor_none.png")
var cursor_pointing = preload("res://Assets/Sprites/Cursor/hand_point.png")

func _ready() -> void:
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(4,2))
	Input.set_custom_mouse_cursor(cursor_pointing, Input.CURSOR_POINTING_HAND, Vector2(4,2))
