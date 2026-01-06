extends CanvasLayer

# Pilni keliai į mygtukus ir label
@onready var upgrade_button_order_time = $Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/UpgradeOrderTimeButton
@onready var upgrade_button_discount   = $Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer2/UpgradeDiscountButton
@onready var info_label                = $Control/ColorRect/MarginContainer/VBoxContainer/InfoLabel

var order_time_upgrades := 0
const MAX_ORDER_TIME_UPGRADES := 4
var discount_purchased := false
var resources_upgrade_count := 0
const MAX_RESOURCES_UPGRADES := 1

func _ready():
	upgrade_button_order_time.pressed.connect(_on_upgrade_order_time_pressed)
	upgrade_button_discount.pressed.connect(_on_upgrade_discount_pressed)
	_update_buttons()

func _update_buttons():
	upgrade_button_order_time.disabled = order_time_upgrades >= MAX_ORDER_TIME_UPGRADES
	upgrade_button_discount.disabled = resources_upgrade_count >= MAX_RESOURCES_UPGRADES

func _set_info(text: String):
	info_label.text = text

# Upgrade 1: prailginam užsakymo laiką

func _on_upgrade_order_time_pressed():
	if order_time_upgrades >= MAX_ORDER_TIME_UPGRADES:
		_set_info("✅ Laiko pratęsimo limitas pasiektas.")
		return
	var upgrade_cost = 10
	if Global.money < upgrade_cost:
		_set_info("❌ Neužtenka pinigų!")
		return

	Global.set_money(Global.money - upgrade_cost)
	Global.order_time += 10
	order_time_upgrades += 1
	# Also increment resources_upgrade_count and update visuals
	resources_upgrade_count += 1
	_update_buttons()
	_set_info("✅ Užsakymo laikas +10s! (" + str(order_time_upgrades) + "/" + str(MAX_ORDER_TIME_UPGRADES) + ")")
	print("Upgrade purchased! Money:", Global.money, "New order time:", Global.order_time)
	# Unhide upgrade visuals if set
	var terminal = get_node("/root/Main/OrderTerminal")
	if terminal:
		print("NUpikrta")
		terminal.show_upgrade_visuals(resources_upgrade_count)

# Upgrade 2: sumažiname žaliavų kainą per pusę

func _on_upgrade_discount_pressed():
	if resources_upgrade_count >= MAX_RESOURCES_UPGRADES:
		_set_info("✅ Resursų limitas pasiektas.")
		return
	var upgrade_cost = 50
	if Global.money < upgrade_cost:
		_set_info("❌ Neužtenka pinigų!")
		return

	Global.set_money(Global.money - upgrade_cost)

	# Pasiekiame terminal.gd (scene root)
	var terminal = get_node("/root/Main/OrderTerminal")
	if terminal:
		terminal.product_discount = 0.5
		resources_upgrade_count += 1
		_update_buttons()
		_set_info("✅ Žaliavų kainos sumažintos 50%! (" + str(resources_upgrade_count) + "/" + str(MAX_RESOURCES_UPGRADES) + ")")
		print("Žaliavų kainos sumažintos 50%! Money:", Global.money)
		# Unhide upgrade visuals if set
		terminal.show_upgrade_visuals(resources_upgrade_count)
	else:
		_set_info("❌ Terminal node nerastas!")
		print("Terminal node nerastas!")
