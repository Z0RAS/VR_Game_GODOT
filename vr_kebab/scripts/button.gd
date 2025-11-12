@tool
extends Node3D  # arba kokia tavo scena root
@export var button_color: Color = Color(1, 0, 0)  # default raudona

@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready():
	if mesh:
		# Sukuriame unikalų materialą, kad nekeištų visų duplicate
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat = mat.duplicate()  # copy existing material
		else:
			mat = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, mat)
		
		# Pakeičiam spalvą
		mat.albedo_color = button_color
