extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


var start_position: Vector3
var first_target: Vector3
var formation_position: Vector3

var state: String = "moving_to_first"
var wait_timer: float = 0.0
var player: Node3D = null

func init(start: Vector3, first: Vector3, formation: Vector3, speed: float):
	start_position = start
	first_target = first
	formation_position = formation
	walk_speed = speed
	global_transform.origin = start_position
	state = "moving_to_first"

func _ready():
	# Try to find player in scene tree
	if has_node("/root/Main/XROrigin3D/PlayerBody"):
		player = get_node("/root/Main/XROrigin3D/PlayerBody")

func _physics_process(delta):
	# Apply gravity if not grounded
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0  # keep stable on floor

	# Face player
	if player:
		var npc_pos = global_transform.origin
		var target_pos = player.global_transform.origin
		target_pos.y = npc_pos.y
		look_at(target_pos, Vector3.UP)
		rotate_y(deg_to_rad(180))

	# State machine (unchanged)
	match state:
		"moving_to_first":
			move_to_point(first_target)
			if horizontal_distance(global_transform.origin, first_target) < 0.05:
				state = "waiting"
				wait_timer = 2.0
				velocity.x = 0
				velocity.z = 0
		"waiting":
			wait_timer -= delta
			if wait_timer <= 0:
				state = "moving_to_formation"
		"moving_to_formation":
			move_to_point(formation_position)
			if horizontal_distance(global_transform.origin, formation_position) < 0.05:
				state = "idle"
				velocity.x = 0
				velocity.z = 0
		"idle":
			velocity.x = 0
			velocity.z = 0

	# Finally move
	move_and_slide()

func move_to_point(target: Vector3):
	var current = global_transform.origin
	var target_flat = Vector3(target.x, current.y, target.z)
	var direction = target_flat - current
	if direction.length() > 0.01:
		var horizontal_velocity = direction.normalized() * walk_speed
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z


func horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
