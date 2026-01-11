extends Node

# Reemplaza estas rutas si guardas tus propios sonidos en otra ubicación.
var music_track: AudioStream = preload("res://Enter the Party.mp3")
var jump_sfx: AudioStream = preload("res://jump.wav")
var power_up_sfx: AudioStream = preload("res://powerUp.wav")
var reset_sfx: AudioStream = preload("res://reset.wav")
# var music_track: AudioStream = preload("res://RUTA/A/TU/MUSICA.mp3")     # ← Actualiza si usas otro archivo
# var jump_sfx: AudioStream = preload("res://RUTA/A/TU/SALTO.wav")         # ← Actualiza si usas otro archivo
# var power_up_sfx: AudioStream = preload("res://RUTA/A/TU/POWERUP.wav")    # ← Actualiza si usas otro archivo
# var reset_sfx: AudioStream = preload("res://RUTA/A/TU/RESET.wav")         # ← Actualiza si usas otro archivo

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_music_player = _create_player("MusicPlayer")
	_sfx_player = _create_player("SfxPlayer")
	if music_track:
		music_track.loop = true
	play_music()

func play_music() -> void:
	if _music_player == null or music_track == null:
		return
	_music_player.stream = music_track
	if _music_player.playing == false:
		_music_player.play()

func play_jump_sfx() -> void:
	if _sfx_player == null or jump_sfx == null:
		return
	_sfx_player.stream = jump_sfx
	_sfx_player.play()

func play_power_up_sfx() -> void:
	if _sfx_player == null or power_up_sfx == null:
		return
	_sfx_player.stream = power_up_sfx
	_sfx_player.play()

func play_reset_sfx() -> void:
	if _sfx_player == null or reset_sfx == null:
		return
	_sfx_player.stream = reset_sfx
	_sfx_player.play()

func _create_player(name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = name
	player.bus = "Master"
	player.autoplay = false
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player
