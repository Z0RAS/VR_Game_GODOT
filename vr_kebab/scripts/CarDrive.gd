extends Node3D

@export var car_scene: PackedScene         # Mašinos scena (Sprite3D ar MeshInstance3D)
@export var start_points: Array[Node3D]   # Pradžios taškai (5)
@export var end_points: Array[Node3D]     # Pabaigos taškai (5)
@export var speed: float = 5.0             # Greitis
@export var spawn_interval: float = 2.0    # Laikas tarp spawno

var cars: Array = []

func _ready():
	spawn_loop()  # start spawn loop

# ================================
# Spawn loop su await
# ================================
func spawn_loop() -> void:
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		spawn_car()

# ================================
# Spawn car su random start-end
# ================================
func spawn_car() -> void:
	if start_points.size() == 0 or end_points.size() == 0:
		return

	# Random start ir end
	var path_index = randi() % start_points.size()
	var start_pos = start_points[path_index].global_transform.origin
	var end_pos = end_points[path_index].global_transform.origin

	# Atsitiktinai apsukti start→end arba end→start
	var reverse = randf() < 0.5
	if reverse:
		var tmp = start_pos
		start_pos = end_pos
		end_pos = tmp

	# Instantiate mašina
	var car = car_scene.instantiate()
	add_child(car)
	car.global_transform.origin = start_pos

	# Apsisukimas 180° jei reikia
	if reverse:
		car.rotate_y(deg_to_rad(180))

	# Į masyvą įdedam car info
	cars.append({
		"node": car,
		"start_pos": start_pos,
		"end_pos": end_pos,
		"direction": 1 if not reverse else -1
	})

# ================================
# Judėjimas
# ================================
func _process(delta: float) -> void:
	for car_data in cars.duplicate():
		var car_node = car_data["node"]
		var start_pos = car_data["start_pos"]
		var end_pos = car_data["end_pos"]
		var dir = car_data["direction"]

		# Judam link end_pos
		var move_vec = (end_pos - start_pos).normalized() * speed * delta * dir
		car_node.global_transform.origin += move_vec

		# Patikrinam ar pasiekė galą
		if (car_node.global_transform.origin - end_pos).length() < 0.1:
			cars.erase(car_data)
			car_node.queue_free()
