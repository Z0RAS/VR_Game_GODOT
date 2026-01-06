extends Node3D

# Particle effect manager for VFX feedback

func _ready():
	Global.money_changed.connect(_on_money_changed)

# Helper to create a simple particle mesh
func _create_particle_mesh(color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3
	mesh_instance.mesh = sphere_mesh
	mesh_instance.scale = Vector3(1.5, 1.5, 1.5)  # Make particles larger
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	mesh_instance.material_override = material
	
	return mesh_instance

# Helper to add particles to scene root so global_position works correctly
func _add_particle(particle: Node3D) -> void:
	get_tree().root.add_child(particle)
	particle.owner = get_tree().root

func _on_money_changed(new_value):
	# Spawn money particles when money changes
	spawn_money_particles()

# Spawn floating money particles
func spawn_money_particles(amount: int = 3, position: Vector3 = Vector3.ZERO):
	if position == Vector3.ZERO:
		# Use a default spawn point (counter area)
		position = global_position + Vector3(0, 1, 0)
	
	for i in range(amount):
		var particle = _create_particle_mesh(Color.GREEN)  # Green for money
		_add_particle(particle)
		particle.global_position = position + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
		
		_animate_particle_simple(particle, position.y + 1.5, 1.5)

# Simple non-blocking particle animation
func _animate_particle_simple(particle: MeshInstance3D, target_y: float, duration: float) -> void:
	var start_pos = particle.global_position
	var start_time = Time.get_ticks_msec()
	var start_alpha = 1.0
	
	while particle and is_instance_valid(particle):
		var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
		if elapsed >= duration:
			particle.queue_free()
			return
		
		var progress = elapsed / duration
		particle.global_position = start_pos.lerp(Vector3(start_pos.x, target_y, start_pos.z), progress)
		var mat = particle.material_override.duplicate()
		mat.albedo_color.a = start_alpha * (1.0 - progress)
		particle.material_override = mat
		await get_tree().process_frame

# Spawn success sparkles
func spawn_success_sparkles(position: Vector3, amount: int = 8):
	for i in range(amount):
		var particle = _create_particle_mesh(Color.GREEN)  # Green for success/completion
		_add_particle(particle)
		
		# Random burst direction
		var burst_dir = Vector3(
			randf_range(-1, 1),
			randf_range(0.5, 1),
			randf_range(-1, 1)
		).normalized()
		
		particle.global_position = position
		
		var end_pos = position + burst_dir * 2.0
		_animate_particle_burst(particle, end_pos, 1.2)

# Spawn satisfaction hearts
func spawn_satisfaction_hearts(position: Vector3, amount: int = 5):
	for i in range(amount):
		var particle = _create_particle_mesh(Color(1.0, 0.8, 0.0, 1.0))  # Gold/orange for happy
		_add_particle(particle)
		
		particle.global_position = position + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
		
		_animate_particle_simple(particle, position.y + 1.5, 2.0)

# Burst animation helper
func _animate_particle_burst(particle: MeshInstance3D, end_pos: Vector3, duration: float) -> void:
	var start_pos = particle.global_position
	var start_time = Time.get_ticks_msec()
	var start_alpha = 1.0
	
	while particle and is_instance_valid(particle):
		var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0
		if elapsed >= duration:
			particle.queue_free()
			return
		
		var progress = elapsed / duration
		particle.global_position = start_pos.lerp(end_pos, progress)
		var mat = particle.material_override.duplicate()
		mat.albedo_color.a = start_alpha * (1.0 - progress)
		particle.material_override = mat
		await get_tree().process_frame

# Spawn angry/frustrated red particles
func spawn_frustration_particles(position: Vector3, amount: int = 4):
	for i in range(amount):
		var particle = _create_particle_mesh(Color.RED)  # Red for frustration/failure
		_add_particle(particle)
		
		# Random burst direction
		var burst_dir = Vector3(
			randf_range(-1, 1),
			randf_range(0, 1),
			randf_range(-1, 1)
		).normalized()
		
		particle.global_position = position
		
		var end_pos = position + burst_dir * 1.5
		_animate_particle_burst(particle, end_pos, 0.8)

# Spawn smoke particles for item spawn effect
func spawn_smoke_particles(position: Vector3, amount: int = 5):
	for i in range(amount):
		var particle = _create_particle_mesh(Color(0.7, 0.7, 0.7, 0.8))  # Gray smoke
		_add_particle(particle)
		particle.scale = Vector3(0.8, 0.8, 0.8)  # Slightly smaller than default
		particle.global_position = position + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2))
		
		# Smoke floats upward and dissipates
		var target_y = position.y + 0.8
		_animate_particle_simple(particle, target_y, 0.8)
