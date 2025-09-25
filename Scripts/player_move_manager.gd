extends Node2D

@onready var line_drawer:= %LineDrawer

@export_group("Movement")
@export var input_style_cursor: bool = true
var player_grid_pos: Vector2i
var player_facing: Vector2i:
	set(value):
		player_facing = value
		player_animation_tree.set("parameters/Idle/blend_position", value)
		player_animation_tree.set("parameters/Walk/blend_position", value)
@export var player_initial_move_range: int = 4
@export var player_initial_grid_pos: Vector2i
@export var player_initial_facing: Vector2i
var player_move_range: int = 4
var moving_backwards_unlocked:= false
var interaction_distance_unlocked:= false
@onready var player_idle_outline:= %"Player Idle Outline"
var player_idle_outline_tween: Tween

@export_group("Planning")
var is_planning_move:= false
var planning_facing: Vector2i = Vector2i.RIGHT
var planning_grid_pos: Vector2i
var planning_step: int
var planning_grids_in_range: Array[BaseGrid]
var previewed_grids: Array[Vector2i]
@export var outline_selected_color:= Color.CORAL
@export var outline_available_color:= Color.YELLOW_GREEN

# Velocity-based movement control variables
var velocity_threshold: float = 5  # Minimum accumulated velocity to trigger movement
var movement_cooldown_time: float = 0.1  # Time between movements in seconds
var last_movement_time: float = 0.0  # Track when last movement occurred

@export_group("Animation")
@export var step_time:= 0.5
var planned_move_grid_positions: Array[Vector2i]
@onready var player_animation_tree:= %"Player AnimationTree"
@onready var player_sprite:= %"Player Sprite"
var is_player_moving:= false:
	set(value):
		is_player_moving = value
		match value:
			true:
				player_animation_tree["parameters/playback"].travel("Walk")
				player_sprite.texture = ResourceLoader.load("res://Assets/Sprites/Character/isometric_character_walk.png")
				player_sprite.hframes = 12
				player_sprite.vframes = 8
			false:
				player_animation_tree["parameters/playback"].travel("Idle")
				player_sprite.texture = ResourceLoader.load("res://Assets/Sprites/Character/isometric_character_idle.png")
				player_sprite.hframes = 8
				player_sprite.vframes = 8

signal plan_move_started
signal move_completed

func _ready() -> void:
	player_move_range = player_initial_move_range
	player_grid_pos = player_initial_grid_pos
	player_facing = player_initial_facing
	is_player_moving = false
	# GridManager.moused_clicked_down_grid.connect(start_plan_move)
	if input_style_cursor:
		GridManager.moused_entered_grid.connect(step_plan_move)
		GridManager.moused_clicked_down_grid.connect(complete_plan_move)
	UpgradeManager.upgrade_added.connect(on_upgrade_added)
	GameManager.game_state_changed.connect(idle_set_player_grid_outline)

	get_viewport().physics_object_picking_first_only = true
	get_viewport().physics_object_picking_sort = true


func _input(event: InputEvent) -> void:
	if is_planning_move && event.is_action_pressed("right_click"):
		GameManager.resume_last_game_state()
		cancel_plan_move()

	if !input_style_cursor:
		if is_planning_move && event is InputEventMouseMotion:
			var mouse_motion := event as InputEventMouseMotion
			if mouse_motion.relative.length() > velocity_threshold:
				handle_velocity_based_movement(mouse_motion.relative)
				
		if is_planning_move && event.is_action_pressed("left_click"):
			CursorManager.cursor_visible(true)
			complete_plan_move(planning_grid_pos)


func start_plan_move(grid_pos: Vector2i):
	#print("Manager received signals from:" + str(grid_pos) + " Clicked Down")
	if not is_player_at_grid(grid_pos): return
	if not is_planning_move:
		is_planning_move = true
		GameManager.switch_game_state(GameManager.GameState.Plan)
		plan_move_started.emit()
		planning_grid_pos = grid_pos
		planning_facing = player_facing
		planning_step = player_move_range
		planning_grids_in_range = GridManager.get_grids_in_range(grid_pos, planning_step, planning_facing, moving_backwards_unlocked)
		line_drawer.add_draw_point(GridManager.grid_database[grid_pos].position)
		planned_move_grid_positions.append(planning_grid_pos)
		
		# Reset movement timer when starting planning
		if !input_style_cursor:
			last_movement_time = 0.0
		
		update_grid_outline()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.START_PLANNING)


func handle_velocity_based_movement(velocity: Vector2) -> void:
	# Check if enough time has passed since last movement
	var current_time: float = Time.get_ticks_msec() / 1000.0  # Convert to seconds
	if current_time - last_movement_time < movement_cooldown_time:
		return
	
	# Determine the strongest direction from velocity
	var direction := get_dominant_direction(velocity)
	
	# Only process if there's a valid direction
	if direction != Vector2i.ZERO:
		var target_grid_pos := planning_grid_pos + direction
		step_plan_move(target_grid_pos)
		last_movement_time = current_time  # Update last movement time


func get_dominant_direction(velocity: Vector2) -> Vector2i:
	# Convert 2D screen velocity to isometric grid movement
	# Isometric mapping: 
	# Screen up-left diagonal -> game UP (左上 = 上)
	# Screen up-right diagonal -> game RIGHT (右上 = 右)  
	# Screen down-left diagonal -> game LEFT (左下 = 左)
	# Screen down-right diagonal -> game DOWN (右下 = 下)
	
	# Transform screen coordinates to isometric diagonal coordinates
	# Rotate by 45 degrees to align with isometric axes
	var iso_x: float = velocity.x + velocity.y  # right-down diagonal
	var iso_y: float = velocity.x - velocity.y  # right-up diagonal
	
	var abs_iso_x: float = abs(iso_x)
	var abs_iso_y: float = abs(iso_y)
	
	# Determine the dominant isometric axis
	if abs_iso_x > abs_iso_y:
		# Right-down / Left-up diagonal dominant
		if iso_x > 0:
			# Right-down diagonal -> game DOWN (右下 = 下)
			return Vector2i.DOWN
		else:
			# Left-up diagonal -> game UP (左上 = 上)
			return Vector2i.UP
	elif abs_iso_y > abs_iso_x:
		# Right-up / Left-down diagonal dominant
		if iso_y > 0:
			# Right-up diagonal -> game RIGHT (右上 = 右)
			return Vector2i.RIGHT
		else:
			# Left-down diagonal -> game LEFT (左下 = 左)
			return Vector2i.LEFT
	else:
		# No clear dominant direction or velocity too weak
		return Vector2i.ZERO


func step_plan_move(grid_pos: Vector2i):
	#print("Manager received signals from:" + str(grid_pos) + " Entered")
	if is_planning_move:
		# check neighbouring
		if GridManager.grid_database[planning_grid_pos].neighbour_grids.has(grid_pos):
			var dir = grid_pos - planning_grid_pos
			# withdraw
			if planned_move_grid_positions[planned_move_grid_positions.size() - 2] == grid_pos:
				planning_grid_pos = grid_pos
				planning_step += 1
				# withdraw to beginning
				if planned_move_grid_positions.size() <= 2:
					planning_facing = player_facing
					planning_grids_in_range = GridManager.get_grids_in_range(grid_pos, planning_step, planning_facing, moving_backwards_unlocked)
				else:
					planning_facing = planned_move_grid_positions[planned_move_grid_positions.size() - 2] - planned_move_grid_positions[planned_move_grid_positions.size() - 3]
					planning_grids_in_range = GridManager.get_grids_in_range(grid_pos, planning_step, planning_facing)
				line_drawer.withdraw_point()
				planned_move_grid_positions.remove_at(planned_move_grid_positions.size() - 1)
				
				update_grid_outline()
				update_preview()
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.STEP_PLANNING)
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
				update_preview()
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.STEP_PLANNING)


func complete_plan_move(grid_pos: Vector2i) -> void:
	if is_planning_move and grid_pos == planning_grid_pos and planning_step != player_move_range:
		#is_player_moving = true
		clear_preview()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.COMPLETE_PLANNING)
		
		GridManager.grid_database[player_grid_pos].depart()
		if interaction_distance_unlocked:
			for neighbour_grid_pos in GridManager.grid_database[player_grid_pos].neighbour_grids:
				GridManager.grid_database[neighbour_grid_pos].depart()
				
		GameManager.switch_game_state(GameManager.GameState.Move)
		player_facing = planning_facing
		var move_grid_positions: Array[Vector2i]
		planned_move_grid_positions.remove_at(0)
		move_grid_positions.append_array(planned_move_grid_positions)
		
		line_drawer.finish_draw()
		is_planning_move = false
		planning_grids_in_range.clear()
		planning_grid_pos = Vector2i(-1, -1)
		
		update_grid_outline()

		await _move_player_step_by_step(move_grid_positions)

		player_grid_pos = grid_pos
		#is_player_moving = false
		TimeManager.add_step_hour()
		await GridManager.grid_database[player_grid_pos].arrive()
		if interaction_distance_unlocked:
			for neighbour_grid_pos in GridManager.grid_database[player_grid_pos].neighbour_grids:
				await GridManager.grid_database[neighbour_grid_pos].arrive()
		
		GameManager.switch_game_state(GameManager.GameState.Idle)
		move_completed.emit()


func _move_player_step_by_step(path: Array[Vector2i]) -> void:
	for grid_position in path:
		is_player_moving = true
		var target_pos = GridManager.grid_database[grid_position].global_position
		var tween = create_tween()
		tween.tween_property(get_parent(), "position", target_pos, step_time).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
		player_facing = grid_position - player_grid_pos
		await tween.finished
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.MOVING)
		is_player_moving = false
		player_grid_pos = grid_position
		planned_move_grid_positions.remove_at(0)
		update_grid_outline()
		
		#Logic: if not destination
		if path[-1] != grid_position:
			await GridManager.grid_database[player_grid_pos].bypass()


func cancel_plan_move():
	line_drawer.finish_draw()
	is_planning_move = false
	planning_grids_in_range.clear()
	planned_move_grid_positions.clear()
	
	# Reset movement timer
	if !input_style_cursor:
		last_movement_time = 0.0
		CursorManager.cursor_visible(true)
	
	update_grid_outline()
	update_preview()
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.CANCEL)


func update_preview():
	# 清空旧 preview
	for pos in previewed_grids:
		GridManager.grid_database[pos].try_arrive(false)
		GridManager.grid_database[pos].try_bypass(false)
	previewed_grids.clear()

	# 路径上的格子 bypass (ignore start pos and destination)
	for pos in planned_move_grid_positions.slice(1, -1):
		GridManager.grid_database[pos].try_bypass(true)
		previewed_grids.append(pos)

	# 当前停留点 arrive (start pos ignored when == destination)
	if planned_move_grid_positions.size() > 1:
		var last_pos = planned_move_grid_positions[-1]
		GridManager.grid_database[last_pos].try_arrive(true)
		previewed_grids.append(last_pos)

		# 邻居交互格子
		if interaction_distance_unlocked:
			for neighbour in GridManager.grid_database[last_pos].neighbour_grids:
				GridManager.grid_database[neighbour].try_arrive(true)
				previewed_grids.append(neighbour)


func clear_preview():
	if !previewed_grids.is_empty():
		for pos in previewed_grids:
			GridManager.grid_database[pos].try_arrive(false)
			GridManager.grid_database[pos].try_bypass(false)
		previewed_grids.clear()


func update_grid_outline():
	for grid: BaseGrid in GridManager.grid_database.values():
		if grid.outline_tween:
			grid.outline_tween.kill()
		grid.outline_tween = create_tween()
		if planned_move_grid_positions.has(grid.grid_position):
			if grid.grid_position == planning_grid_pos:
				grid.outline_tween.set_loops()
				grid.outline_tween.tween_property(grid.grid_outline, "modulate", Color.TRANSPARENT, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				grid.outline_tween.tween_property(grid.grid_outline, "modulate", outline_selected_color, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
				grid.outline_tween.tween_interval(0.25)
			else:
				grid.outline_tween.tween_property(grid.grid_outline, "modulate", outline_selected_color, 0.1)
		elif planning_grids_in_range.has(grid):
			grid.outline_tween.tween_property(grid.grid_outline, "modulate", outline_available_color, 0.1)
		else:
			grid.outline_tween.tween_property(grid.grid_outline, "modulate", Color.TRANSPARENT, 0.2)


func idle_set_player_grid_outline():
	if player_idle_outline_tween:
		player_idle_outline_tween.kill()
	player_idle_outline_tween = create_tween()
	if GameManager.current_game_state == GameManager.GameState.Idle:
		player_idle_outline_tween.tween_property(player_idle_outline, "modulate", Color.BLACK, 0.1)
		player_idle_outline_tween.set_loops()
		player_idle_outline_tween.tween_property(player_idle_outline, "scale", Vector2.ONE * 0.8, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		player_idle_outline_tween.tween_property(player_idle_outline, "scale", Vector2.ONE * 0.7, 0.25).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		player_idle_outline_tween.tween_interval(0.75)
	else:
		player_idle_outline_tween.tween_property(player_idle_outline, "modulate", Color.TRANSPARENT, 0.1)


func is_player_at_grid(grid_pos: Vector2i) -> bool:
	return grid_pos == player_grid_pos


#func update_player_animation():
	#match is_player_moving:
		#true:
			#player_animation_tree["parameters/playback"].travel("Walk")
		#false:
			#player_animation_tree["parameters/playback"].travel("Idle")
	#player_animation_tree.set("parameters/Idle/blend_position", player_facing)
	#player_animation_tree.set("parameters/Walk/blend_position", player_facing)


func on_upgrade_added(upgrade: Upgrade):
	match upgrade.upgrade_name:
		"move speed +":
			player_move_range = player_initial_move_range + UpgradeManager.get_upgrade_level(upgrade) * upgrade.effect_delta_per_level
		"increase interaction distance":
			interaction_distance_unlocked = true
		"moving backward":
			moving_backwards_unlocked = true


func _on_area_2d_mouse_entered() -> void:
	# if GameManager.current_game_state == GameManager.GameState.Idle:
		player_sprite.use_parent_material = false


func _on_area_2d_mouse_exited() -> void:
	player_sprite.use_parent_material = true


func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if GameManager.current_game_state == GameManager.GameState.Idle:
		if event.is_action_pressed("left_click"):
			start_plan_move(player_grid_pos)
			if !input_style_cursor:
				CursorManager.cursor_visible(false)
