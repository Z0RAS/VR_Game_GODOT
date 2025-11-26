extends Node3D

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		await get_tree().process_frame
		spawn_player()
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")

func spawn_player():
	var player_scene = preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	add_child(player)
	player.global_transform.origin = Vector3(-1.4, 1.12, -5)
