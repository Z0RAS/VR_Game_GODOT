# res://scripts/Mouse3D.gd
extends RigidBody3D

@export var computer_path: NodePath
@export var movement_scale: float = 200.0
@export var viewport_size: Vector2 = Vector2(512,512)

var last_pos := Vector3.ZERO
var mouse_pos := Vector2(256,256)

func _ready():
	last_pos = global_transform.origin
	if $ClickArea:
		$ClickArea.body_entered.connect(_on_click_down)
	# prevent tumbling
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true

func _physics_process(_delta):
	var cur = global_transform.origin
	var delta = cur - last_pos
	last_pos = cur

	var dx = delta.x * movement_scale
	var dy = -delta.z * movement_scale
	mouse_pos += Vector2(dx, dy)
	mouse_pos = mouse_pos.clamp(Vector2.ZERO, viewport_size)

	if has_node(computer_path):
		var comp = get_node(computer_path)
		comp.call("set_mouse_position", mouse_pos)

func _on_click_down(body):
	if body.is_in_group("hands"):
		if has_node(computer_path):
			var comp = get_node(computer_path)
			comp.call("click_mouse", mouse_pos)
