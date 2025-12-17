# Global.gd
extends Node

signal money_changed(new_value)
signal order_time_changed(new_value)

# tiesiog kintamieji be setget
var money = 50
var order_time = 20.0

# dienų global kintamieji
var current_combo_count = 0
var current_special_chance = 0.0
var current_day_quota = 0
var current_day_index = 0

# setter funkcijos rankiniu būdu
func set_money(value):
	money = value
	emit_signal("money_changed", money)

func set_order_time(value):
	order_time = value
	emit_signal("order_time_changed", order_time)
