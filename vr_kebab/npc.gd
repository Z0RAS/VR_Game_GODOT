extends CharacterBody3D

@export var walk_speed: float = 4.0

var start_position: Vector3
var first_target: Vector3
var formation_position: Vector3

var state: String = "moving_to_first"
var wait_timer: float = 0.0

func init(start: Vector3, first: Vector3, formation: Vector3, speed: float):
	start_position = start
	first_target = first
	formation_position = formation
	walk_speed = speed
	global_transform.origin = start_position
	state = "moving_to_first"

func _physics_process(delta):
	match state:
		"moving_to_first":
			move_to_point(first_target)
			if horizontal_distance(global_transform.origin, first_target) < 0.05:
				global_transform.origin.x = first_target.x
				global_transform.origin.z = first_target.z
				state = "waiting"
				wait_timer = 2.0  # wait 2s
				velocity = Vector3.ZERO
		"waiting":
			wait_timer -= delta
			if wait_timer <= 0:
				state = "moving_to_formation"
		"moving_to_formation":
			move_to_point(formation_position)
			if horizontal_distance(global_transform.origin, formation_position) < 0.05:
				global_transform.origin.x = formation_position.x
				global_transform.origin.z = formation_position.z
				velocity = Vector3.ZERO
				state = "idle"
		"idle":
			velocity = Vector3.ZERO

func move_to_point(target: Vector3):
	var current = global_transform.origin
	var target_flat = Vector3(target.x, current.y, target.z)
	var direction = target_flat - current
	if direction.length() > 0.01:
		velocity = direction.normalized() * walk_speed
		move_and_slide()

func horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
