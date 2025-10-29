# res://scripts/KebabComputer.gd
extends Node3D

@export var viewport_size := Vector2(512, 512)

@onready var viewport: SubViewport = $SubViewport
@onready var keyboard: Node3D = $EmojiKeyboard

var menu_ui : Control
var game_ui : Control

var current_input: Array = []
var current_order: Array = []

func _ready():
	# prepare SubViewport and UI
	viewport.size = viewport_size
	menu_ui = preload("res://scenes/ui/MenuUI.tscn").instantiate()
	game_ui = preload("res://scenes/ui/GameUI.tscn").instantiate()
	viewport.add_child(menu_ui)
	viewport.add_child(game_ui)
	menu_ui.position = Vector2.ZERO
	game_ui.position = Vector2.ZERO


	menu_ui.visible = true
	game_ui.visible = false


	menu_ui.connect("play_pressed", Callable(self, "_on_play_pressed"))
	menu_ui.connect("options_pressed", Callable(self, "_on_options_pressed"))


	# connect emoji buttons
	for button in keyboard.get_children():
		if button.has_signal("pressed"):
			button.pressed.connect(_on_emoji_pressed)

func _on_play_pressed():
	_enter_game_mode()

func _on_options_pressed():
	# show options later
	print("Options pressed")

func _enter_game_mode():
	menu_ui.visible = false
	game_ui.visible = true
	keyboard.visible = true
	_start_new_order()

func _start_new_order():
	var pool := ["🌯","🥬","🍅","🥩","🧄","🧀","🔥","🥔"]
	current_order = []
	var n := randi() % 3 + 2
	for i in n:
		current_order.append(pool[randi() % pool.size()])
	current_input.clear()
	game_ui.call("set_order", current_order)
	game_ui.call("update_player_input", current_input)
	game_ui.call("show_message", "")

func _on_emoji_pressed(emoji: String):
	current_input.append(emoji)
	game_ui.call("update_player_input", current_input)
	if current_input.size() == current_order.size():
		_check_order()

func _check_order():
	if current_input == current_order:
		game_ui.call("show_message", "✅ Correct!")
	else:
		game_ui.call("show_message", "❌ Wrong!")
	await get_tree().create_timer(1.0).timeout
	_start_new_order()

# Called by Mouse3D to move cursor
func set_mouse_position(pos: Vector2):
	var ev := InputEventMouseMotion.new()
	ev.position = pos
	viewport.push_input(ev)

# Called by Mouse3D click area
func click_mouse(pos: Vector2):
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = pos
	press.pressed = true
	viewport.push_input(press)
	var release := press.duplicate()
	release.pressed = false
	viewport.push_input(release)

# Optional: allow NPCs to set orders externally
func set_external_order(order: Array):
	if not game_ui.visible:
		# automatically enter game mode if menu was still visible
		_enter_game_mode()
	current_order = order.duplicate()
	current_input.clear()
	game_ui.call("set_order", current_order)
	game_ui.call("update_player_input", current_input)
	game_ui.call("show_message", "")
