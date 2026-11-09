extends Node

@export_range(0.0, 1.0, 0.01) var loop_lead_time: float = 0.6
@export var music_stream: AudioStream
@export var milestone_sound: AudioStream

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var effect_player: AudioStreamPlayer = $EffectPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("music_player")
	if music_stream:
		audio_player.stream = music_stream
	audio_player.play()

func play_music(stream: AudioStream = null) -> void:
	if stream:
		music_stream = stream
		audio_player.stream = stream
	if not audio_player.playing:
		audio_player.play()

func stop_music() -> void:
	audio_player.stop()

func _process(_delta: float) -> void:
	if not audio_player.playing or not audio_player.stream:
		return

	var restart_position: float = audio_player.stream.get_length() - loop_lead_time
	if restart_position > 0.0 and audio_player.get_playback_position() >= restart_position:
		audio_player.play()

func play_milestone_sound() -> void:
	if not milestone_sound:
		return
	effect_player.stream = milestone_sound
	effect_player.play()
