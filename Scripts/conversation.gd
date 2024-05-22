extends Control

## meste av koden her er tatt fra https://forum.godotengine.org/t/strip-bbcode-from-an-array-and-detect-characters/38846/3

## The speed at which the text animation will play
@export var playback_speed = 1.5
## The speead at which each character will appear
@export var char_speed = 0.08
## The long stop delay
@export var long_stop_delay = 0.4
## The long stop characters
@export var long_stop_chars = [".", "?", "!"]
## The short stop delay
@export var short_stop_delay = 0.2
## The short stop characters
@export var short_stop_chars = [",", ";", ":"]


@onready var rich_text_label: RichTextLabel = $Node/ColorRect2/Panel/RichTextLabel
@onready var rich_text_label2: RichTextLabel = $Node/ColorRect3/Panel/RichTextLabel
@onready var animation_player: AnimationPlayer = $Node/AnimationPlayer
@onready var background_music = $ConvoMusic
@onready var game_node = get_node("/root/" + Global.save_scene)

var clicks = 0

func _ready() -> void:
	start_convo()

func start_convo():
	if Global.world_convo_played == false and Global.save_scene == "World":
		if clicks == 0:
			background_music.play()
			$Node/AnimatedSprite2D2.self_modulate.a = 0.5
			$Node/AnimatedSprite2D.play("talking")
			display(" Så jeg må finne denne kofferten du snakket om?")
			clicks = 1
			await animation_player.animation_finished
	if Global.store_convo_played == false and Global.save_scene == "Store":
		if clicks == 0:
			background_music.play()
			$Node/AnimatedSprite2D2.self_modulate.a = 0.5
			$Node/AnimatedSprite2D.play("talking")
			display(" Jeg er i butikken nå.")
			clicks = 1
			await animation_player.animation_finished
	if Global.jail_convo_played == false and Global.save_scene == "Jail":
		if clicks == 0:
			background_music.play()
			$Node/AnimatedSprite2D2.self_modulate.a = 0.5
			$Node/AnimatedSprite2D.play("talking")
			display(" filern! jeg ble fanget")
			clicks = 1
			await animation_player.animation_finished

func _on_Button_pressed():
	if Global.save_scene == "World":
		if clicks == 1:
			swap_to_second_talker()
			display2(" Ja, den inneholder det enneste viruset som kan stoppe AI'en")
			clicks = 2
			await animation_player.animation_finished
		elif clicks == 2:
			swap_to_first_talker()
			display(" Greit, og hvor finner jeg den?")
			clicks = 3
			await animation_player.animation_finished
		elif clicks == 3:
			swap_to_second_talker()
			display2(" Den skal være i stor buttik i nærheten, mest sannsynlig til venstre")
			clicks = 4
		elif clicks == 4:
			Global.world_convo_played = true
			Global.game_first_loading = false
			clicks = 0
			$Node.visible = false
			get_tree().paused = false
			stop_conversation_music()
	if Global.save_scene == "Store":
		if clicks == 1:
			swap_to_second_talker()
			display2(" kofferten ligger på taket gå å hent den!")
			clicks = 2
		elif clicks == 2: 
			Global.store_convo_played = true
			clicks = 0
			$Node.visible = false
			get_tree().paused = false
			stop_conversation_music()
	if Global.save_scene == "Jail":
		if clicks == 1:
			swap_to_second_talker()
			display2(" Ta det med roo, du har en hackmaster 3000 på deg, du kan lett komme deg ut.")
			clicks = 2
		elif clicks == 2:
			Global.jail_convo_played = true
			clicks = 0
			$Node.visible = false
			get_tree().paused = false
			stop_conversation_music()

func swap_to_first_talker():
	$Node/AnimatedSprite2D2.stop()
	$Node/AnimatedSprite2D2.self_modulate.a = 0.5
	$Node/AnimatedSprite2D.play("talking")
	$Node/AnimatedSprite2D.self_modulate.a = 1

func swap_to_second_talker():
	$Node/AnimatedSprite2D.stop()
	$Node/AnimatedSprite2D.self_modulate.a = 0.5
	$Node/AnimatedSprite2D2.self_modulate.a = 1
	$Node/AnimatedSprite2D2.play("talking")

func display(text:String) -> void:
	# Stop the current animation
	animation_player.stop()

	# Reset the visible characters to 0 and set the text to be displayed
	rich_text_label.visible_characters = 0
	rich_text_label.text = text

	var animation = _generate_animation(rich_text_label.get_parsed_text())

	# If the animation player does not have a global animation library, create one
	if not animation_player.has_animation_library(""):
		animation_player.add_animation_library("", AnimationLibrary.new())
	var library = animation_player.get_animation_library("")

	# remove the old animation if it exists
	if library.has_animation("play_text"):
		library.remove_animation("play_text")

	# Add the new animation
	library.add_animation("play_text", animation)
	# Set the speed of the animation
	animation_player.speed_scale = playback_speed
	animation_player.play("play_text")

func display2(text:String) -> void:
	# Stop the current animation
	animation_player.stop()

	# Reset the visible characters to 0 and set the text to be displayed
	rich_text_label2.visible_characters = 0
	rich_text_label2.text = text

	var animation = _generate_animation2(rich_text_label2.get_parsed_text())

	# If the animation player does not have a global animation library, create one
	if not animation_player.has_animation_library(""):
		animation_player.add_animation_library("", AnimationLibrary.new())
	var library = animation_player.get_animation_library("")

	# remove the old animation if it exists
	if library.has_animation("play_text"):
		library.remove_animation("play_text")

	# Add the new animation
	library.add_animation("play_text", animation)
	# Set the speed of the animation
	animation_player.speed_scale = playback_speed
	animation_player.play("play_text")

func _generate_animation(text:String) -> Animation:
	# Create a new animation with 2 tracks, one for the visible_characters and one for the play_sound()
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	var sound_index = animation.add_track(Animation.TYPE_METHOD)

	animation.track_set_path(track_index, "%s:visible_characters" % get_path_to(rich_text_label))
	animation.track_set_path(sound_index, get_path_to(self))

	# For each character check if it should skip the sound and add a delay
	# if the current character is inside one of the short/long characters array and if the next is a space
	var time = 0.0
	for i in text.length():
		var current_char = text[i]
		var next_char = null
		if i < text.length() - 1:
			next_char = text[i+1]

		var skip_sound = false
		if current_char == " ":
			skip_sound = true
		var delay = char_speed
		if next_char and next_char == " ":
			if current_char in short_stop_chars:
				delay = short_stop_delay
				skip_sound = true
			elif current_char in long_stop_chars:
				delay = long_stop_delay
				skip_sound = true

		animation.track_insert_key(track_index, time, i+1)
		if not skip_sound:
			animation.track_insert_key(sound_index, time, {"method": "play_sound", "args": [i, current_char]})

		time += delay

	# Set the final time to the animation
	animation.length = time

	return animation

func _generate_animation2(text:String) -> Animation:
	# Create a new animation with 2 tracks, one for the visible_characters and one for the play_sound()
	var animation = Animation.new()
	var track_index = animation.add_track(Animation.TYPE_VALUE)
	var sound_index = animation.add_track(Animation.TYPE_METHOD)

	animation.track_set_path(track_index, "%s:visible_characters" % get_path_to(rich_text_label2))
	animation.track_set_path(sound_index, get_path_to(self))

	# For each character check if it should skip the sound and add a delay
	# if the current character is inside one of the short/long characters array and if the next is a space
	var time = 0.0
	for i in text.length():
		var current_char = text[i]
		var next_char = null
		if i < text.length() - 1:
			next_char = text[i+1]

		var skip_sound = false
		if current_char == " ":
			skip_sound = true
		var delay = char_speed
		if next_char and next_char == " ":
			if current_char in short_stop_chars:
				delay = short_stop_delay
				skip_sound = true
			elif current_char in long_stop_chars:
				delay = long_stop_delay
				skip_sound = true

		animation.track_insert_key(track_index, time, i+1)
		if not skip_sound:
			animation.track_insert_key(sound_index, time, {"method": "play_sound", "args": [i, current_char]})

		time += delay

	# Set the final time to the animation
	animation.length = time

	return animation

func stop_conversation_music():
	background_music.stop()
