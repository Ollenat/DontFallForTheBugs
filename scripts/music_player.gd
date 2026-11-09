extends Node

@export_range(0.0, 1.0, 0.01) var loop_lead_time: float = 0.1

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	audio_player.play()

func _process(_delta: float) -> void:
	if not audio_player.playing or not audio_player.stream:
		return

	var restart_position: float = audio_player.stream.get_length() - loop_lead_time
	if restart_position > 0.0 and audio_player.get_playback_position() >= restart_position:
		audio_player.play()
