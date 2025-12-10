# Global.gd
extends Node

signal money_changed(new_value)
signal order_time_changed(new_value)

var money: int = 0 :
	set(value):
		money = value
		emit_signal("money_changed")

var order_time: float = 30.0 :
	set(value):
		order_time = value
		emit_signal("order_time_changed", order_time)
