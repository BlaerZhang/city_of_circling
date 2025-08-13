extends Node

enum GameState{
	Idle,
	Plan,
	Move,
	Resolve,
	Draw,
}

var input_lock:= false
var grid_input_lock:= false
var current_game_state:= GameState.Idle
var last_game_state:= GameState.Idle

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	switch_game_state(GameState.Idle)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func resume_last_game_state():
	switch_game_state(last_game_state)


func switch_game_state(game_state: GameState):
	last_game_state = current_game_state
	current_game_state = game_state
	match game_state:
		GameState.Idle, GameState.Plan:
			input_lock = false
			grid_input_lock = false
		GameState.Draw:
			input_lock = false
			grid_input_lock = true
		GameState.Move, GameState.Resolve:
			input_lock = true
			grid_input_lock = true
