# LoadingScreen.gd
extends Node3D  # root Node3D

@onready var loading_label: Label3D = $XRCamera3D/Label3D

var game_scene_path := "res://scenes/main.tscn"
var player_scene_path := "res://scenes/player.tscn"

var loading_dots := 0
var loading_running := true

func _ready() -> void:
	# Parent this loading screen under XROrigin3D so it's always visible
	var xr_origin = get_tree().get_root().get_node_or_null("XROrigin3D")
	if xr_origin:
		xr_origin.add_child(self)
		global_transform.origin = Vector3(0, 0, -2)  # 2 meters in front of headset
	else:
		# fallback in world space if XROrigin not found
		global_transform.origin = Vector3(0, 1.5, -2)

	# Scale label for VR readability
	loading_label.scale = Vector3(0.5, 0.5, 0.5)
	set_message("Initializing VR...")

	await start_vr_and_load_game()


func start_vr_and_load_game() -> void:
	var xr = XRServer.find_interface("OpenXR")

	if xr and xr.is_initialized():
		get_viewport().use_xr = true
		await xr.session_begun
		# Wait a few frames for tracking and swapchain to settle
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
	else:
		push_warning("OpenXR not initialized — continuing without VR")
		set_message("VR not detected. Continuing...")

	# Start animated loading text
	loading_running = true
	animate_loading_text("Loading")

	# Wait 10 seconds while showing animated text
	await get_tree().create_timer(5.0).timeout
	loading_running = false

	# Load the game scene
	set_message("Loading game scene...")
	
	# Debug: Check if file exists first
	print("Checking for game scene at: ", game_scene_path)
	if not ResourceLoader.exists(game_scene_path):
		push_error("Game scene file does not exist at: " + game_scene_path)
		set_message("Scene file not found: " + game_scene_path)
		return
	
	var packed_scene: PackedScene = load(game_scene_path) as PackedScene
	
	# Debug: print the result
	if not packed_scene:
		push_error("Failed to load Game scene from: " + game_scene_path)
		set_message("Failed to load game scene!")
		return
	
	print("Successfully loaded game scene")
	var game_scene: Node3D = packed_scene.instantiate() as Node3D
	get_tree().get_root().add_child(game_scene)
	get_tree().set_current_scene(game_scene)

	# Wait a couple frames for _ready() calls
	await get_tree().process_frame
	await get_tree().process_frame

	# Spawn player
	set_message("Spawning player...")
	await spawn_player(game_scene)

	# Hide the loading screen
	visible = false


func spawn_player(game_root: Node3D) -> void:
	var player_scene = load(player_scene_path) as PackedScene
	if not player_scene:
		push_error("Failed to load Player scene from: " + player_scene_path)
		return
	
	var player := player_scene.instantiate() as XROrigin3D
	game_root.add_child(player)

	var spawn := game_root.get_node_or_null("PlayerSpawn")
	if not spawn:
		return

	await get_tree().process_frame
	await get_tree().process_frame

	# perkeliam tracking space, ne node transformą
	player.set_global_position(spawn.global_position)



func set_message(msg: String) -> void:
	if loading_label:
		loading_label.text = msg


func animate_loading_text(base_text: String = "Loading") -> void:
	while loading_running:
		loading_dots = (loading_dots + 1) % 4
		var dots: String = ".".repeat(loading_dots)
		set_message(base_text + dots)
		await get_tree().create_timer(0.5).timeout
