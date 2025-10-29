# res://scripts/MenuUI.gd
extends Control
signal play_pressed
signal options_pressed

func _ready():
	$PlayButton.pressed.connect(func(): emit_signal("play_pressed"))
	$OptionsButton.pressed.connect(func(): emit_signal("options_pressed"))
	$QuitButton.pressed.connect(func(): get_tree().quit())
