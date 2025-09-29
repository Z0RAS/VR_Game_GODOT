extends Node3D

@export var npc_scene: PackedScene
@export var npc_count: int = 5
@export var spawn_interval: float = 10.0  # seconds between spawns
@export var spawn_position: Node3D
@export var first_target_position: Node3D
@export var formation_start_position: Node3D
@export var walk_speed: float = 4.0
@export var x_spacing: float = 2.0  # distance between NPCs in formation

var timer: float = 0.0
var spawned_count: int = 0

func _ready():
	timer = spawn_interval

func _process(delta):
	timer -= delta
	if timer <= 0 and spawned_count < npc_count:
		spawn_npc()
		timer = spawn_interval
		spawned_count += 1

func spawn_npc():
	var npc = npc_scene.instantiate()
	add_child(npc)
	
	# Calculate formation X position
	var formation_pos = formation_start_position.global_transform.origin
	formation_pos.x += spawned_count * x_spacing
	
	# Calculate speed for first move (distance / 2s)
	var distance = horizontal_distance(spawn_position.global_transform.origin, first_target_position.global_transform.origin)
	var speed_for_first_move = distance / 2.0
	
	npc.init(
		spawn_position.global_transform.origin,
		first_target_position.global_transform.origin,
		formation_pos,
		speed_for_first_move
	)

func horizontal_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z))
