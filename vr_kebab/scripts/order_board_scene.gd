extends Node3D

@onready var orders_container = $SubViewport/CanvasLayer/OrdersContainer
@onready var timer = $Timer   # add a Timer node next to SubViewport

@export var order_lifetime := 10.0
var order_panel_scene: PackedScene = preload("res://scenes/OrderPanel.tscn")

var meats = ["Chicken", "Beef", "Lamb", "Falafel"]
var potatoes = ["Fries", "Mashed", "Wedges", "Hash Browns"]
var vegetables = ["Lettuce", "Tomato", "Cabbage", "Onion"]
var sauces = ["Garlic Sauce", "Spicy Sauce", "BBQ"]

func _ready():
	timer.timeout.connect(add_new_order)
	timer.start()
	add_new_order()

func generate_order() -> String:
	var meat = meats.pick_random()
	var potato = potatoes.pick_random()
	var veg = vegetables.pick_random()
	var sauce = sauces.pick_random()
	return "Order:\n- %s\n- %s\n- %s\n- %s" % [meat, potato, veg, sauce]

func add_new_order():
	var order_text = generate_order()
	var panel = order_panel_scene.instantiate()
	orders_container.add_child(panel)

	# Pick a random lifetime between 30 and 60 seconds
	var lifetime = randi_range(30, 60)
	panel.setup(order_text, lifetime)
