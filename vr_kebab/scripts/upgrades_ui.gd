extends CanvasLayer

# Pilni keliai į mygtukus ir label
@onready var upgrade_button_order_time = $Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/UpgradeOrderTimeButton
@onready var upgrade_button_discount   = $Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/UpgradeDiscountButton
@onready var info_label                = $Control/ColorRect/MarginContainer/VBoxContainer/InfoLabel

func _ready():
	upgrade_button_order_time.pressed.connect(_on_upgrade_order_time_pressed)
	upgrade_button_discount.pressed.connect(_on_upgrade_discount_pressed)

# Upgrade 1: prailginam užsakymo laiką
func _on_upgrade_order_time_pressed():
	var upgrade_cost = 10
	if Global.money < upgrade_cost:
		info_label.text = "❌ Neužtenka pinigų!"
		return

	Global.set_money(Global.money - upgrade_cost)
	Global.order_time += 10
	info_label.text = "✅ Užsakymo laikas +10s!"
	print("Upgrade purchased! Money:", Global.money, "New order time:", Global.order_time)

# Upgrade 2: sumažiname žaliavų kainą per pusę
func _on_upgrade_discount_pressed():
	var upgrade_cost = 50
	if Global.money < upgrade_cost:
		info_label.text = "❌ Neužtenka pinigų!"
		return

	Global.set_money(Global.money - upgrade_cost)

	# Pasiekiame terminal.gd (scene root)
	var terminal = get_node("/root/Main/OrderTerminal")
	if terminal:
		terminal.product_discount = 0.5
		info_label.text = "✅ Žaliavų kainos sumažintos 50%!"
		print("Žaliavų kainos sumažintos 50%! Money:", Global.money)
	else:
		info_label.text = "❌ Terminal node nerastas!"
		print("Terminal node nerastas!")
