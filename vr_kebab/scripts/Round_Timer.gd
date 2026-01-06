extends Control
class_name RoundTimer

signal timeout

@export var total_time: float = 10.0

var remaining: float = 0.0
var running := false

@onready var ring: TextureProgressBar = $TextureProgressBar

func start(time: float = -1.0):
	if time > 0:
		total_time = time

	remaining = total_time
	ring.max_value = total_time
	ring.value = total_time
	running = true


func stop():
	running = false


func _process(delta: float):
	if not running:
		return
		
	remaining -= delta
	ring.value = remaining

	if remaining <= 0:
		running = false
		ring.value = 0
		timeout.emit()
