extends Node

var grid_database: Dictionary[Vector2i, BaseGrid]
signal moused_clicked_down_grid(grid_pos: Vector2i)
signal moused_entered_grid(grid_pos: Vector2i)
signal moused_exited_grid(grid_pos: Vector2i)

func _ready() -> void:
	await get_tree().process_frame
	setup_grid_system()


func setup_grid_system():
	var grids:= get_tree().get_nodes_in_group("Grids")
	grid_database.clear()
	for grid: BaseGrid in grids:
		grid_database.get_or_add(grid.grid_position, grid)
		grid.connect("mouse_entered", on_moused_entered_grid)
		grid.connect("mouse_exited", on_moused_exited_grid)
		grid.connect("mouse_clicked_down", on_moused_clicked_down_grid)
	setup_grid_neighbours(grid_database)


func setup_grid_neighbours(grid_database: Dictionary[Vector2i, BaseGrid]):
	for grid:BaseGrid in grid_database.values():
		grid.neighbour_grids.clear()
		if grid_database.has(grid.grid_position + Vector2i.RIGHT):
			grid.neighbour_grids.append(grid.grid_position + Vector2i.RIGHT)
		if grid_database.has(grid.grid_position + Vector2i.LEFT):
			grid.neighbour_grids.append(grid.grid_position + Vector2i.LEFT)
		if grid_database.has(grid.grid_position + Vector2i.UP):
			grid.neighbour_grids.append(grid.grid_position + Vector2i.UP)
		if grid_database.has(grid.grid_position + Vector2i.DOWN):
			grid.neighbour_grids.append(grid.grid_position + Vector2i.DOWN)


func get_grids_in_range(origin: Vector2i, range: int, facing_dir: Vector2i, free_move:= false) -> Array[BaseGrid]:
	var grids_in_range: Array[BaseGrid]
	grids_in_range.clear()
	
	recursive_search_grid(grids_in_range, origin, range, facing_dir, free_move)
	
	return grids_in_range


func recursive_search_grid(grids_in_range: Array[BaseGrid], origin: Vector2i, range: int, facing_dir: Vector2i, free_move:= false):
	if range <= 0: return
	
	var origin_grid = grid_database[origin]
	match free_move:
		true:
			for neighbour_grid_pos: Vector2i in origin_grid.neighbour_grids:
				var neighbour_grid:= grid_database[neighbour_grid_pos]
				grids_in_range.append(neighbour_grid)
				var new_facing_dir:= neighbour_grid.grid_position - origin
				recursive_search_grid(grids_in_range, neighbour_grid.grid_position, range -1, new_facing_dir)
		false:
			for neighbour_grid_pos: Vector2i in origin_grid.neighbour_grids:
				var neighbour_grid:= grid_database[neighbour_grid_pos]
				var new_facing_dir:= neighbour_grid.grid_position - origin
				if new_facing_dir != -facing_dir:
					grids_in_range.append(neighbour_grid)
					recursive_search_grid(grids_in_range, neighbour_grid.grid_position, range -1, new_facing_dir)


func on_moused_entered_grid(grid_pos: Vector2i):
	#print("Manager received signals from:" + str(grid_pos) + " Entered")
	if !GameManager.input_lock && !GameManager.grid_input_lock:
		moused_entered_grid.emit(grid_pos)
		grid_database[grid_pos].self_modulate = Color.hex(0xf0f0f0ff)


func on_moused_exited_grid(grid_pos: Vector2i):
	#print("Manager received signals from:" + str(grid_pos) + " Exited")
	if !GameManager.input_lock && !GameManager.grid_input_lock:
		moused_exited_grid.emit(grid_pos)
		grid_database[grid_pos].self_modulate = Color.WHITE


func on_moused_clicked_down_grid(grid_pos: Vector2i):
	#print("Manager received signals from:" + str(grid_pos) + " Clicked Down")
	if !GameManager.input_lock && !GameManager.grid_input_lock:
		moused_clicked_down_grid.emit(grid_pos)
		grid_database[grid_pos].self_modulate = Color.WHITE
		grid_database[grid_pos].interact()
