extends Node3D

@export var cube_scene: PackedScene = preload("res://Grabbables.tscn")
@export var spawn_zone: MeshInstance3D
@export var spacing: float = 0.3

# Categories
var meats = ["Chicken", "Beef", "Lamb", "Falafel"]
var potatoes = ["Fries", "Mashed", "Wedges", "Hash Browns"]
var vegetables = ["Lettuce", "Tomato", "Cabbage", "Onion"]
var sauces = ["Garlic Sauce", "Spicy Sauce", "BBQ"]

# Color mapping for test visualization
var item_colors := {
	"Chicken": Color(1,0.7,0.7), "Beef": Color(0.6,0.3,0.2), "Lamb": Color(0.7,0.4,0.3), "Falafel": Color(0.4,0.3,0.1),
	"Fries": Color(1,1,0), "Mashed": Color(1,0.9,0.7), "Wedges": Color(0.9,0.8,0.5), "Hash Browns": Color(0.8,0.6,0.3),
	"Lettuce": Color(0.3,1,0.3), "Tomato": Color(1,0.2,0.2), "Cabbage": Color(0.5,1,0.5), "Onion": Color(0.9,0.8,1),
	"Garlic Sauce": Color(1,1,0.8), "Spicy Sauce": Color(1,0.4,0.2), "BBQ": Color(0.5,0.2,0)
}

func _ready():
	if spawn_zone == null:
		push_error("No spawn zone assigned!")
		return

	var zone_origin: Vector3 = spawn_zone.global_transform.origin
	var zone_size: Vector3 = spawn_zone.mesh.size * spawn_zone.scale

	# Determine spacing if not fixed
	var spacing_x = spacing
	var spacing_z = spacing

	# How many items fit per row (X direction)
	var items_per_row = int(zone_size.x / spacing_x)
	if items_per_row <= 0:
		items_per_row = 1

	var all_items = meats + potatoes + vegetables + sauces

	for i in range(all_items.size()):
		var item_name = all_items[i]

		# Row / Column calculation
		var row = float(i) / items_per_row
		var col = i % items_per_row

		# Center the grid around the spawn_zone
		var x = (col + 0.5) * spacing_x - zone_size.x / 2
		var z = (row + 0.5) * spacing_z - zone_size.z / 2

		var spawn_pos = zone_origin + Vector3(x, 0, z)
		spawn_cube(item_name, item_colors[item_name], spawn_pos)


func spawn_cube(item_name: String, color: Color, cube_position: Vector3):
	var cube = cube_scene.instantiate()
	add_child(cube)
	cube.global_transform.origin = cube_position

	# Apply color to mesh
	var mesh_instance: MeshInstance3D = cube.get_node("ItemMesh")
	if mesh_instance:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mesh_instance.material_override = mat
	else:
		print("Warning: ItemMesh not found for", item_name)

	# Set label text and fix rotation
	var label: Label3D = cube.get_node("ItemLabel")
	if label:
		label.text = item_name
		
		label.billboard = BaseMaterial3D.BILLBOARD_DISABLED  # NEVER face camera
		label.global_transform.origin = cube.global_transform.origin + Vector3(0, 0.15, 0)  # float above cube
		label.modulate = Color(1,1,1)  # make sure text is visible
	else:
		print("Warning: ItemLabel not found for", item_name)
