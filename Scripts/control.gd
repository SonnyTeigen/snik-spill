extends Control

const SAVE_PATH = "res://save_config_file.ini"

@onready var game_node = get_node("/root/" + Global.save_scene)
@onready var player_node = get_node("/root/"+ Global.save_scene +"/Player")
@onready var convo_node = get_node("/root/"+Global.save_scene+"/Conversation")

func _ready():
	if Global.menu_open == true:
		$MenuMusic.play()
		$Container.visible = true
		$Camera2D.make_current()
	else:
		$Camera2D.enabled = false

func _process(_delta):
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

func _on_button_2_pressed():
	$MenuMusic.stop()
	$Container2.visible = false
	if Global.world_convo_played == true:
		get_tree().paused = false
	$Camera2D.enabled = false
	if Global.game_first_loading == true:
		convo_node.visible = true
		convo_node.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_button_3_pressed():
	get_tree().quit()

func _on_button_4_pressed():
	var config := ConfigFile.new()
	config.set_value("player", "position", player_node.position)
	
	var sounds := []
	for sound in get_tree().get_nodes_in_group(&"sound"):
		sounds.push_back({
			volume = sound.volume_db
		})
	
	config.set_value("sounds", "sounds", sounds)

	var guards := []
	for guard in get_tree().get_nodes_in_group(&"guard"):
		guards.push_back({
			position = guard.position,
		})
	config.set_value("guards", "guards", guards)

	config.save(SAVE_PATH)

func _on_button_5_pressed():
	var config := ConfigFile.new()
	config.load(SAVE_PATH)

	player_node.position = config.get_value("player", "position")

	get_tree().call_group("guards", "queue_free")

	var guards = config.get_value("guards", "guards")
	
	var sounds = config.get_value("sounds", "sounds")
	
	for sound in sounds:
		sound.volume_db = sound.volume
		$ContainerOptions/VBoxContainer/HSlider.value = sound.volume

	for guard_config in guards:
		var guard := preload("res://Scenes/guard.tscn").instantiate()
		guard.position = guard_config.position
		game_node.add_child(guard)

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
	for sound in get_tree().get_nodes_in_group(&"EnemySound"):
		sound.volume_db = $ContainerOptions/VBoxContainer/HSlider2.value


func _on_control_pressed():
	$Container2.visible = false
	$Container.visible = false
	$ContainerControls.visible = true

