@tool
class_name XRToolsInteractableAreaButton
extends MeshInstance3D

signal button_pressed(button)
signal button_released(button)

@export var displacement: Vector3 = Vector3(0, -0.02, 0)
@export var duration: float = 0.1
@export var area_node: NodePath  # assign the Area3D child

var pressed: bool = false
var _trigger_items := {}
var _tween: Tween

@onready var _area_ref: Area3D = $Area3D
@onready var _button_up := position
@onready var _button_down := _button_up + displacement

func _ready():
	if not _area_ref:
		push_error("Area3D node not assigned")
		return

	# Connect signals from Area3D
	_area_ref.area_entered.connect(_on_area_entered)
	_area_ref.area_exited.connect(_on_area_exited)
	_area_ref.body_entered.connect(_on_area_entered)
	_area_ref.body_exited.connect(_on_area_exited)

func _on_area_entered(item: Node) -> void:
	if _trigger_items.has(item):
		return
	_trigger_items[item] = true

	if not pressed:
		pressed = true
		_tween_button(_button_down)
		button_pressed.emit()

func _on_area_exited(item: Node) -> void:
	if _trigger_items.has(item):
		_trigger_items.erase(item)

	if pressed and _trigger_items.is_empty():
		pressed = false
		_tween_button(_button_up)
		button_released.emit()

func _tween_button(to_position: Vector3) -> void:
	if _tween:
		_tween.kill()
	_tween = get_tree().create_tween()
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "position", to_position, duration)
