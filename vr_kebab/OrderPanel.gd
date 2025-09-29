extends Control

@onready var order_text_label = $VBoxContainer/OrderText
@onready var timer_label = $VBoxContainer/TimerLabel

var time_left: float = 0.0

func setup(order_text: String, lifetime: float):
	order_text_label.text = order_text
	time_left = lifetime
	update_timer()


func _process(delta):
	if time_left > 0:
		time_left -= delta
		update_timer()
		if time_left <= 0:
			queue_free()  # remove panel when expired
			# TODO: later: emit signal for completed/expired order

func update_timer():
	timer_label.text = "Time left: %ds" % int(time_left)
