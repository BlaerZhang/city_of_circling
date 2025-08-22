class_name FunctionalGridComponent
extends Node2D

var grid_pos: Vector2i:
	get:
		return get_parent().grid_position

var is_player_at_this_grid: bool:
	get:
		return %"Player Movement Manager".is_player_at_grid(grid_pos)

var is_player_at_neighbour_grid: bool:
	get:
		var at_neighbour:= false
		for neighbour_grid in get_parent().neighbour_grids:
			if %"Player Movement Manager".is_player_at_grid(neighbour_grid):
				at_neighbour = true
		return at_neighbour

var is_player_arrived:= false

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


func try_arrive(arrive: bool):
	pass
