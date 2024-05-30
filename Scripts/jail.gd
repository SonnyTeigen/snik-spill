extends Node2D

const SAVE_PATH = "res://save_config_file.ini"
@onready var game_node = get_node("/root/" + Global.save_scene)
@onready var player_node = get_node("/root/"+ Global.save_scene +"/Player")
@onready var guard_node = get_tree().get_nodes_in_group(&"guard")
@onready var global = get_node("/root/Global")  # Få tilgang til global script
@onready var player = $Player

@onready var ui_label = $UILayer/Control/Label
@onready var message_timer = $UILayer/MessageTimer

@onready var background_music = $BackgroundMusic
@onready var chase_music = $ChaseMusic

var player_can_open_cell = false

func _ready():
	$ControlUi/ContainerOptions/VBoxContainer/HSlider.value = Global.sound
	$ControlUi/ContainerOptions/VBoxContainer/HSlider2.value = Global.enemy_sound
	if Global.is_from_load == false:
		pass
	else:
		load_placement()
	if Global.jail_convo_played == false:
		$Conversation.visible = true
	$ControlUi/Camera2D.enabled = true
	$ControlUi/Camera2D.make_current()
	get_tree().paused = true
	update_initial_message()
	$Player.position.x = Global.player_start_jail_posx
	$Player.position.y = Global.player_start_jail_posy
	background_music.play()

	for guard in get_tree().get_nodes_in_group("guards"):
		guard.connect("guard_alerted", Callable(self, "_on_guard_alerted"))
		guard.connect("guard_down", Callable(self, "_on_guard_down"))
		guard.connect("chase_state_changed", Callable(self, "_on_chase_state_changed"))

func _process(delta):
	Global.sound = $ControlUi/ContainerOptions/VBoxContainer/HSlider.value
	Global.enemy_sound = $ControlUi/ContainerOptions/VBoxContainer/HSlider2.value
	if get_tree().paused == false:
		$UILayer.visible = true
	else: 
		$UILayer.visible = false
	change_scenes()

func _physics_process(delta):
	if player_can_open_cell == true:
		if Input.is_action_pressed("action"):
			disable_door()
	if Global.jail_puzzle_solved == true:
		$DoorTileMap.set_layer_enabled(0, false)
		$Minigame.visible = false
		Global.menu_open = false
		get_tree().paused = false

func load_placement():
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	player_node.position = config.get_value("player", "position")
	var guards = config.get_value("guards", "guards")
	var sounds = config.get_value("sounds", "sounds")
	var enemy_sounds = config.get_value("enemy_sounds", "sounds")
	var i = 0
	for sound in sounds:
		sound.volume_db = sound.volume
		$ControlUi/ContainerOptions/VBoxContainer/HSlider.value = sound.volume
	for sound in enemy_sounds:
		sound.volume_db = sound.volume
		$ControlUi/ContainerOptions/VBoxContainer/HSlider2.value = sound.volume
	for guard in guards:
		if i <= 1:
			guard_node[i].position = guard.position
		else:
			pass
		i = i+1

func _on_jail_exit_point_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true
		Global.scene_exit_id = 2

func change_scenes():
	if Global.transition_scene == true:
		if Global.current_scene == "jail":
			get_tree().change_scene_to_file("res://Scenes/world.tscn")
			Global.finish_changescenes()

func show_message(text: String, duration: float):
	ui_label.text = text
	if duration > 0:
		message_timer.start(duration)

func update_initial_message():
	show_message(" Kom deg ut av fengsel!", 0)

func disable_door():
	background_music.process_mode = Node.PROCESS_MODE_ALWAYS
	$UILayer.visible = false
	Global.menu_open = true
	$Minigame.visible = true
	get_tree().paused = true

func _on_jail_door_zone_body_entered(body):
	if body.has_method("player"):
		player_can_open_cell = true


func _on_jail_door_zone_body_exited(body):
	if body.has_method("player"):
		player_can_open_cell = false

func _on_chase_state_changed(is_in_chase):
	if is_in_chase:
		background_music.stop()
		chase_music.play()
	else:
		chase_music.stop()
		background_music.play()
