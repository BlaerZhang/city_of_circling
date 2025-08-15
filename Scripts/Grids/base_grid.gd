class_name BaseGrid
extends Sprite2D

enum GridType{
	Vanilla,
	NPC,
	Upgrade_Shop,
	Lottery,
	Shop,
}

@export var grid_type:= GridType.Vanilla
@export var grid_position: Vector2i
var neighbour_grids: Array[Vector2i]

@onready var functional_grid_component:= get_node_or_null("Functional Component")

@onready var grid_outline: Sprite2D = $"Grid Outline"
var outline_tween: Tween

signal mouse_entered(grid_position: Vector2i)
signal mouse_exited(grid_position: Vector2i)
signal mouse_clicked_down(grid_position: Vector2i)


func _ready() -> void:
	add_to_group("Grids")


func _process(delta: float) -> void:
	pass


func bypass():
	if functional_grid_component is FunctionalGridComponent:
		await functional_grid_component.bypass()
		GameManager.switch_game_state(GameManager.GameState.Move)


func arrive():
	if functional_grid_component is FunctionalGridComponent:
		await functional_grid_component.arrive()
		GameManager.switch_game_state(GameManager.GameState.Idle)


func depart():
	if functional_grid_component is FunctionalGridComponent:
		await functional_grid_component.depart()


func interact():
	if functional_grid_component is FunctionalGridComponent:
		await functional_grid_component.interact(grid_position)


func try_bypass(forward: bool):
	if functional_grid_component is FunctionalGridComponent:
		functional_grid_component.try_bypass(forward)


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		mouse_clicked_down.emit(grid_position)
		#print(str(grid_position) + "Clicked")


func _on_area_2d_mouse_entered() -> void:
	mouse_entered.emit(grid_position)
	#print(str(grid_position) + "Entered")


func _on_area_2d_mouse_exited() -> void:
	mouse_exited.emit(grid_position)
	#print(str(grid_position) + "Exited")
