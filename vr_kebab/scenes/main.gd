extends Node3D

@export var top_cut_zone_path: NodePath
@export var bottom_cut_zone_path: NodePath
@export var meat_drop_zone_path: NodePath
@export var special_meat_scene: PackedScene

var cut_step := 0			# 0 = waiting, 1 = top cut done
var cut_timer: Timer
const CUT_TIMEOUT := 3.0	# seconds

@onready var top_zone: Area3D = get_node(top_cut_zone_path)
@onready var bottom_zone: Area3D = get_node(bottom_cut_zone_path)
@onready var meat_drop_zone: Node3D = get_node(meat_drop_zone_path)

var xr_interface: XRInterface

func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	
	if xr_interface and xr_interface.is_initialized():
		
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		
		get_viewport().use_xr = true
	else:
		push_warning("OpenXR not available")
	
	# Timer setup
	cut_timer = Timer.new()
	cut_timer.wait_time = CUT_TIMEOUT
	cut_timer.one_shot = true
	add_child(cut_timer)
	cut_timer.timeout.connect(_on_cut_timeout)

	# Zone signals
	top_zone.body_entered.connect(_on_top_cut_entered)
	bottom_zone.body_entered.connect(_on_bottom_cut_entered)

	print("Cutting system ready ✔")

# ---------------- CUT DETECTION ---------------- #

func _on_top_cut_entered(body):
	if not body.is_in_group("Knife"):
		return

	# Only allow top as the first cut
	if cut_step != 0:
		return

	cut_step = 1
	cut_timer.start()
	print("🔪 TOP cut detected → waiting for BOTTOM...")

func _on_bottom_cut_entered(body):
	if not body.is_in_group("Knife"):
		return

	# Only valid if top happened first
	if cut_step == 1:
		print("✅ BOTTOM cut detected → Combo complete!")
		_spawn_special_meat()
		cut_step = 0
		cut_timer.stop()
	else:
		print("❌ Bottom cut ignored (top was not cut first).")

func _on_cut_timeout():
	print("⏳ Cut combo expired.")
	cut_step = 0

# ---------------- SPAWNING ---------------- #

func _spawn_special_meat():
	if not special_meat_scene:
		push_warning("Special meat scene missing!")
		return

	var meat := special_meat_scene.instantiate()
	get_parent().add_child(meat)

	# Use BOTH position AND rotation of the drop zone
	meat.global_transform = meat_drop_zone.global_transform

	print("🥩 Special meat spawned at drop zone!")
