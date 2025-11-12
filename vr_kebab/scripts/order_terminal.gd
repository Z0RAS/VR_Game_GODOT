extends Node3D

# === KONFIGŪRACIJA ===
@export var button_paths: Array[NodePath]
@export var confirm_button_path: NodePath
@export var delete_button_path: NodePath
@export var label_3d_path: NodePath        # Label3D, laikys teisingą kombinaciją
@export var terminal_viewport_path: NodePath  # SubViewport su Label2D terminalui
@export var money_label_path: NodePath     # Label3D, rodys surinktus pinigus
@export var mesh_to_hide_path: NodePath    # MeshInstance3D, kuris dings laikinai

# Mygtukų etiketes
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

# === VIDINIAI KINTAMIEJI ===
var selected_items: Array = []
var money: int = 0

# === NODES ===
@onready var label_3d: Label3D = get_node(label_3d_path)
@onready var terminal_viewport: SubViewport = get_node(terminal_viewport_path)
@onready var label_2d: Label = terminal_viewport.get_node("Control/Label")
@onready var confirm_button = get_node(confirm_button_path)
@onready var delete_button = get_node(delete_button_path)
@onready var money_label: Label = get_node(money_label_path)
@onready var mesh_to_hide: MeshInstance3D = get_node(mesh_to_hide_path)

func _ready():
	new_combination()
	_update_money_label()
	
	for i in range(button_paths.size()):
		var holder = get_node(button_paths[i])
		var btn = holder.get_node_or_null("InteractableAreaButton")
		if not btn:
			push_warning("Button %s neranda InteractableAreaButton child!" % holder.name)
			continue
		btn.button_pressed.connect(_on_food_button_pressed.bind(i))
	
	var confirm_btn = confirm_button.get_node_or_null("InteractableAreaButton")
	var delete_btn = delete_button.get_node_or_null("InteractableAreaButton")
	if confirm_btn:
		confirm_btn.button_pressed.connect(_on_confirm_pressed)
	if delete_btn:
		delete_btn.button_pressed.connect(_on_delete_pressed)

# ============================
# FUNKCIJOS
# ============================

func new_combination(count: int = 3):
	var all_items = button_labels.values()
	all_items.shuffle()
	var combination = all_items.slice(0, count)
	label_3d.text = "\n".join(combination)
	print("New combination (debug):", combination)

func _on_food_button_pressed(index: int):
	var item = button_labels.get(index, "")
	if item == "":
		return
	selected_items.append(item)
	label_2d.text = "📝 Pasirinkta:\n" + "\n".join(selected_items)

func _on_confirm_pressed():
	if selected_items.is_empty():
		label_2d.text = "❌ Nieko nepasirinkta!"
		return

	var correct_combination = Array(label_3d.text.split("\n"))

	var selected_sorted = selected_items.duplicate()
	selected_sorted.sort()
	var correct_sorted = correct_combination.duplicate()
	correct_sorted.sort()

	if selected_sorted == correct_sorted:
		label_2d.text = "✅ Teisinga!"
		money += 1
		_update_money_label()
		_hide_mesh_temporarily()
		new_combination()
	else:
		label_2d.text = "❌ Neteisinga užsakymas!"

	selected_items.clear()

func _on_delete_pressed():
	if selected_items.is_empty():
		label_2d.text = "🗑️ Nėra ką trinti."
		return

	# Pašalinam paskutinį įrašą
	selected_items.pop_back()

	# Atnaujinam tekstą terminale
	if selected_items.is_empty():
		label_2d.text = "🗑️ Viskas išvalyta."
	else:
		label_2d.text = "📝 Pasirinkta:\n" + "\n".join(selected_items)


func _update_money_label():
	money_label.text = "💰 " + str(money) + " €"

func _hide_mesh_temporarily():
	mesh_to_hide.visible = false
	await get_tree().create_timer(5.0).timeout
	mesh_to_hide.visible = true
