extends Node3D

@export var button_paths: Array[NodePath]
@export var confirm_button_path: NodePath
@export var delete_button_path: NodePath
@export var label_3d_path: NodePath
@export var terminal_viewport_path: NodePath
@export var money_label_path: NodePath
@export var mesh_to_hide_path: NodePath
@export var timer_path: NodePath              # RoundTimer node
@export var watched_door_path: NodePath       # Node3D durys
@export var npc_spawn_point_path: NodePath    # Where NPCs appear
@export var counter_point_path: NodePath      # Where NPCs walk to
@export var npc_scene: PackedScene            # NPC scene to spawn
@export var cooldown_time: int = 10
@export var exit_point_path: NodePath   # NPC exit point
@export var timer_label_path: NodePath
@export var corner_entry_point_path: NodePath   # Waypoint after spawn before counter
@export var corner_exit_point_path: NodePath    # Waypoint before exit
@export var product_scenes: Array[PackedScene]       # one per button
@export var product_spawn_points: Array[NodePath]   # one per button


var button_labels := {
	0: "🐄 Mėsa 1",
	1: "🐖 Mėsa 2",
	2: "🐓 Mėsa 3",
	3: "🥔 Bulvės 1",
	4: "🍟 Bulvės 2",
	5: "🍠 Bulvės 3",
	6: "🧂 Padažas 1",
	7: "🍅 Padažas 2",
	8: "🧄 Padažas 3"
}
var selected_items: Array = []
var active_order := false
var waiting_for_next := false
var door_opened := false
var npc_at_counter := false
var door_start_y := 0.0
var current_npc: Node3D = null
var npc_speed := 2.5
var npc_leaving := false
var order_state := "waiting_for_npc"
var order_time_left: float = 0.0
var wobble_amplitude_side = 0.3
var wobble_amplitude_up = 0.15
var wobble_speed = 6.0
var wobble_time = 0.0
var wobble_recover_speed = 5.0  # higher = faster recovery
var SPECIAL_MEAT = "🥩 Special Meat"


@onready var label_3d: Label3D = get_node(label_3d_path)
@onready var terminal_viewport: SubViewport = get_node(terminal_viewport_path)
@onready var label_2d: Label = terminal_viewport.get_node("Control/Label")
@onready var confirm_button = get_node(confirm_button_path)
@onready var delete_button = get_node(delete_button_path)
@onready var money_label: Label = get_node(money_label_path)
@onready var mesh_to_hide: MeshInstance3D = get_node(mesh_to_hide_path)
@onready var round_timer = get_node(timer_path)
@onready var watched_door: Node3D = get_node(watched_door_path)
@onready var npc_spawn_point: Node3D = get_node(npc_spawn_point_path)
@onready var counter_point: Node3D = get_node(counter_point_path)
@onready var label_container: Node3D = get_node(label_3d_path).get_parent()  # Node3D holding the Label3D
@onready var exit_point: Node3D = get_node(exit_point_path)
@onready var timer_label: Label = get_node(timer_label_path).get_node("TextureProgressBar/Label") as Label
@onready var corner_entry_point: Node3D = get_node(corner_entry_point_path)
@onready var corner_exit_point: Node3D = get_node(corner_exit_point_path)

func _ready():
	door_start_y = watched_door.global_position.y
	round_timer.timeout.connect(_on_order_timeout)
	label_container.visible = false
	label_2d.text = "🍔 Laukiama durų..."
	round_timer.visible = false
	Global.money_changed.connect(_update_money_label)

	for i in range(button_paths.size()):
		var holder = get_node(button_paths[i])
		var btn = holder as XRToolsInteractableAreaButton
		if not btn:
			push_warning("Button %s neranda InteractableAreaButton child!" % holder.name)
			continue
		btn.button_pressed.connect(_on_food_button_pressed.bind(i))
	if confirm_button:
		confirm_button.button_pressed.connect(_on_confirm_pressed)
	if delete_button:
		delete_button.button_pressed.connect(_on_delete_pressed)
	_update_money_label()

func _physics_process(delta):
	# Detect doors opening
	if not door_opened and watched_door.global_position.y > door_start_y + 0.1:
		door_opened = true
		label_2d.text = "🌞 Diena prasideda!"
		_spawn_npc()
	if not current_npc:
		return
	# Get the pivot if exists
	var pivot: Node3D = null
	if current_npc.has_node("WobblePivot"):
		pivot = current_npc.get_node("WobblePivot")
	match order_state:
		"moving_to_corner_entry":
			_move_npc_to_point(corner_entry_point.global_position, "moving_to_counter", pivot, delta)
		"moving_to_counter":
			_move_npc_to_point(counter_point.global_position, "order_active", pivot, delta)
		"order_active":
			# NPC stands upright at counter
			if pivot:
				pivot.position = Vector3.ZERO
				pivot.rotation_degrees = Vector3.ZERO
		"moving_to_corner_exit":
			_move_npc_to_point(corner_exit_point.global_position, "npc_leaving", pivot, delta)
		"npc_leaving":
			_move_npc_to_point(exit_point.global_position, "waiting_for_npc", pivot, delta, true)

func _move_npc_to_point(target: Vector3, next_state: String, pivot: Node3D, delta: float, queue_free_after: bool=false):
	if not current_npc:
		return
	var dir = (target - current_npc.global_position).normalized()
	var distance = current_npc.global_position.distance_to(target)
	if distance < 0.1:
		# Snap to target
		current_npc.global_position = target
		order_state = next_state
		# Reset pivot immediately when reaching counter
		if next_state == "order_active" and pivot:
			pivot.position = Vector3.ZERO
			pivot.rotation_degrees = Vector3.ZERO
			_start_order_timer()
		if queue_free_after:
			current_npc.rotation_degrees = Vector3.ZERO
			current_npc.queue_free()
			current_npc = null
			label_2d.text = "🍔 Laukiama užsakymo..."
			label_container.visible = false
			_spawn_npc()
		match target:
			corner_entry_point.global_position:
				current_npc.global_rotation_degrees = Vector3(0, -90, 0)
			corner_exit_point.global_position:
				current_npc.global_rotation_degrees = Vector3(0, 0, 0)
			exit_point.global_position:
				current_npc.global_rotation_degrees = Vector3(0, 0, 0)


	else:
		current_npc.global_position += dir * npc_speed * delta
		if pivot:
			wobble_time += delta * wobble_speed
			var offset_x = sin(wobble_time) * wobble_amplitude_side
			var offset_y = abs(sin(wobble_time * 2)) * wobble_amplitude_up
			var tilt = sin(wobble_time) * 10
			pivot.position = Vector3(offset_x, offset_y, 0)
			pivot.rotation_degrees = Vector3(0, 0, tilt)

func _process(delta):
	if active_order:
		order_time_left -= delta
		if order_time_left < 0:
			order_time_left = 0
		timer_label.text = str(ceil(order_time_left)) + "s"

func _spawn_npc():
	if not npc_scene:
		push_warning("No NPC scene assigned!")
		return
	current_npc = npc_scene.instantiate()
	get_parent().add_child(current_npc)  # Add as sibling
	current_npc.global_position = npc_spawn_point.global_position
	current_npc.global_rotation_degrees = Vector3(0, 0, 0)
	order_state = "moving_to_corner_entry"

func _start_order_timer():
	if active_order:
		return
	if order_state != "order_active":
		return
	order_time_left = Global.order_time
	active_order = true
	waiting_for_next = false
	label_container.visible = true
	new_combination()
	label_2d.text = "⏳ Užsakymas vyksta..."
	round_timer.visible = true
	round_timer.start(Global.order_time)

func new_combination(count: int = 3):
	var all_items = button_labels.values()
	all_items.shuffle()
	var combination = all_items.slice(0, count)
	var include_special_meat = randi() % 2 == 0
	if include_special_meat:
		combination.append(SPECIAL_MEAT)
	label_3d.text = "\n".join(combination)
	print("New combination:", combination)
	
	selected_items.clear()
	waiting_for_next = false

func _on_food_button_pressed(index: int):
	var item = button_labels.get(index, "")
	if item == "":
		return
	selected_items.append(item)
	label_2d.text = "📝 Pasirinkta:\n" + "\n".join(selected_items)
	if index < product_scenes.size() and index < product_spawn_points.size():
		var scene = product_scenes[index]
		var spawn_point = get_node(product_spawn_points[index])
		if scene and spawn_point:
			var instance = scene.instantiate()
			get_parent().add_child(instance)
			instance.global_position = spawn_point.global_position

func _on_confirm_pressed():
	if not active_order:
		return
	if selected_items.is_empty():
		label_2d.text = "❌ Nieko nepasirinkta!"
		return
	var correct = Array(label_3d.text.split("\n"))
	correct.erase(SPECIAL_MEAT)
	var sel = selected_items.duplicate()
	correct.sort()
	sel.sort()
	if sel == correct:
		label_2d.text = "✅ Teisingas užsakymas!"
		Global.money += 1
		_end_order()
	else:
		label_2d.text = "❌ Neteisingas užsakymas!"
		selected_items.clear()
	_end_order()

func _on_delete_pressed():
	if selected_items.is_empty():
		label_2d.text = "🗑️ Nėra ką trinti."
		return
	selected_items.pop_back()
	if selected_items.is_empty():
		label_2d.text = "🗑️ Išvalyta."
	else:
		label_2d.text = "📝 Pasirinkta:\n" + "\n".join(selected_items)

func _update_money_label():
	money_label.text = "💰 " + str(Global.money) + " €"

func _on_order_timeout():
	if not active_order:
		return
	label_2d.text = "⏳ Laikas baigėsi!"
	_end_order()

func _end_order():
	if not active_order:
		return
	active_order = false
	round_timer.stop()
	round_timer.visible = false
	label_container.visible = false  # hide combination label immediately
	order_state = "moving_to_corner_exit"      # NPC leaves after order
	selected_items.clear()
	if current_npc:
		current_npc.rotation_degrees.y += 180
