extends Node3D

# ===================================
# KONFIGŪRACIJA
# ===================================
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

# ===================================
# MYGTUKŲ ŽYMĖS
# ===================================
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

# ===================================
# KINTAMIEJI
# ===================================
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


# ===================================
# NODES
# ===================================
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


func _ready():
	door_start_y = watched_door.global_position.y
	round_timer.timeout.connect(_on_order_timeout)
	label_container.visible = false
	label_2d.text = "🍔 Laukiama durų..."
	round_timer.visible = false

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

# ===================================
# DURŲ STEBĖJIMAS
# ===================================
func _physics_process(delta):
	# Detect doors opening
	if not door_opened and watched_door.global_position.y > door_start_y + 0.1:
		door_opened = true
		label_2d.text = "🌞 Diena prasideda!"
		_spawn_npc()

	if not current_npc:
		return

	match order_state:
		"moving_to_counter":
			var dir = (counter_point.global_position - current_npc.global_position).normalized()
			var distance = current_npc.global_position.distance_to(counter_point.global_position)
			if distance < 0.1:
				current_npc.global_position = counter_point.global_position  # Snap to counter
				order_state = "order_active"
				_start_order_timer()
			else:
				current_npc.global_position += dir * npc_speed * delta

		"npc_leaving":
			var dir = (exit_point.global_position - current_npc.global_position).normalized()
			var distance = current_npc.global_position.distance_to(exit_point.global_position)
			if distance < 0.1:
				current_npc.queue_free()
				current_npc = null
				order_state = "waiting_for_npc"
				label_2d.text = "🍔 Laukiama užsakymo..."
				label_container.visible = false  # ensure label is hidden
				_spawn_npc()
			else:
				current_npc.global_position += dir * npc_speed * delta


var order_time_left: float = 0.0


func _process(delta):
	if active_order:
		order_time_left -= delta
		if order_time_left < 0:
			order_time_left = 0
		timer_label.text = str(ceil(order_time_left)) + "s"



# ===================================
# SPAWN NPC
# ===================================
func _spawn_npc():
	if not npc_scene:
		push_warning("No NPC scene assigned!")
		return

	current_npc = npc_scene.instantiate()
	get_parent().add_child(current_npc)  # Add as sibling

	# Set position
	current_npc.global_position = npc_spawn_point.global_position
	current_npc.global_position.y += 1.0  # Lift by 1 meter

	# Set scale
	current_npc.scale = Vector3.ONE

	# Rotate to face counter (optional)
	current_npc.rotation_degrees.y = 90

	order_state = "moving_to_counter"



# ===================================
# TIMER START & ORDER
# ===================================
func _start_order_timer():
	if active_order:
		return

	# Only start order when NPC has reached counter
	if order_state != "order_active":
		return

	order_time_left = Global.order_time
	active_order = true
	waiting_for_next = false

	# Show label container for the combination ONLY during active order
	label_container.visible = true

	# Generate a new combination
	new_combination()

	# Update terminal
	label_2d.text = "⏳ Užsakymas vyksta..."

	# Start round timer
	round_timer.visible = true
	round_timer.start(Global.order_time)


# ===================================
# NEW COMBINATION GENERATION
# ===================================
func new_combination(count: int = 3):
	var all_items = button_labels.values()
	all_items.shuffle()
	var combination = all_items.slice(0, count)

	# Update the 3D label
	label_3d.text = "\n".join(combination)
	print("New combination:", combination)

	# Clear previous selection
	selected_items.clear()

	# Do NOT reset active_order here! Otherwise confirm won't work
	waiting_for_next = false

func _on_food_button_pressed(index: int):
	var item = button_labels.get(index, "")
	if item == "":
		return
	selected_items.append(item)
	label_2d.text = "📝 Pasirinkta:\n" + "\n".join(selected_items)

# ===================================
# ORDER COMPLETE
# ===================================
func _on_confirm_pressed():
	if not active_order:
		return

	if selected_items.is_empty():
		label_2d.text = "❌ Nieko nepasirinkta!"
		return

	var correct = Array(label_3d.text.split("\n"))
	var sel = selected_items.duplicate()

	correct.sort()
	sel.sort()

	if sel == correct:
		label_2d.text = "✅ Teisinga!"
		Global.money += 1
		_update_money_label()
		_end_order()
	else:
		label_2d.text = "❌ Neteisinga!"
		selected_items.clear()

	# Either way, end this order
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

# ===================================
# ORDER TIMER END
# ===================================
func _on_order_timeout():
	if not active_order:
		return
	label_2d.text = "⏳ Laikas baigėsi!"
	_end_order()

# ===================================
# END ORDER FUNCTION
# ===================================
func _end_order():
	if not active_order:
		return
	active_order = false
	round_timer.stop()
	round_timer.visible = false
	label_container.visible = false  # hide combination label immediately
	order_state = "npc_leaving"      # NPC leaves after order
	# Clear selected items to avoid lingering selection
	selected_items.clear()
