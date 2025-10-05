extends Node

# Music files
var intro_music = preload("res://assets/sounds/intro.mp3")
var loop_music = preload("res://assets/sounds/loop.mp3")

# Sound effects
var item_drop_sound = preload("res://assets/sounds/item_drop.wav")
var item_get_sound = preload("res://assets/sounds/item_get.wav")
var player_shoot_sound = preload("res://assets/sounds/player_shoot.wav")
var ghost_shoot_sound = preload("res://assets/sounds/ghost_shoot.wav")
var imp_shoot_sound = preload("res://assets/sounds/imp_shoot.wav")
var hurt_sound = preload("res://assets/sounds/hurt.wav")
var dash_sound = preload("res://assets/sounds/dash.wav")

# Audio players
var intro_player: AudioStreamPlayer
var loop_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var item_sfx_player: AudioStreamPlayer  # Separate player for item sounds
var dash_player: AudioStreamPlayer  # Separate player for dash sound

func _ready():
	# Create music players
	intro_player = AudioStreamPlayer.new()
	intro_player.stream = intro_music
	intro_player.bus = "Music"  # Optional: if you have a music bus set up
	intro_player.volume_db = -12.0  # 50% volume
	add_child(intro_player)
	
	loop_player = AudioStreamPlayer.new()
	loop_player.stream = loop_music
	loop_player.bus = "Music"  # Optional: if you have a music bus set up
	loop_player.volume_db = -12.0  # 50% volume
	add_child(loop_player)
	
	# Create sound effects player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.bus = "SFX"  # Optional: if you have an SFX bus set up
	add_child(sfx_player)
	
	# Create separate item sound effects player
	item_sfx_player = AudioStreamPlayer.new()
	item_sfx_player.bus = "Items"  # Separate bus for item sounds
	add_child(item_sfx_player)
	
	# Create separate dash sound player
	dash_player = AudioStreamPlayer.new()
	dash_player.stream = dash_sound
	dash_player.bus = "Dash"  # Separate bus for dash sound
	dash_player.volume_db = -10.0  # Quieter dash sound
	add_child(dash_player)
	
	# Connect signals
	intro_player.finished.connect(_on_intro_finished)
	Globals.shoot_sound.connect(_on_shoot_sound)
	Globals.player_hurt.connect(_on_player_hurt)
	Globals.player_dash.connect(_on_player_dash)
	
	# Start playing the intro
	play_music()

func play_music():
	intro_player.play()
	print("Playing intro music...")

func _on_intro_finished():
	# When intro ends, start looping the main music
	loop_player.play()
	# Enable looping on the loop player
	if loop_player.stream:
		loop_player.stream.loop = true
	print("Intro finished, now looping main music...")

func stop_music():
	intro_player.stop()
	loop_player.stop()

func set_music_volume(volume_db: float):
	intro_player.volume_db = volume_db
	loop_player.volume_db = volume_db

# Sound effects
func play_item_drop():
	item_sfx_player.stream = item_drop_sound
	item_sfx_player.play()

func play_item_get():
	item_sfx_player.stream = item_get_sound
	item_sfx_player.play()

func play_player_shoot():
	sfx_player.stream = player_shoot_sound
	sfx_player.play()

# Shoot sound handler
func _on_shoot_sound(entity_type: String):
	match entity_type:
		"player":
			sfx_player.stream = player_shoot_sound
		"floater":
			sfx_player.stream = ghost_shoot_sound
		"basic":
			sfx_player.stream = imp_shoot_sound
		_:
			push_warning("Unknown entity type for shoot sound: %s" % entity_type)
			return
	
	sfx_player.play()

# Player hurt sound handler
func _on_player_hurt():
	sfx_player.stream = hurt_sound
	sfx_player.play()

# Player dash sound handler
func _on_player_dash():
	dash_player.play()