extends Node3D

# === KONFIGŪRACIJA ===
@export var button_paths: Array[NodePath]
@export var confirm_button_path: NodePath
@export var delete_button_path: NodePath
@export var label_3d_path: NodePath        # Label3D, laikys teisingą kombinaciją
@export var terminal_viewport_path: NodePath  # SubViewport su Label2D terminalui

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

# NODES
@onready var label_3d: Label3D = get_node(label_3d_path)
@onready var terminal_viewport: SubViewport = get_node(terminal_viewport_path)
@onready var label_2d: Label = terminal_viewport.get_node("Label")
@onready var confirm_button = get_node(confirm_button_path)
@onready var delete_button = get_node(delete_button_path)

func _ready():
	# Sugeneruojam pradinę kombinaciją Label3D
	new_combination()
	
	# Mygtukų registracija
	for i in range(button_paths.size()):
		var holder = get_node(button_paths[i])
		var btn = holder.get_node_or_null("InteractableAreaButton")
		if not btn:
			push_warning("Button %s neranda InteractableAreaButton child!" % holder.name)
			continue
		btn.button_pressed.connect(_on_food_button_pressed.bind(i))
	
	# Confirm ir Delete
	var confirm_btn = confirm_button.get_node_or_null("InteractableAreaButton")
	var delete_btn = delete_button.get_node_or_null("InteractableAreaButton")
	if confirm_btn:
		confirm_btn.button_pressed.connect(_on_confirm_pressed)
	if delete_btn:
		delete_btn.button_pressed.connect(_on_delete_pressed)

# ============================
# FUNKCIJOS
# ============================

# Sukuria naują atsitiktinę kombinaciją ir saugo Label3D
func new_combination(count: int = 3):
	var all_items = button_labels.values()
	all_items.shuffle()
	var combination = all_items.slice(0, count)
	label_3d.text = "\n".join(combination)  # Label3D saugo „teisingą“ kombinaciją
	print("New combination (debug):", combination) # debugui

# Mygtuko paspaudimas
func _on_food_button_pressed(index: int):
	var item = button_labels.get(index, "")
	if item == "":
		return
	selected_items.append(item)
	label_2d.text = "📝 Pasirinkta:\n" + "\n".join(selected_items)

# Confirm mygtukas
func _on_confirm_pressed():
	if selected_items.is_empty():
		label_2d.text = "❌ Nieko nepasirinkta!"
		return

	# Gaunam teisingą kombinaciją iš Label3D
	var correct_combination = Array(label_3d.text.split("\n"))

	# Palyginam tvarka nesvarbi
	var selected_sorted = selected_items.duplicate()
	selected_sorted.sort()
	var correct_sorted = correct_combination.duplicate()
	correct_sorted.sort()

	if selected_sorted == correct_sorted:
		label_2d.text = "✅ Teisinga!"
		new_combination()  # sukuriam naują kombinaciją
	else:
		label_2d.text = "❌ Bloga!"

	# Išvalom pasirinkimus
	selected_items.clear()

# Delete mygtukas
func _on_delete_pressed():
	if not selected_items.is_empty():
		selected_items.pop_back()
	else:
		label_2d.text = "🗑️ Viskas išvalyta."
		selected_items.clear()
