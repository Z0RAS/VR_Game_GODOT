extends Area3D

signal pressed
signal released

func _ready():
	# Prisijungiame prie įėjimo/išėjimo signalų
	area_entered.connect(_on_entered)
	area_exited.connect(_on_exited)
	body_entered.connect(_on_entered)
	body_exited.connect(_on_exited)


func _on_entered(item: Node) -> void:
	pressed.emit()
	print("Mygtukas paspaustas!")

func _on_exited(item: Node) -> void:
	released.emit()
	print("Mygtukas atleistas!")
