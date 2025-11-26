@tool
extends Node3D

@export var lift_button: XRToolsInteractableAreaButton
@export var lower_button: XRToolsInteractableAreaButton
@export var lift_amount: float = 2.0
@export var duration: float = 0.5

var _tween: Tween
var _start_y: float

func _ready():
	_start_y = global_position.y

	if lift_button:
		lift_button.button_pressed.connect(_on_lift_pressed)
	if lower_button:
		lower_button.button_pressed.connect(_on_lower_pressed)

func _on_lift_pressed():
	_tween_door_to(_start_y + lift_amount)

func _on_lower_pressed():
	_tween_door_to(_start_y)

func _tween_door_to(target_y: float):
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.set_ease(Tween.EASE_IN_OUT)

	var new_pos = global_position
	new_pos.y = target_y
	_tween.tween_property(self, "global_position", new_pos, duration)
