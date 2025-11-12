extends Node

@export var trigger_action: String = "trigger"
@export var target_node: NodePath  # Node, kurį norime įjungti/išjungti

@onready var target = get_node(target_node)

func _process(delta):
	# Gauname trigger vertę iš OpenXR
	var trigger_value = Input.get_action_strength(trigger_action)
	
	# Jei trigger paspaustas (reikšmė > 0.1), įjungiame target
	if trigger_value > 0.1:
		target.visible = true
		if target.has_method("activate"):
			target.activate()
	else:
		target.visible = false
		if target.has_method("deactivate"):
			target.deactivate()
