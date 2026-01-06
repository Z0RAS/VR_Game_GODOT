extends Node3D

@onready var an1 = $AnimatedSprite3D
@onready var an2 = $AnimatedSprite3D2
@onready var an3 = $AnimatedSprite3D3

func _ready() -> void:
	an1.play("default")
	an2.play("default")
	an3.play("default")
