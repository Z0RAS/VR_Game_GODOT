extends CanvasLayer

@onready var upgrade_button = $Control/ColorRect/MarginContainer/VBoxContainer/HBoxContainer/Button

func _ready():
	upgrade_button.pressed.connect(_on_upgrade_pressed)


func _on_upgrade_pressed():
	if Global.money <= 0:
		return
	Global.money -= 1
	Global.order_time += 10
	print("Upgrade purchased! Money:", Global.money, "New order time:", Global.order_time)
