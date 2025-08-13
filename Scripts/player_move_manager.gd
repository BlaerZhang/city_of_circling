extends Node2D

@onready var line_drawer:= %LineDrawer

var player_grid_pos: Vector2i = Vector2i.ZERO
var player_facing: Vector2i = Vector2i.RIGHT
var player_move_range: int = 4
var moving_backwards_unlocked:= false

#movement planning related
var is_planning_move:= false
var planning_facing: Vector2i = Vector2i.RIGHT
var planning_grid_pos: Vector2i
var planning_step: int
var planning_grids_in_range: Array[BaseGrid]
@export var outline_selected_color:= Color.CORAL
@export var outline_available_color:= Color.YELLOW_GREEN

#moving & animation related
@export var step_time:= 0.5
var planned_move_grid_positions: Array[Vector2i]
@onready var player_animation_tree:= %"Player AnimationTree"
var is_player_moving:= false


func _ready() -> void:
	GridManager.moused_clicked_down_grid.connect(start_plan_move)
	GridManager.moused_entered_grid.connect(step_plan_move)
	GridManager.moused_clicked_down_grid.connect(complete_plan_move)


func _process(delta: float) -> void:
	update_player_animation()
	
	if is_planning_move && Input.is_action_just_pressed("right_click"):
		cancel_plan_move()
		GameManager.resume_last_game_state()


func start_plan_move(grid_pos: Vector2i):
	#print("Manager received signals from:" + str(grid_pos) + " Clicked Down")
	if not is_player_at_grid(grid_pos): return
	if not is_planning_move:
		is_planning_move = true
		GameManager.switch_game_state(GameManager.GameState.Plan)
		planning_grid_pos = grid_pos
		planning_facing = player_facing
		planning_step = player_move_range
		planning_grids_in_range = GridManager.get_grids_in_range(grid_pos, planning_step, planning_facing, moving_backwards_unlocked)
		line_drawer.add_draw_point(GridManager.grid_database[grid_pos].position)
		planned_move_grid_positions.append(planning_grid_pos)
		
		update_grid_outline()


func step_plan_move(grid_pos: Vector2i):
	#print("Manager received signals from:" + str(grid_pos) + " Entered")
	if is_planning_move:
		# check neighbouring
		if GridManager.grid_database[planning_grid_pos].neighbour_grids.has(grid_pos):
			var dir = grid_pos - planning_grid_pos
			# withdraw
			if planned_move_grid_positions[planned_move_grid_positions.size() - 2] == grid_pos:
				planning_grid_pos = grid_pos
				# withdraw to beginning
				planning_step += 1
				if planned_move_grid_positions.size() <= 2:
					planning_facing = player_facing
					planning_grids_in_range = GridManager.get_grids_in_range(grid_pos, planning_step, planning_facing, moving_backwards_unlocked)
				else:
					planning_facing = planned_move_grid_positions[planned_move_grid_positions.size() - 2] - planned_move_grid_positions[planned_move_grid_positions.size() - 3]
					planning_grids_in_range = GridManager.get_grids_in_range(grid_pos, planning_step, planning_facing)
				line_drawer.withdraw_point()
				var grid_to_remove_pos:= planned_move_grid_positions[planned_move_grid_positions.size() - 1]
				GridManager.grid_database[grid_to_remove_pos].try_bypass(false)
				planned_move_grid_positions.remove_at(planned_move_grid_positions.size() - 1)
				
				update_grid_outline()
			# step
			elif planning_grids_in_range.has(GridManager.grid_database[grid_pos]):
				# if is not first step, lock moving backward
				if planning_step != player_move_range:
					if dir == -planning_facing:
						return
				elif dir == -planning_facing && !moving_backwards_unlocked:
						return
				planning_grid_pos = grid_pos
				planning_facing = dir
				planning_step -= 1
				planning_grids_in_range = GridManager.get_grids_in_range(grid_pos, planning_step, planning_facing)
				line_drawer.add_draw_point(GridManager.grid_database[grid_pos].position)
				planned_move_grid_positions.append(planning_grid_pos)
				
				update_grid_outline()
				GridManager.grid_database[grid_pos].try_bypass(true)


func complete_plan_move(grid_pos: Vector2i) -> void:
	if is_planning_move and grid_pos == planning_grid_pos and planning_step != player_move_range:
		#is_player_moving = true
		for planned_grid_pos in planned_move_grid_positions:
			GridManager.grid_database[planned_grid_pos].try_bypass(false)
		
		GridManager.grid_database[player_grid_pos].depart()
		GameManager.switch_game_state(GameManager.GameState.Move)
		player_facing = planning_facing
		var move_grid_positions: Array[Vector2i]
		planned_move_grid_positions.remove_at(0)
		move_grid_positions.append_array(planned_move_grid_positions)
		
		line_drawer.finish_draw()
		is_planning_move = false
		planning_grids_in_range.clear()
		
		update_grid_outline()

		await _move_player_step_by_step(move_grid_positions)

		player_grid_pos = grid_pos
		is_player_moving = false
		await GridManager.grid_database[player_grid_pos].arrive()
		GameManager.switch_game_state(GameManager.GameState.Idle)


func _move_player_step_by_step(path: Array[Vector2i]) -> void:
	for grid_position in path:
		is_player_moving = true
		var target_pos = GridManager.grid_database[grid_position].global_position
		var tween = create_tween()
		tween.tween_property(get_parent(), "position", target_pos, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		player_facing = grid_position - player_grid_pos
		await tween.finished
		is_player_moving = false
		player_grid_pos = grid_position
		planned_move_grid_positions.remove_at(0)
		update_grid_outline()
		
		#Logic
		TimeManager.add_one_hour()
		await GridManager.grid_database[player_grid_pos].bypass()


func cancel_plan_move():
	for grid_pos in planned_move_grid_positions:
		GridManager.grid_database[grid_pos].try_bypass(false)
	line_drawer.finish_draw()
	is_planning_move = false
	planning_grids_in_range.clear()
	planned_move_grid_positions.clear()
	
	update_grid_outline()


func update_grid_outline():
	for grid: BaseGrid in GridManager.grid_database.values():
		grid.outline_tween.kill()
		grid.outline_tween = create_tween()
		if planned_move_grid_positions.has(grid.grid_position):
			if grid.grid_position == planning_grid_pos:
				grid.outline_tween.set_loops()
				grid.outline_tween.tween_property(grid.grid_outline, "modulate", outline_selected_color, 0.375).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				grid.outline_tween.tween_interval(0.25)
				grid.outline_tween.tween_property(grid.grid_outline, "modulate", Color.TRANSPARENT, 0.375).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
			else:
				grid.outline_tween.tween_property(grid.grid_outline, "modulate", outline_selected_color, 0.1)
		elif planning_grids_in_range.has(grid):
			grid.outline_tween.tween_property(grid.grid_outline, "modulate", outline_available_color, 0.1)
		else:
			grid.outline_tween.tween_property(grid.grid_outline, "modulate", Color.TRANSPARENT, 0.2)


func is_player_at_grid(grid_pos: Vector2i) -> bool:
	return grid_pos == player_grid_pos


func update_player_animation():
	match is_player_moving:
		true:
			player_animation_tree["parameters/playback"].travel("Walk")
		false:
			player_animation_tree["parameters/playback"].travel("Idle")
	player_animation_tree.set("parameters/Idle/blend_position", player_facing)
	player_animation_tree.set("parameters/Walk/blend_position", player_facing)
