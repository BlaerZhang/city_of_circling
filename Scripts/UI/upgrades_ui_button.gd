extends Button

@onready var container:= $VBoxContainer
var showing:= false
var is_tween_playing:= false

func _ready() -> void:
	container.scale = Vector2.ZERO


func _process(delta: float) -> void:
	if Input.is_action_pressed("left_click") && !self.is_hovered() && !is_tween_playing && showing:
		is_tween_playing = true
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIDE_SHOP)
		var hide_upgrade_ui_tween = create_tween()
		hide_upgrade_ui_tween.tween_property(container, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_EXPO)
		hide_upgrade_ui_tween.tween_callback(func(): 
			is_tween_playing = false
			showing = false
			)


func _on_pressed() -> void:
	if is_tween_playing or showing: return
	is_tween_playing = true
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SHOW_PANEL)
	var show_upgrade_ui_tween = create_tween()
	show_upgrade_ui_tween.tween_property(container, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_EXPO)
	show_upgrade_ui_tween.tween_callback(func(): 
		is_tween_playing = false
		showing = true
		)
