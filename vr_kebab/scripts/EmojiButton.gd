# res://scripts/EmojiButton.gd
extends Node3D
signal pressed(emoji: String)

@export var emoji: String = "🌯"

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("hands"):
		emit_signal("pressed", emoji)
		_press_effect()

func _press_effect():
	var orig = global_transform
	translate_object_local(Vector3(0, 0, -0.02))
	await get_tree().create_timer(0.14).timeout
	global_transform = orig
