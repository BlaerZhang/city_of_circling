class_name FunctionalGridComponent
extends Node2D

var grid_pos: Vector2i:
	get:
		return get_parent().grid_position

var is_player_at_this_grid: bool:
	get:
		return %"Player Movement Manager".is_player_at_grid(grid_pos)


func bypass() -> void:
	pass


func arrive() -> void:
	pass


func depart() -> void:
	pass


func interact(grid_pos: Vector2) -> void:
	pass


#for planning UI Display
func try_bypass(forward: bool) -> void:
	pass
