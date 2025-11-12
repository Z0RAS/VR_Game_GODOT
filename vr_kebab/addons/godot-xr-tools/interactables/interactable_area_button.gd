@tool
class_name XRToolsInteractableAreaButton
extends Area3D

signal button_pressed(button)
signal button_released(button)

@export var displacement: Vector3 = Vector3(0.0, -0.02, 0.0)
@export var duration: float = 0.1

var pressed: bool = false
var _trigger_items := {}
var _tween: Tween

# Mygtuko MeshInstance3D – dabar imame parent (root)
@onready var _button: MeshInstance3D = get_parent() as MeshInstance3D
@onready var _button_up := _button.position
@onready var _button_down := _button_up + displacement

func _ready():
	# Connect signals
	area_entered.connect(_on_button_entered)
	area_exited.connect(_on_button_exited)
	body_entered.connect(_on_button_entered)
	body_exited.connect(_on_button_exited)

func _on_button_entered(item: Node) -> void:
	if _trigger_items.has(item):
		return
	_trigger_items[item] = true
	print("Iėjo:", item.name)

	if not pressed:
		pressed = true
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.set_trans(Tween.TRANS_LINEAR)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_button, "position", _button_down, duration)
		button_pressed.emit()

func _on_button_exited(item: Node) -> void:
	if _trigger_items.has(item):
		_trigger_items.erase(item)
		print("Išejo:", item.name)

	if pressed and _trigger_items.is_empty():
		pressed = false
		if _tween:
			_tween.kill()
		_tween = get_tree().create_tween()
		_tween.set_trans(Tween.TRANS_LINEAR)
		_tween.set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(_button, "position", _button_up, duration)
		button_released.emit(self)
