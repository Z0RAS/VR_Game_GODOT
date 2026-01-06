extends Node3D

@onready var skeleton: Skeleton3D = $Skeleton3D

# Kaulai
const R_ARM = "Character1_RightShoulder_028"
const L_ARM = "Character1_LeftShoulder_00"
const R_LEG = "Character1_RightUpLeg_06"
const L_LEG = "Character1_LeftUpLeg_02"
const NECK  = "Character1_Neck_044"

@export var walk_speed := 6.0
@export var arm_amp := 0.6
@export var leg_amp := 0.7

var walk_time := 0.0
var is_walking := false

# Idle variables
var idle_time := 0.0
var idle_cooldown := 0.0
var current_pose: Dictionary = {}
var target_pose: Dictionary = {}
var move_stage: String = ""
var is_leaving: bool = false
var speed: float = 2.5

@export var pose_lerp_speed := 2.5  # Greitis, kaip greitai pereina tarp pozų

# ----------------------------
func _process(delta):
	if is_walking:
		walk_time += delta * walk_speed

		set_bone_leg(R_LEG, sin(walk_time) * leg_amp)
		set_bone_leg(L_LEG, sin(walk_time + PI) * leg_amp)

		set_bone_arm(R_ARM, sin(walk_time + PI) * arm_amp)
		set_bone_arm(L_ARM, sin(walk_time) * arm_amp)

		set_bone_arm(NECK, sin(walk_time * 0.5) * 0.15)
	else:
		idle_pose_random(delta)

# ----------------------------
# Rankų ir kojų rotacija
func set_bone_arm(bone: String, value: float):
	var idx := skeleton.find_bone(bone)
	if idx == -1:
		return

	var pose := skeleton.get_bone_global_pose(idx)
	var origin := pose.origin

	var euler := pose.basis.get_euler()
	euler.x = value
	pose.basis = Basis.from_euler(euler)
	pose.origin = origin

	skeleton.set_bone_global_pose_override(idx, pose, 1.0, true)

func set_bone_leg(bone: String, value: float):
	var idx := skeleton.find_bone(bone)
	if idx == -1:
		return

	var pose := skeleton.get_bone_global_pose(idx)
	var origin := pose.origin

	var euler := pose.basis.get_euler()
	euler.z = value
	pose.basis = Basis.from_euler(euler)
	pose.origin = origin

	skeleton.set_bone_global_pose_override(idx, pose, 1.0, true)

func set_bone_idle(bone: String, value: float):
	var idx := skeleton.find_bone(bone)
	if idx == -1:
		return

	var pose := skeleton.get_bone_global_pose(idx)
	var origin := pose.origin

	var euler := pose.basis.get_euler()

	if bone == R_ARM or bone == L_ARM:
		euler.x = value
	elif bone == R_LEG or bone == L_LEG:
		euler.z = value
	else:
		euler.z = value  # kaklas, galima keisti į y jei reikia

	pose.basis = Basis.from_euler(euler)
	pose.origin = origin
	skeleton.set_bone_global_pose_override(idx, pose, 1.0, true)

# ----------------------------
# Smooth random idle
func idle_pose_random(delta):
	idle_time += delta
	idle_cooldown -= delta

	# Use dramatic poses 80% of the time (increased from 20%)
	var use_jojo = false
	if randf() < 0.8 and idle_cooldown <= 0:
		use_jojo = true

	if idle_cooldown <= 0 or current_pose.size() == 0:
		if use_jojo:
			target_pose = jojo_poses[randi() % jojo_poses.size()]
		else:
			target_pose = generate_random_pose()
		idle_cooldown = randf_range(2.0, 5.0)  # Increased from 0.1-0.5 to 2-5 seconds

	# Smooth perejimas
	for key in target_pose.keys():
		if not current_pose.has(key):
			current_pose[key] = target_pose[key]
		else:
			current_pose[key] = lerp(float(current_pose[key]), float(target_pose[key]), delta * pose_lerp_speed)


	apply_pose(current_pose)

var jojo_poses = [
	# 1 – ranka į šoną, kita prie veido, kojos plačiai
	{ "R_ARM": 1.0, "L_ARM": -0.8, "R_LEG": 0.5, "L_LEG": -0.5, "NECK": 0.25, "WOBBLE_X":0.03, "WOBBLE_Y":0, "WOBBLE_Z":8 },
	# 2 – pasilenkęs atgal, rankos į viršų, kojos suglaustos
	{ "R_ARM": 1.2, "L_ARM": 1.2, "R_LEG": 0.0, "L_LEG": 0.0, "NECK": -0.15, "WOBBLE_X":0, "WOBBLE_Y":0, "WOBBLE_Z":-10 },
	# 3 – „Attack on Titan“ dedicate your hearts
	{ "R_ARM": -1.0, "L_ARM": 1.0, "R_LEG": 0.25, "L_LEG": -0.25, "NECK": 0.35, "WOBBLE_X":0.01, "WOBBLE_Y":0.015, "WOBBLE_Z":5 },
	# 4 – crazy dramatic lean, rankos į skirtingas puses
	{ "R_ARM": 0.9, "L_ARM": -1.2, "R_LEG": 0.4, "L_LEG": -0.4, "NECK": 0.5, "WOBBLE_X":0.04, "WOBBLE_Y":0.025, "WOBBLE_Z":12 },
	# 5 – The Thinker - one arm up to chin, leaning forward
	{ "R_ARM": -0.9, "L_ARM": 0.15, "R_LEG": 0.15, "L_LEG": -0.15, "NECK": 0.4, "WOBBLE_X":0.015, "WOBBLE_Y":0.01, "WOBBLE_Z":2 },
	# 6 – Stretching - both arms up high, leaning back
	{ "R_ARM": 1.4, "L_ARM": 1.4, "R_LEG": -0.2, "L_LEG": 0.2, "NECK": -0.25, "WOBBLE_X":0, "WOBBLE_Y":0.02, "WOBBLE_Z":-7 },
	# 7 – Casual lean - arms crossed style
	{ "R_ARM": -0.4, "L_ARM": -0.4, "R_LEG": 0.3, "L_LEG": -0.05, "NECK": 0.1, "WOBBLE_X":-0.02, "WOBBLE_Y":0, "WOBBLE_Z":6 },
	# 8 – Looking around - neck turned, one leg out
	{ "R_ARM": 0.25, "L_ARM": -0.25, "R_LEG": 0.45, "L_LEG": 0.1, "NECK": 0.6, "WOBBLE_X":0.03, "WOBBLE_Y":0, "WOBBLE_Z":4 },
	# 9 – Impatient tap - slight crouch, arms down
	{ "R_ARM": -0.15, "L_ARM": 0.1, "R_LEG": -0.25, "L_LEG": 0.25, "NECK": -0.1, "WOBBLE_X":0.01, "WOBBLE_Y":-0.01, "WOBBLE_Z":-2 },
	# 10 – Confident stance - wide legs, hands on hips style
	{ "R_ARM": -0.6, "L_ARM": 0.6, "R_LEG": 0.6, "L_LEG": -0.6, "NECK": 0.2, "WOBBLE_X":0, "WOBBLE_Y":0, "WOBBLE_Z":9 },
	# 11 – Checking phone pose - one arm bent up
	{ "R_ARM": -1.1, "L_ARM": 0.4, "R_LEG": 0.1, "L_LEG": 0.35, "NECK": 0.45, "WOBBLE_X":0.02, "WOBBLE_Y":0.005, "WOBBLE_Z":3 },
	# 12 – Tired lean - slouched, arms relaxed
	{ "R_ARM": 0.15, "L_ARM": 0.2, "R_LEG": -0.15, "L_LEG": 0.15, "NECK": -0.2, "WOBBLE_X":0.025, "WOBBLE_Y":-0.015, "WOBBLE_Z":-5 },
	# 13 – Dramatic point - one arm extended
	{ "R_ARM": 1.15, "L_ARM": -0.25, "R_LEG": 0.25, "L_LEG": -0.35, "NECK": 0.3, "WOBBLE_X":0.035, "WOBBLE_Y":0.01, "WOBBLE_Z":10 },
	# 14 – Ninja stealth pose
	{ "R_ARM": -0.75, "L_ARM": 1.0, "R_LEG": 0.45, "L_LEG": -0.2, "NECK": 0.15, "WOBBLE_X":-0.03, "WOBBLE_Y":0.005, "WOBBLE_Z":-4 },
	# 15 – Superhero landing prep
	{ "R_ARM": 0.75, "L_ARM": 0.75, "R_LEG": 0.35, "L_LEG": -0.45, "NECK": 0.25, "WOBBLE_X":0.02, "WOBBLE_Y":0.015, "WOBBLE_Z":7 }
]

 
func idle_pose_instant(delta):
	idle_time += delta
	idle_cooldown -= delta

	if idle_cooldown <= 0:
		# Pasirenkame random drastišką JoJo pozą
		current_pose = jojo_poses[randi() % jojo_poses.size()]
		apply_pose(current_pose)
		# Sekantis instant pozu pokytis po 1-3 sek
		idle_cooldown = randf_range(1.0, 3.0)



func generate_random_pose() -> Dictionary:
	return {
		"R_ARM": randf_range(-0.5, 0.5),
		"L_ARM": randf_range(-0.5, 0.5),
		"R_LEG": randf_range(-0.2, 0.2),
		"L_LEG": randf_range(-0.2, 0.2),
		"NECK":  randf_range(-0.3, 0.3),
		"WOBBLE_X": randf_range(-0.05, 0.05),
		"WOBBLE_Y": randf_range(-0.02, 0.02),
		"WOBBLE_Z": randf_range(-10.0, 10.0)
	}

func apply_pose(pose: Dictionary):
	set_bone_idle(R_ARM, pose.get("R_ARM",0))
	set_bone_idle(L_ARM, pose.get("L_ARM",0))
	set_bone_idle(R_LEG, pose.get("R_LEG",0))
	set_bone_idle(L_LEG, pose.get("L_LEG",0))
	set_bone_idle(NECK, pose.get("NECK",0))

# ----------------------------
# Reset funkcija
func reset_pose():
	skeleton.clear_bones_global_pose_override()
	current_pose.clear()
	target_pose.clear()

# --- Body color matching logic ---
func match_body_to_head_color():
	var head_mesh: MeshInstance3D = null
	var body_mesh: MeshInstance3D = null
	# Find head and body mesh instances inside Skeleton3D
	var skeleton_node = $Skeleton3D
	for child in skeleton_node.get_children():
		if child is MeshInstance3D:
			if "head" in child.name.to_lower():
				head_mesh = child
			elif "body" in child.name.to_lower():
				body_mesh = child

		# Always generate a new random color for each NPC
		var npc_color = Color(randf(), randf(), randf())
		if head_mesh:
			var head_mat = head_mesh.get_active_material(0)
			if head_mat:
				var new_head_mat = head_mat.duplicate()
				new_head_mat.albedo_color = npc_color
				head_mesh.set_surface_override_material(0, new_head_mat)
		if body_mesh:
			var body_mat = body_mesh.get_active_material(0)
			if body_mat:
				var new_body_mat = body_mat.duplicate()
				new_body_mat.albedo_color = npc_color
				body_mesh.set_surface_override_material(0, new_body_mat)

func _ready():
		match_body_to_head_color()

# Set a specific initial pose for variety
func set_initial_pose(pose_index: int):
	if pose_index >= 0 and pose_index < jojo_poses.size():
		current_pose = jojo_poses[pose_index].duplicate()
		target_pose = current_pose.duplicate()
		apply_pose(current_pose)
