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

@onready var grid_outline: Sprite2D = $"Grid Outline"
var outline_tween: Tween

signal mouse_entered(grid_position: Vector2i)
signal mouse_exited(grid_position: Vector2i)
signal mouse_clicked_down(grid_position: Vector2i)


func _ready() -> void:
	add_to_group("Grids")
	outline_tween = create_tween()


func _process(delta: float) -> void:
	pass


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
