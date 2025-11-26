extends Node3D

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")

	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Laukiame kol prasidės XR sesija:
		xr_interface.session_begun.connect(_on_session_begun)

		# Paleidžiame XR
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")


func _on_session_begun():
	print("XR session fully started!")
	spawn_player()


func spawn_player():
	var player_scene = preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()

	add_child(player)

	# Dabar XR jau tikrai inicijuotas → galima naudoti global pozicijas
	player.global_position = Vector3(-1.4, 1.12, -5)
