# AudioManager.gd
extends Node

var sfx_player: Node3D = null

func _get_sfx_player() -> Node:
	if sfx_player == null:
		var root = get_tree().get_current_scene()
		if root:
			sfx_player = root.get_node_or_null("Player/SFXPlayer")
	return sfx_player

func play_sfx(stream: AudioStream, offset: float = 0.0, volume: float = 0.0):
	var player = _get_sfx_player()
	if player == null or stream == null:
		return
	
	var audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = stream
	audio_player.volume_db = volume
	player.add_child(audio_player)
	
	audio_player.play(offset)
	audio_player.connect("finished", Callable(audio_player, "queue_free"))
