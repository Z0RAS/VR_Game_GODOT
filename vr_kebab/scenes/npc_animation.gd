extends Node3D

@onready var skeleton: Skeleton3D = $WobblePivot/Skeleton3D

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

	# Kartais iššauti JoJo pozą (pvz. 1 iš 5)
	var use_jojo = false
	if randf() < 0.2 and idle_cooldown <= 0:
		use_jojo = true

	if idle_cooldown <= 0 or current_pose.size() == 0:
		if use_jojo:
			target_pose = jojo_poses[randi() % jojo_poses.size()]
		else:
			target_pose = generate_random_pose()
		idle_cooldown = randf_range(0.1, 0.5)

	# Smooth perejimas
	for key in target_pose.keys():
		if not current_pose.has(key):
			current_pose[key] = target_pose[key]
		else:
			current_pose[key] = lerp(float(current_pose[key]), float(target_pose[key]), delta * pose_lerp_speed)


	apply_pose(current_pose)

var jojo_poses = [
	# 1 – ranka į šoną, kita prie veido, kojos plačiai
	{ "R_ARM": 2.0, "L_ARM": -1.5, "R_LEG": 1.0, "L_LEG": -1.0, "NECK": 0.5, "WOBBLE_X":0.05, "WOBBLE_Y":0, "WOBBLE_Z":15 },
	# 2 – pasilenkęs atgal, rankos į viršų, kojos suglaustos
	{ "R_ARM": 2.5, "L_ARM": 2.5, "R_LEG": 0.0, "L_LEG": 0.0, "NECK": -0.3, "WOBBLE_X":0, "WOBBLE_Y":0, "WOBBLE_Z":-20 },
	# 3 – „Attack on Titan“ dedicate your hearts
	{ "R_ARM": -2.0, "L_ARM": 2.0, "R_LEG": 0.5, "L_LEG": -0.5, "NECK": 0.7, "WOBBLE_X":0.02, "WOBBLE_Y":0.03, "WOBBLE_Z":10 },
	# 4 – crazy dramatic lean, rankos į skirtingas puses
	{ "R_ARM": 1.8, "L_ARM": -2.5, "R_LEG": 0.8, "L_LEG": -0.8, "NECK": 1.0, "WOBBLE_X":0.08, "WOBBLE_Y":0.05, "WOBBLE_Z":25 }
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
	# WobblePivot
	$WobblePivot.position = Vector3(pose.get("WOBBLE_X",0), pose.get("WOBBLE_Y",0), 0)
	$WobblePivot.rotation_degrees = Vector3(0,0,pose.get("WOBBLE_Z",0))

	# Kaulai
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
