extends Node3D  # attach to the NPC root (Skeleton)

func _ready():
	randomize_npc_colors()

func randomize_npc_colors():
	# Iterate over all children
	for child in get_children():
		if child is MeshInstance3D:
			var mesh_instance := child as MeshInstance3D
			var mat := mesh_instance.get_active_material(0)
			
			if mat:
				# Make a duplicate so we don't modify the original material
				var new_mat = mat.duplicate()
				new_mat.albedo_color = Color(randf(), randf(), randf())
				mesh_instance.set_surface_override_material(0, new_mat)
