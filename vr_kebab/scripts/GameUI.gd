extends Control

func set_order(order: Array):
	var joined = "".join(order)  # Join directly on a string, not on PackedStringArray
	$NPCOrderLabel.text = "Order: " + joined

func update_player_input(input: Array):
	var joined = "".join(input)  # Same here
	$PlayerInputLabel.text = "You: " + joined

func show_message(text: String):
	$MessageLabel.text = text
