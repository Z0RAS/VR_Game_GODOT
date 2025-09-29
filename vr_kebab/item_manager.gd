extends Node

@export var item_type: String = "Item"
@export var color: Color = Color.WHITE

@onready var mesh_instance := $"../ItemMesh"

func _ready():
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
