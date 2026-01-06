@tool
extends Node3D

@export var lift_button: XRToolsInteractableAreaButton
@export var lower_button: XRToolsInteractableAreaButton
@export var lift_amount: float = 2.0
@export var duration: float = 0.5

# Audio
@export var door_open_sfx: AudioStream
@export var door_close_sfx: AudioStream  # optional

# Internal
var _tween: Tween
var _start_y: float
var door_opened_sfx_played: bool = false  # ensure SFX plays only once

func _ready():
	_start_y = global_position.y

	if lift_button:
		lift_button.button_pressed.connect(_on_lift_pressed)
	if lower_button:
		lower_button.button_pressed.connect(_on_lower_pressed)

func _on_lift_pressed():
	# Only play/open if door isn’t already fully lifted
	if global_position.y < _start_y + lift_amount:
		_tween_door_to(_start_y + lift_amount)

		# Play door open SFX once
		if not door_opened_sfx_played:
			AudioManager.play_sfx(door_open_sfx, 0.8)
			door_opened_sfx_played = true

func _on_lower_pressed():
	# Only play/close if door isn’t already at start
	if global_position.y > _start_y:
		_tween_door_to(_start_y)

		# Optional: play door close SFX
		if door_close_sfx:
			AudioManager.play_sfx(door_close_sfx, 0.8)
			door_opened_sfx_played = false


func _tween_door_to(target_y: float):
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.set_ease(Tween.EASE_IN_OUT)

	var new_pos = global_position
	new_pos.y = target_y
	_tween.tween_property(self, "global_position", new_pos, duration)
