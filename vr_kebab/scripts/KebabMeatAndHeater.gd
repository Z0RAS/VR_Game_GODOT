extends Node3D

# Assign these in the editor
@export var kebab_meat: MeshInstance3D
@export var kebab_heater: MeshInstance3D

# Kebab meat rotation
@export var rotation_speed: float = 1.0 # radians/sec

# Heater emission animation
@export var base_color: Color = Color(1, 0.4, 0.1)
@export var min_energy: float = 0.5
@export var max_energy: float = 2.5
@export var pulse_speed: float = 1.5


var t: float = 0.0
var color_t: float = 0.0
var current_color: Color = Color(1, 0.4, 0.1)
var target_color: Color = Color(randf(), randf(), randf())
@export var color_change_speed: float = 0.5

func _process(delta):
	# Rotate the kebab meat
	if kebab_meat:
		kebab_meat.rotation.z += rotation_speed * delta

	# Animate the heater emission
	if kebab_heater:
		var mat = kebab_heater.get_active_material(0)
		if mat:
			t += delta * pulse_speed
			color_t += delta * color_change_speed
			# Lerp color toward target
			current_color = current_color.lerp(target_color, min(color_t, 1.0))
			if color_t >= 1.0:
				target_color = Color(randf(), randf(), randf())
				color_t = 0.0
			var pulse = 0.5 + 0.5 * sin(t)
			mat.emission_enabled = true
			mat.emission = current_color
			mat.emission_energy = lerp(min_energy, max_energy, pulse)
