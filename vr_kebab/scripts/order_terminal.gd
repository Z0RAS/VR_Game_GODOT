extends Node3D

@export var upgrade_visuals: Array[NodePath] = [] # Set in inspector: nodes to unhide for upgrades

func show_upgrade_visuals(upgrade_count: int):
	for i in range(upgrade_visuals.size()):
		var node = get_node_or_null(upgrade_visuals[i])
		if node:
			node.visible = i < upgrade_count

@export var button_paths: Array[NodePath]
@export var confirm_button_path: NodePath
@export var delete_button_path: NodePath
@export var speechBubbleOrderLabel: NodePath
@export var terminal_viewport_path: NodePath
@export var money_label_path: NodePath
@export var timer_path: NodePath # RoundTimer node
@export var watched_door_path: NodePath # Node3D durys
@export var npc_spawn_point_path: NodePath # Where NPCs appear
@export var counter_point_path: NodePath # Where NPCs walk to
@export var npc_scene: PackedScene # NPC scene to spawn
@export var cooldown_time: int = 10
@export var exit_point_path: NodePath # NPC exit point
@export var timer_label_path: NodePath
@export var corner_entry_point_path: NodePath # Waypoint after spawn before counter
@export var corner_exit_point_path: NodePath # Waypoint before exit
@export var product_scenes: Array[PackedScene] # one per button
@export var product_spawn_points: Array[NodePath] # one per button
@export var order_zone_root: Node3D
@export var product_costs: Array = [5,5,5,3,3,3,1,1,1] # atitinka ITEMS indeksus
@export var radio_player: AudioStreamPlayer3D
@export var radio_tracks: Array[AudioStream] = [] #Žaidimo garsai
@export var door_open_sfx: AudioStream
@export var button_sfx: AudioStream
@export var confirm_correct_sfx: AudioStream
@export var confirm_wrong_sfx: AudioStream
@export var npc_greet_sfx: AudioStream
@export var item_added_sfx: AudioStream
@export var qouta_reached_sfx: AudioStream
@export var pipe_sfx: AudioStream  # Sound for item spawn

var product_discount := 1.0 # 1.0 = full price, 0.5 = pusė kainos (upgrade)
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
var wobble_recover_speed = 5.0 # higher = faster recovery
var order_confirmed_correct: bool = false
var original_order: Array = []
var remaining_order: Array = []
var placed_items: Array = []
var order_zone_active := false
var base_npc_speed =8.0 # pradinis greitis
var last_radio_index := -1
var sfx_player: AudioStreamPlayer3D = null
var npc_queue: Array = [] # Array to hold NPCs waiting in queue
var queue_line_positions: Array[Vector3] = [] # Positions for NPCs waiting at counter
var npc_queue_spacing := 1.0 # Distance between NPCs in line at counter
var queue_spawn_cooldown := 4.0 # Time between spawning queue NPCs (1-5 seconds)
var time_since_last_spawn := 0.0

@onready var label_3d: Label3D = get_node(speechBubbleOrderLabel)
@onready var terminal_viewport: SubViewport = get_node(terminal_viewport_path)
@onready var label_2d: Label = terminal_viewport.get_node("Control/InfoLabel")
@onready var timeLabel_2d: Label = terminal_viewport.get_node("Control/TimeLabel")
@onready var confirm_button = get_node(confirm_button_path)
@onready var delete_button = get_node(delete_button_path)
@onready var money_label: Label = get_node(money_label_path)
@onready var round_timer = get_node(timer_path)
@onready var watched_door: Node3D = get_node(watched_door_path)
@onready var npc_spawn_point: Node3D = get_node(npc_spawn_point_path)
@onready var counter_point: Node3D = get_node(counter_point_path)
@onready var order_zone_area: Area3D = order_zone_root.get_node("Area3D")
@onready var label_container: Node3D = get_node(speechBubbleOrderLabel).get_parent() # Node3D holding the Label3D
@onready var exit_point: Node3D = get_node(exit_point_path)
@onready var timer_label: Label = get_node(timer_label_path).get_node("TextureProgressBar/Label") as Label
@onready var corner_entry_point: Node3D = get_node(corner_entry_point_path)
@onready var corner_exit_point: Node3D = get_node(corner_exit_point_path)
@onready var day_timer: Timer = get_node("day_timer")
@onready var particle_manager: Node3D = get_node("../ParticleManager") if has_node("../ParticleManager") else null

const ITEMS := {
	0: { "label": "🐄 Mėsa 1", "tag": "Mesa1" },
	1: { "label": "🐖 Mėsa 2", "tag": "Mesa2" },
	2: { "label": "🐓 Mėsa 3", "tag": "Mesa3" },
	3: { "label": "🥔 Bulvės 1", "tag": "Bulves1" },
	4: { "label": "🍟 Bulvės 2", "tag": "Bulves2" },
	5: { "label": "🍠 Bulvės 3", "tag": "Bulves3" },
	6: { "label": "🧂 Padažas 1","tag": "Padazas1" },
	7: { "label": "🍅 Padažas 2","tag": "Padazas2" },
	8: { "label": "🧄 Padažas 3","tag": "Padazas3" },
}

const SPECIAL_MEAT := { "label": "🥩 Speciali", "tag": "SpecialMeat" }

# Dienų nustatymai
const DAYS := [
	{"name": "D1", "combo_count": 1, "special_chance": 0.2, "quota": 100},
	{"name": "D2", "combo_count": 2, "special_chance": 0.3, "quota": 130},
	{"name": "D3", "combo_count": 3, "special_chance": 0.5, "quota": 169},
	{"name": "D4", "combo_count": 3, "special_chance": 0.8, "quota": 219},
	{"name": "D5", "combo_count": 3, "special_chance": 1.0, "quota": 285}
]

var current_day := 0
var day_score := 0
var game_time := 10 * 60 # 10 min in seconds
var day_active := false
var day_start_hour := 9 # dienos pradžia 09:00
var day_end_hour := 17 # dienos pabaiga 17:00
var total_day_seconds := 8 * 60 * 60 # 8 valandos = 28800 s
var door_opened_sfx_played := false
var day_end_pending := false
var day_end_success := false

func _ready():
	# Nustatome durų padėtį ir kitus pradžios parametrus
	door_start_y = watched_door.global_position.y
	round_timer.timeout.connect(_on_order_timeout)
	label_container.visible = false
	label_2d.text = "🍔 Laukiama durų..."
	round_timer.visible = false
	_play_random_radio()
	
	# Inicializuojam pinigus
	Global.money = 50
	Global.money_changed.connect(_update_money_label)
	_update_money_label()
	
	if order_zone_area:
		order_zone_area.body_entered.connect(_on_order_zone_body_entered)
		order_zone_area.monitoring = false
	
	set_meta("tag", "Mesa1")
	
	# Mygtukų jungimas
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

func _physics_process(delta):
	if not day_active and !day_end_pending and watched_door.global_position.y > door_start_y + 0.1:
		_start_day()
	
	# Day end animation (only doors)
	if day_end_pending:
		if watched_door.global_position.y > door_start_y:
			watched_door.global_position.y = max(
				watched_door.global_position.y - 0.05, door_start_y
			)
		else:
			_finalize_day_end()
		return
	
	if not day_active:
		return
	
	# Day timer
	game_time -= delta
	if game_time <= 0:
		var success: bool = current_day < DAYS.size() and day_score >= DAYS[current_day].quota
		_end_day(success)
		return
	
	# Spawn new NPCs in queue if day is active
	time_since_last_spawn += delta
	if time_since_last_spawn >= queue_spawn_cooldown:
		time_since_last_spawn = 0.0
		_try_spawn_queue_npc()

	# Ambient NPCs for environment
	ambient_npc_timer += delta
	if ambient_npc_timer >= ambient_npc_interval and ambient_npcs.size() < max_ambient_npcs:
		ambient_npc_timer = 0.0
		_spawn_ambient_npc()

	# Update ambient NPCs movement
	for ambient in ambient_npcs.duplicate():
		if ambient.npc:
			var dir = (exit_point.global_position - npc_spawn_point.global_position).normalized()
			if ambient.npc is RigidBody3D:
				ambient.npc.linear_velocity = dir * npc_speed * 0.7
			else:
				ambient.npc.global_position += dir * npc_speed * delta * 0.7 # slower than queue NPCs
			# Remove if reached exit
			if ambient.npc.global_position.distance_to(exit_point.global_position) < 0.2:
				ambient.npc.queue_free()
				ambient_npcs.erase(ambient)

	# Update queue positions
	_update_queue_positions(delta)
	
	# Check if front queue NPC should become the main NPC at counter
	if npc_queue.size() > 0 and current_npc == null and order_state == "waiting_for_npc":
		var queue_data = npc_queue.pop_front()
		var front_npc = queue_data.npc
		
		# Recalculate queue positions for remaining NPCs
		for i in range(npc_queue.size()):
			npc_queue[i].index = i
		
		# Clear order state for new customer
		selected_items.clear()
		placed_items.clear()
		order_confirmed_correct = false
		order_zone_active = false
		order_zone_area.set_deferred("monitoring", false)
		
		# Transition front NPC from queue to counter
		current_npc = front_npc
		current_npc.global_position = counter_point.global_position
		# Always face forward at counter
		current_npc.global_rotation_degrees = Vector3(0, 180, 0)
		order_state = "order_active"
		
		# Stop the wobbling/animations when at counter
		
		_start_order_timer()
		print("NPC moved from queue to counter")
		return  # Exit early to prevent processing the NPC movement in the same frame
	
	# No NPC at counter → nothing to move
	if current_npc == null:
		return
	
	# Normal NPC movement at counter
	
	match order_state:
		"moving_to_corner_entry":
			_move_npc_to_point(corner_entry_point.global_position, "moving_to_counter", delta)
		"moving_to_counter":
			_move_npc_to_point(counter_point.global_position, "order_active", delta)
		"order_active":
			pass
		"moving_to_corner_exit":
			_move_npc_to_point(corner_exit_point.global_position, "npc_leaving", delta)
		"npc_leaving":
			_move_npc_to_point(exit_point.global_position, "waiting_for_npc", delta, true)

func _finalize_day_end():
	day_end_pending = false
	current_day += 1
	day_score = 0
	selected_items.clear()
	placed_items.clear()
	original_order.clear()
	remaining_order.clear()
	label_container.visible = false
	round_timer.stop()
	round_timer.visible = false
	timeLabel_2d.text = "%s %02d:%02d" % [ ["Pr","An","Tr","Kt","Pn","Št","Sk"][current_day % 7], day_start_hour, 0 ]
	# Paliekam DURIS UŽDARYTAS – žaidėjas pats atidarys

func _start_day():
	if day_active:
		return
	
	# Resetinam order progress
	selected_items.clear()
	placed_items.clear()
	original_order.clear()
	remaining_order.clear()
	order_confirmed_correct = false
	active_order = false
	waiting_for_next = false
	round_timer.stop()
	round_timer.visible = false
	day_score = 0
	
	# Clear queue
	for queue_data in npc_queue:
		if queue_data and queue_data.npc:
			queue_data.npc.queue_free()
	npc_queue.clear()
	if current_npc:
		current_npc.queue_free()
		current_npc = null
	
	if current_day >= DAYS.size():
		label_2d.text = "🎉 Žaidimas baigtas!"
		day_active = false
		return
	
	var day_info = DAYS[current_day]
	
	# Nustatome pradinį laiką
	var hour = day_start_hour
	var minute = 0
	var day_names := ["Pr", "An", "Tr", "Kt", "Pn", "Št", "Sk"]
	var day_label = day_names[current_day % day_names.size()]
	# Rodom tik laiką + savaitės dieną
	timeLabel_2d.text = "%s %02d:%02d" % [day_label, hour, minute]
	
	# Pagrindinė info
	day_score = 0
	day_active = true
	door_opened = true
	order_zone_active = false
	selected_items.clear()
	placed_items.clear()
	_end_order()
	
	# Initialize queue positions (5 positions behind spawn point)
	_init_queue_positions()
	
	Global.current_combo_count = day_info.combo_count
	Global.current_special_chance = day_info.special_chance
	Global.current_day_quota = day_info.quota
	npc_speed = base_npc_speed + current_day * 0.5
	_spawn_npc()
	# Start at 0 so the first queue NPC spawns after the full cooldown delay
	time_since_last_spawn = 0.0
	_update_money_label()
	
	# dienos laikmatis
	game_time = total_day_seconds
	if day_timer:
		day_timer.wait_time = 1.0
		day_timer.one_shot = false
		day_timer.start()
		if not day_timer.timeout.is_connected(_on_day_timer_tick):
			day_timer.timeout.connect(_on_day_timer_tick)

var passive_income_counter := 0
# Ambient NPCs for environment
var ambient_npc_timer := 0.0
var ambient_npc_interval := 8.0 # seconds between ambient NPC spawns
var ambient_npcs: Array = []
var max_ambient_npcs := 3

func _on_day_timer_tick():
	if game_time <= 0:
		day_timer.stop()
		_end_day(day_score >= DAYS[current_day].quota)
		return
	
	game_time -= 1
	passive_income_counter += 1
	if passive_income_counter >= 10:
		passive_income_counter = 0
		Global.money += 1
		_update_money_label()
	
	# Laiko skaičiavimas
	var elapsed_seconds = total_day_seconds - game_time
	var hour = day_start_hour + int(elapsed_seconds / 3600)
	var minute = int((elapsed_seconds % 3600) / 60)
	var day_names := ["Pr", "An", "Tr", "Kt", "Pn", "Št", "Sk"]
	var day_label = day_names[current_day % day_names.size()]
	# Tik laiką + savaitės dieną
	timeLabel_2d.text = "%s %02d:%02d" % [day_label, hour, minute]
	
	# Lėtai nuleisti duris likus 5 s
	if game_time <= 5 and watched_door.global_position.y > door_start_y - 0.5:
		var step := 0.05
		watched_door.global_position.y -= step

#domis was here
func _end_day(success: bool):
	if day_end_pending:
		return
	day_end_pending = true
	day_active = false
	door_opened = false
	
	# Sustabdom dienos laiką
	game_time = 0
	
	# Ištrinam NPC iš karto ir visą eilę
	if current_npc:
		current_npc.queue_free()
		current_npc = null
	
	for queue_data in npc_queue:
		if queue_data and queue_data.npc:
			queue_data.npc.queue_free()
	npc_queue.clear()
	
	if success:
		label_2d.text = "✅ " + DAYS[current_day].name + " pavyko!"
	else:
		label_2d.text = "💀 Bankrotas!"
	
	_end_order()

func _move_npc_to_point(target: Vector3, next_state: String, delta: float, queue_free_after: bool=false):
		if not current_npc:
			return
		# Only use X and Z from target, do not set Y (let gravity/physics handle Y)
		var move_target = Vector3(target.x, current_npc.global_position.y, target.z)
		var dir = (move_target - current_npc.global_position)
		dir.y = 0 # Ignore Y for movement direction
		if dir.length() > 0:
			dir = dir.normalized()
		var distance = current_npc.global_position.distance_to(move_target)
		if distance < 0.1:
			current_npc.is_walking = false
			# Only set X and Z, leave Y unchanged
			current_npc.global_position.x = move_target.x
			current_npc.global_position.z = move_target.z
			if current_npc is RigidBody3D:
				current_npc.linear_velocity.x = 0
				current_npc.linear_velocity.z = 0
			# If NPC is arriving at the counter, start the order
			if next_state == "order_active":
				order_state = "order_active"
				# Do NOT forcibly set rotation here; keep the direction NPC was facing
				AudioManager.play_sfx(npc_greet_sfx)
				_start_order_timer()
			else:
				order_state = next_state
			if queue_free_after:
				current_npc.rotation_degrees = Vector3.ZERO
				current_npc.queue_free()
				current_npc = null
				label_2d.text = "🍔 Laukiama užsakymo..."
				label_container.visible = false
				order_state = "waiting_for_npc"
			else:
				match target:
					corner_entry_point.global_position:
						current_npc.global_rotation_degrees = Vector3(0, -90, 0)
					corner_exit_point.global_position:
						current_npc.global_rotation_degrees = Vector3(0, 0, 0)
					exit_point.global_position:
						current_npc.global_rotation_degrees = Vector3(0, 0, 0)
		else:
			current_npc.is_walking = true
			if current_npc is RigidBody3D:
				current_npc.linear_velocity = dir * npc_speed
			else:
				current_npc.global_position += dir * npc_speed * delta
			if order_state in ["moving_to_corner_entry", "moving_to_counter"] and not active_order:
				label_2d.text = "🍔 Laukiama užsakymo…"

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
	# Only spawn if no current NPC (they go to counter immediately)
	if current_npc == null:
		current_npc = npc_scene.instantiate()
		get_parent().add_child(current_npc)
		current_npc.global_position = npc_spawn_point.global_position
		current_npc.global_rotation_degrees = Vector3(0, 0, 0)
		current_npc.set_meta("queue_index", -1) # -1 means main NPC
		# Assign random color to counter NPC
		if current_npc.has_method("match_body_to_head_color"):
			current_npc.call("match_body_to_head_color")
		order_state = "moving_to_corner_entry"
		active_order = false # Ensure order can start
		# Let movement logic handle walking to counter and starting order
		print("First NPC spawned at spawn point and will walk to counter")

func _try_spawn_queue_npc():
	# Spawn NPCs into the queue that will walk the same path as the first NPC
	if not day_active or not npc_scene:
		return
	
	# Spawn new queue NPC if queue isn't too long (max 5 in queue)
	if npc_queue.size() < 5:
		var queue_npc = npc_scene.instantiate()
		get_parent().add_child(queue_npc)
		var queue_index = npc_queue.size()
		# All queue NPCs start at spawn point and walk the same path
		var spawn_pos = npc_spawn_point.global_position
		queue_npc.global_position = Vector3(spawn_pos.x, spawn_pos.y, spawn_pos.z)
		queue_npc.global_rotation_degrees = Vector3(0, 0, 0)
		queue_npc.set_meta("queue_index", queue_index)
		queue_npc.is_walking = false
		# Assign random color to queue NPC
		if queue_npc.has_method("match_body_to_head_color"):
			queue_npc.call("match_body_to_head_color")

		# Give each NPC a very different starting cooldown so they don't sync up
		queue_npc.idle_cooldown = randf_range(0.5, 4.0) + (queue_index * 0.8)  # Stagger by index
		queue_npc.idle_time = randf() * TAU  # Random starting idle time

		# Force each NPC to start with a specific different pose from the array
		# This ensures they all have different poses immediately
		if queue_npc.has_method("set_initial_pose"):
			# Use modulo to cycle through poses if we have more NPCs than poses
			var pose_index = (queue_index + randi()) % 15  # 15 is the number of jojo_poses
			queue_npc.call("set_initial_pose", pose_index)
		
		# Randomize wobble timing for each NPC
		var random_wobble_offset = randf() * TAU  # Random offset between 0 and 2*PI
		queue_npc.set_meta("wobble_offset", random_wobble_offset)
		
		# Queue NPCs start in "moving_to_corner_entry" state
		npc_queue.append({
			"npc": queue_npc,
			"state": "moving_to_corner_entry",
			"index": queue_index,
			"wobble_time": random_wobble_offset  # Each NPC has its own wobble timer
		})
		print("Spawned queue NPC #", queue_index)

func _init_queue_positions():
	# Initialize positions at counter_point where NPCs line up
	# Each NPC waits at a position behind the one in front
	queue_line_positions.clear()
	var base_pos = counter_point.global_position
	print("Counter point position: ", base_pos)
	
	# Create a line extending backwards from counter in the direction from corner_entry
	# Calculate direction from corner_entry to counter
	var direction = (counter_point.global_position - corner_entry_point.global_position).normalized()
	var backward_direction = -direction
	
	for i in range(1, 6):
		# Position each NPC behind the previous one
		var pos = base_pos + backward_direction * i * npc_queue_spacing
		queue_line_positions.append(pos)
	print("Queue line positions: ", queue_line_positions)

func _update_queue_positions(delta: float):
	# Move queue NPCs through the same path as the main NPC
	# They walk: spawn → corner_entry → counter → stop and wait in line
	# Check if front queue NPC should become the main NPC at counter
	if npc_queue.size() > 0 and current_npc == null and order_state == "waiting_for_npc":
		var queue_data = npc_queue.pop_front()
		var front_npc = queue_data.npc
		# Recalculate queue positions for remaining NPCs
		for j in range(npc_queue.size()):
			npc_queue[j].index = j
		# Clear order state for new customer
		selected_items.clear()
		placed_items.clear()
		order_confirmed_correct = false
		order_zone_active = false
		order_zone_area.set_deferred("monitoring", false)
		# Transition front NPC from queue to counter
		current_npc = front_npc
		# Let movement logic handle walking to counter
		order_state = "moving_to_counter"
		active_order = false # Ensure order can start
		print("Queue NPC promoted to main NPC, will walk to counter")
		return  # Exit early to prevent processing the NPC movement in the same frame

	# Move queue NPCs through the same path as the main NPC
	# They walk: spawn → corner_entry → counter → stop and wait in line
	for i in range(npc_queue.size()):
		var queue_data = npc_queue[i]
		var npc = queue_data.npc
		var state = queue_data.state
		if not npc:
			continue
		# Unify movement logic: all NPCs (ambient, queue, counter) use the same directional walk
		match state:
			"moving_to_corner_entry":
				var ground_target = Vector3(corner_entry_point.global_position.x, npc.global_position.y, corner_entry_point.global_position.z)
				var dir = (ground_target - npc.global_position).normalized()
				var dist = npc.global_position.distance_to(ground_target)
				if npc is RigidBody3D:
					if dist > 0.05:
						npc.linear_velocity = dir * npc_speed
					else:
						npc.linear_velocity = Vector3.ZERO
						npc.global_position = ground_target
						npc.global_rotation_degrees = Vector3(0, -90, 0)
						queue_data.state = "moving_to_counter"
						print("Queue NPC reached corner entry: ", npc.name)
				else:
					if dist > 0.05:
						npc.global_position += dir * npc_speed * delta
					else:
						npc.global_position = ground_target
						npc.global_rotation_degrees = Vector3(0, -90, 0)
						queue_data.state = "moving_to_counter"
						print("Queue NPC reached corner entry: ", npc.name)
				npc.is_walking = true
			"moving_to_counter":
				var target_queue_pos = queue_line_positions[i] if i < queue_line_positions.size() else counter_point.global_position
				var ground_target = Vector3(target_queue_pos.x, npc.global_position.y, target_queue_pos.z)
				var dir = (ground_target - npc.global_position).normalized()
				var dist = npc.global_position.distance_to(ground_target)
				if npc is RigidBody3D:
					if dist > 0.05:
						npc.linear_velocity = dir * npc_speed
					else:
						npc.linear_velocity = Vector3.ZERO
						npc.global_position = ground_target
						npc.is_walking = false
						queue_data.state = "waiting_in_queue"
						print("Queue NPC reached queue position: ", npc.name)
				else:
					if dist > 0.05:
						npc.global_position += dir * npc_speed * delta
					else:
						npc.global_position = ground_target
						npc.is_walking = false
						queue_data.state = "waiting_in_queue"
						print("Queue NPC reached queue position: ", npc.name)
				npc.is_walking = dist > 0.05

func _start_order_timer():
	print("_start_order_timer called, order_state:", order_state, " active_order:", active_order)
	if active_order:
		return
	if order_state != "order_active":
		return
	order_time_left = Global.order_time
	active_order = true
	waiting_for_next = false
	label_container.visible = true
	original_order = new_combination()
	# remaining_order neturi SPECIAL_MEAT
	remaining_order = original_order.filter(func(i): return i != SPECIAL_MEAT)
	placed_items.clear()
	label_2d.text = "⏳ Užsakymas vyksta..."
	round_timer.visible = true
	round_timer.start(Global.order_time)

func new_combination() -> Array:
	# Generuojam dienos combo pagal Global.current_combo_count
	var all_items = ITEMS.values()
	all_items.shuffle()
	var combination := all_items.slice(0, Global.current_combo_count)
	# Special meat tikimybė pagal Global.current_special_chance
	if randf() <= Global.current_special_chance:
		combination.append(SPECIAL_MEAT)
	# Rodom label 3D terminale
	label_3d.text = "\n".join(combination.map(func(i): return i.label))
	# Išvalom selected_items prieš naują kombinaciją
	selected_items.clear()
	waiting_for_next = false
	# Grąžinam masyvą
	return combination

func _on_food_button_pressed(index: int):
	AudioManager.play_sfx(button_sfx)
	if not active_order:
		return
	var item_data = ITEMS.get(index, null)
	if item_data == null:
		return
	if !order_confirmed_correct: # Tik prieš Confirm pildom selected_items
		if not order_zone_active:
			selected_items.append(item_data.tag)
		# UI vis tiek atnaujinam, kad žaidėjas matytų ką spaudė
		label_2d.text = "📝 Pasirinkta:\n" + "\n".join(
			selected_items.map(func(tag):
				for key in ITEMS.keys():
					if ITEMS[key].tag == tag:
						return ITEMS[key].label
				return tag)
		)
	var item_cost = product_costs[index] * product_discount
	if Global.money < item_cost:
		label_2d.text = "❌ Neužtenka pinigų!"
		return
	Global.money -= int(item_cost)
	_update_money_label()
	# Spawninam objektą
	if index < product_scenes.size() and index < product_spawn_points.size():
		var scene = product_scenes[index]
		var spawn_point = get_node(product_spawn_points[index])
		if scene and spawn_point:
			var instance = scene.instantiate()
			get_parent().add_child(instance)
			instance.global_position = spawn_point.global_position
			instance.set_meta("tag", item_data.tag)
			# Play spawn sound
			if pipe_sfx:
				AudioManager.play_sfx(pipe_sfx)
			# Spawn smoke particles at spawn location
			if particle_manager:
				particle_manager.spawn_smoke_particles(spawn_point.global_position, 5)

func _on_confirm_pressed():
	AudioManager.play_sfx(button_sfx)
	if not active_order:
		return
	if selected_items.is_empty():
		label_2d.text = "❌ Nieko nepasirinkta!"
		return
	if order_confirmed_correct:
		return
	var correct_order_tags = original_order.map(func(i): return i.tag).filter(func(t): return t != SPECIAL_MEAT.tag)
	var sel_sorted = selected_items.duplicate()
	sel_sorted.sort()
	var correct_sorted = correct_order_tags.duplicate()
	correct_sorted.sort()
	if sel_sorted == correct_sorted:
		if not order_confirmed_correct:
			order_time_left += 10
			round_timer.start(order_time_left)
			order_confirmed_correct = true
			AudioManager.play_sfx(confirm_correct_sfx)
			label_2d.text = "✅ Teisinga kombinacija! Dėkite ingredientus..."
			label_container.visible = false
			order_zone_active = true
			order_zone_area.monitoring = true
	else:
		order_time_left = max(order_time_left - 2, 0)
		round_timer.start(order_time_left)
		label_2d.text = "❌ Neteisinga kombinacija! Laikas sumažintas"
		AudioManager.play_sfx(confirm_wrong_sfx, 0, -20.0)

func _on_order_zone_body_entered(body):
	if not order_zone_active:
		return
	var tag = null
	# Randam grupę, jei jos nėra - nieko nededam
	for group_name in body.get_groups():
		if group_name in ITEMS.values().map(func(i): return i.tag) or group_name == SPECIAL_MEAT.tag:
			tag = group_name
			break
	if tag == null:
		# Objektas neturi tinkamos grupės, ignoruojam
		return
	print("DEBUG: Objekto įeina į zoną. Tag:", tag, "Node:", body.name)
	# SpecialMeat logika: correct tikrina scoring'e
	var correct = false
	if tag == SPECIAL_MEAT.tag:
		correct = original_order.has(SPECIAL_MEAT)
	else:
		correct = original_order.any(func(i): return i.tag == tag)
	# Įdedam į placed_items
	placed_items.append({"tag": tag, "correct": correct})
	# Pašalinam objektą iš scenos
	body.queue_free()
	AudioManager.play_sfx(item_added_sfx)
	# Visada pašalinam iš remaining_order, SpecialMeat taip pat
	for i in remaining_order:
		if i.tag == tag or i == SPECIAL_MEAT:
			remaining_order.erase(i)
			break
	# Jei visi teisingi sudėti, užbaigiame order
	if remaining_order.is_empty():
		AudioManager.play_sfx(confirm_correct_sfx)
		_finish_order_scoring()

func _finish_order_scoring():
	order_zone_active = false
	order_zone_area.set_deferred("monitoring", false)
	var score := 0.0
	# Original combo be special meat
	var original_no_special := original_order.filter(func(i): return i != SPECIAL_MEAT)
	# Tik teisingi itemai
	var placed_correct := placed_items.filter(func(i): return i.correct)
	var placed_tags := placed_correct.map(func(i): return i.tag)
	# Teisingi ir neteisingi objektai
	for item in placed_items:
		if item.correct:
			score += 50
		else:
			score -= 3
	# Eiliškumo bonusas
	var in_order := placed_tags == original_no_special.map(func(i): return i.tag)
	if in_order:
		score *= 1.5
	else:
		score *= 0.9
	# Special meat logika
	var had_special := original_order.has(SPECIAL_MEAT)
	var placed_special := placed_tags.has(SPECIAL_MEAT)
	if had_special and placed_special:
		score *= 1.2
	elif not had_special and placed_special:
		score *= 0.8
	Global.money += int(score)
	day_score += int(score)
	label_2d.text = "✅ Užsakymas baigtas! +" + str(int(score))
	
	# Spawn success particles at NPC torso height
	if particle_manager:
		var particle_pos = counter_point.global_position + Vector3(0, 1.2, 0)  # Spawn at torso level
		particle_manager.spawn_success_sparkles(particle_pos, 12)
		particle_manager.spawn_satisfaction_hearts(particle_pos, 6)
	
	# Užbaigiame order
	_end_order()
	# Atspausdinam naują kvotą / pinigus
	_update_money_label()
	# Patikrinam, ar pasiekta dienos kvota
	if day_score >= Global.current_day_quota:
		_prepare_end_of_day(true)

func _prepare_end_of_day(success: bool):
	if day_end_pending:
		return
	day_end_pending = true
	day_end_success = success
	day_active = false
	order_zone_active = false
	game_time = 0
	# Sustabdom laikmatį
	if day_timer:
		day_timer.stop()
	# Išvalom NPC ir eilę
	if current_npc:
		current_npc.queue_free()
		current_npc = null
	for queue_data in npc_queue:
		if queue_data and queue_data.npc:
			queue_data.npc.queue_free()
	npc_queue.clear()
	# Pradedam durų uždarymą (physics_process)
	label_2d.text = "🏁 Kvota pasiekta. Diena baigta.\nKitai dienai atidarykite duris."

func _on_delete_pressed():
	# Snap Y to floor (use spawn point Y) for the last NPC in the queue, if any
	if npc_queue.size() > 0:
		var last_npc = npc_queue[-1].npc if "npc" in npc_queue[-1] else null
		if last_npc:
			var pos = npc_spawn_point.global_position
			last_npc.global_position = Vector3(pos.x, pos.y, pos.z)
	if not active_order:
		return
	if selected_items.is_empty():
		label_2d.text = "🗑️ Nėra ką trinti."
		return
	# Pašalinam paskutinį
	selected_items.pop_back()
	# Atnaujinam UI su emoji
	if selected_items.is_empty():
		label_2d.text = "🗑️ Išvalyta."
	else:
		label_2d.text = "📝 Pasirinkta:\n" + "\n".join(
			selected_items.map(func(tag):
				for key in ITEMS.keys():
					if ITEMS[key].tag == tag:
						return ITEMS[key].label
				return tag)
		)

func _update_money_label(new_value = null):
	var quota_text := ""
	if day_active and current_day < DAYS.size():
		quota_text = " | Kvota: " + str(day_score) + " / " + str(DAYS[current_day].quota)
	money_label.text = "💰 " + str(Global.money) + " €" + quota_text

func _on_order_timeout():
	if not active_order:
		return
	label_2d.text = "⏳ Laikas baigėsi!"
	_end_order()

func _end_order():
	if not active_order:
		return
	active_order = false
	order_confirmed_correct = false
	round_timer.stop()
	round_timer.visible = false
	order_state = "moving_to_corner_exit" # NPC leaves after order
	selected_items.clear()
	if current_npc:
		current_npc.rotation_degrees.y += 180

func _play_random_radio():
	if radio_tracks.size() == 0:
		return
	# Atsitiktinis track, ne tas pats kaip paskutinė
	var index := randi() % radio_tracks.size()
	while radio_tracks.size() > 1 and index == last_radio_index:
		index = randi() % radio_tracks.size()
	last_radio_index = index
	radio_player.stream = radio_tracks[index]
	radio_player.play()
	# Disconnect if already connected, then reconnect
	if radio_player.finished.is_connected(Callable(self, "_on_radio_finished")):
		radio_player.finished.disconnect(Callable(self, "_on_radio_finished"))
	radio_player.finished.connect(Callable(self, "_on_radio_finished"))

func _on_radio_finished():
	_play_random_radio()

func _spawn_ambient_npc():
	if not npc_scene:
		return
	var ambient_npc = npc_scene.instantiate()
	get_parent().add_child(ambient_npc)
	ambient_npc.global_position = npc_spawn_point.global_position
	ambient_npc.global_rotation_degrees = Vector3(0, 0, 0)
	ambient_npc.is_walking = true
	# Give a random idle pose for variety
	if ambient_npc.has_method("set_initial_pose"):
		var pose_index = randi() % 15
		ambient_npc.call("set_initial_pose", pose_index)
	# Assign random color
	if ambient_npc.has_method("match_body_to_head_color"):
		ambient_npc.call("match_body_to_head_color")
	ambient_npcs.append({"npc": ambient_npc})
