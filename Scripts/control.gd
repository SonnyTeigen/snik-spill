extends Control

const SAVE_PATH = "res://save_config_file.ini"

@onready var game_node = get_node("/root/" + Global.save_scene)
@onready var player_node = get_node("/root/"+ Global.save_scene +"/Player")
@onready var convo_node = get_node("/root/"+Global.save_scene+"/Conversation")

func _ready():
	if Global.game_first_loading == false:
		$Container.visible = false
	if Global.is_from_load == true:
		$Container2/Label.text = "spillet er lastet inn"
		$Container2/AnimationPlayer.play("fade_out")
		$MenuMusic.play()
		$Container2.visible = true
	if Global.menu_open == true:
		$MenuMusic.play()
		$Container.visible = true
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false

func _process(_delta):
	if Input.is_action_pressed("o"):
		Global.menu_open
	if Global.menu_open == true:
		pass
	else:
		if Input.is_action_pressed("esc"):
			if $Container2.visible == false:
				$MenuMusic.play()
				$Container2.visible = true
				$Camera2D.enabled = true
				$Camera2D.make_current()
				get_tree().paused = true
	if $ContainerControls.visible == true:
		if Input.is_action_pressed("action"):
			$ContainerControls/Label2.visible = true
		else: 
			$ContainerControls/Label2.visible = false

func _on_button_1_pressed():
	$MenuMusic.stop()
	$Container.visible = false
	if Global.world_convo_played == true:
		get_tree().paused = false
	$Camera2D.enabled = false
	if Global.game_first_loading == true:
		convo_node.visible = true
		convo_node.process_mode = Node.PROCESS_MODE_ALWAYS
	Global.is_from_load = false

func _on_button_2_pressed():
	$MenuMusic.stop()
	$Container.visible = false
	$Container2.visible = false
	if Global.world_convo_played == true:
		get_tree().paused = false
	$Camera2D.enabled = false
	if Global.game_first_loading == true:
		convo_node.visible = true
		convo_node.process_mode = Node.PROCESS_MODE_ALWAYS
	Global.is_from_load = false

func _on_button_3_pressed():
	get_tree().quit()

func _on_button_4_pressed():
	var config := ConfigFile.new()
	config.set_value("player", "position", player_node.position)
	config.set_value("location", "current", Global.current_scene)
	config.set_value("location", "scene", Global.save_scene)
	config.set_value("global", "game_started", Global.game_first_loading)
	config.set_value("global", "intro_played", Global.intro_played)
	config.set_value("global", "world_convo_played", Global.world_convo_played)
	config.set_value("global", "store_convo_played", Global.store_convo_played)
	config.set_value("global", "jail_convo_played", Global.jail_convo_played)
	
	var paths := []
	for path in get_tree().get_nodes_in_group(&"path"):
		paths.push_back({
			path = path.get_curve()
		})
	
	config.set_value("paths", "paths", paths)
	var sounds := []
	for sound in get_tree().get_nodes_in_group(&"sound"):
		sounds.push_back({
			volume = sound.volume_db
		})
	
	config.set_value("sounds", "sounds", sounds)
	
	var enemy_sounds := []
	for enemy_sound in get_tree().get_nodes_in_group(&"enemy_sound"):
		enemy_sounds.push_back({
			enemy_volume = enemy_sound.volume_db
		})
	
	config.set_value("enemy_sounds", "sounds", sounds)
	
	var guards := []
	for guard in get_tree().get_nodes_in_group(&"guard"):
		guards.push_back({
			position = guard.position,
		})
	config.set_value("guards", "guards", guards)
	
	config.save(SAVE_PATH)
	
	$Container2/Label.text = "Spillet er lagret"
	$Container2/AnimationPlayer.play("fade_out")

func change_scene():
	Global.is_from_load = true
	get_tree().change_scene_to_file("res://Scenes/"+Global.current_scene+".tscn")
	$Container2.visible = true

func _on_button_5_pressed():
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	Global.intro_played = config.get_value("global", "intro_played")
	Global.game_first_loading = config.get_value("global", "game_started")
	Global.world_convo_played = config.get_value("global", "world_convo_played")
	Global.store_convo_played = config.get_value("global", "store_convo_played")
	Global.jail_convo_played = config.get_value("global", "jail_convo_played")
	Global.save_scene = config.get_value("location", "scene")
	Global.current_scene = config.get_value("location", "current")
	Global.sound = config.get_value("sounds", "sounds")
	Global.enemy_sound = config.get_value("enemy_sounds", "sounds")
	change_scene()

func _on_options_pressed():
	$Container2.visible = false
	$Container.visible = false
	$ContainerOptions.visible = true

func _on_button_pressed():
	$ContainerOptions.visible = false
	$ContainerControls.visible = false
	if Global.menu_open == true:
		$Container.visible = true
	else:
		$Container2.visible = true
		

func _on_h_slider_value_changed(value):
	for sound in get_tree().get_nodes_in_group(&"sound"):
		sound.volume_db = $ContainerOptions/VBoxContainer/HSlider.value

func _on_h_slider_2_value_changed(value):
	for sound in get_tree().get_nodes_in_group(&"enemy_sound"):
		sound.volume_db = $ContainerOptions/VBoxContainer/HSlider2.value


func _on_control_pressed():
	$Container2.visible = false
	$Container.visible = false
	$ContainerControls.visible = true
