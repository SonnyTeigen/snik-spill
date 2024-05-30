extends Node2D

# Referanser til de viktige objektene i scenen
@onready var player = $Player
@onready var exit = $Exit
@onready var case = $Case
@onready var game_node = get_node("/root/" + Global.save_scene)
@onready var player_node = get_node("/root/"+ Global.save_scene +"/Player")
@onready var guard_node = get_tree().get_nodes_in_group(&"guard")

@onready var ui_label = $UILayer/Control/Label
@onready var message_timer = $UILayer/MessageTimer

@onready var background_music = $BackgroundMusic
@onready var chase_music = $ChaseMusic

@onready var global = get_node("/root/Global")  # Få tilgang til global script
const SAVE_PATH = "res://save_config_file.ini"
var has_case = false

func _ready():
	Global.intro_played = true
	if Global.game_first_loading == true:
		$Player.position.x = Global.player_start_posx
		$Player.position.y = Global.player_start_posy
	else:
		$ControlUi/ContainerOptions/VBoxContainer/HSlider.value = Global.sound
		$ControlUi/ContainerOptions/VBoxContainer/HSlider2.value = Global.enemy_sound
		match Global.scene_exit_id:
			0:
				$Player.position.x = Global.player_exit_store_posx
				$Player.position.y = Global.player_exit_store_posy
			1:
				$Player.position.x = Global.player_exit_roof_posx
				$Player.position.y = Global.player_exit_roof_posy
			2:
				$Player.position.x = Global.player_exit_jail_posx
				$Player.position.y = Global.player_exit_jail_posy
	for guard in get_tree().get_nodes_in_group("guards"):
		guard.connect("guard_alerted", Callable(self, "_on_guard_alerted"))
		guard.connect("guard_down", Callable(self, "_on_guard_down"))
		guard.connect("chase_state_changed", Callable(self, "_on_chase_state_changed"))

	case.connect("body_entered", Callable(self, "_on_case_body_entered"))
	exit.connect("body_entered", Callable(self, "_on_exit_body_entered"))
	message_timer.connect("timeout", Callable(self, "_on_MessageTimer_timeout"))
	update_initial_message()
	if Global.menu_open == true:
		get_tree().paused = true
	background_music.play()  # Start bakgrunnsmusikken når spillet lastes
	if Global.is_from_load == true: 
		load_placement()
		$ControlUi.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta):
	Global.sound = $ControlUi/ContainerOptions/VBoxContainer/HSlider.value
	Global.enemy_sound = $ControlUi/ContainerOptions/VBoxContainer/HSlider2.value
	change_scene()
	message_visible()

func load_placement():
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	player_node.position = config.get_value("player", "position")
	var guards = config.get_value("guards", "guards")
	var sounds = config.get_value("sounds", "sounds")
	var enemy_sounds = config.get_value("enemy_sounds", "sounds")
	var i = 0
	var Istring
	for sound in sounds:
		sound.volume_db = sound.volume
		$ControlUi/ContainerOptions/VBoxContainer/HSlider.value = sound.volume
	for sound in enemy_sounds:
		sound.volume_db = sound.volume
		$ControlUi/ContainerOptions/VBoxContainer/HSlider2.value = sound.volume
	for guard in guards:
		if i <= 6:
			guard_node[i].position = guard.position
		else:
			pass
		i = i+1


# Funksjon for å gå ut gjennom global utgangsdør
func _on_exit_body_entered(body):
	if body.name == "Player" and global.get_case_status():
		show_message(" Oppdrag utført!", 0)  # Beskjed forblir synlig
		get_tree().paused = true  # Pause spillet

func _on_guard_alerted(location):
	for guard in get_tree().get_nodes_in_group("guards"):
		if guard.global_position.distance_to(location) <= guard.alert_radius:
			guard.change_state(guard.States.CHASE)

func message_visible():
	if $ControlUi/Container.visible == false && Global.menu_open == true:
		$UILayer.visible = true
		Global.menu_open = false
	else:
		$UILayer.visible = true
	if Input.is_action_pressed("esc"):
		$UILayer.visible = false

func show_message(text: String, duration: float):
	ui_label.text = text
	if duration > 0:
		message_timer.start(duration)

func _on_MessageTimer_timeout():
	ui_label.text = ""  # Skjuler meldingen når timeren løper ut

func get_patrol_paths():
	var paths = []
	for child in get_children():
		if child is Path2D:
			paths.append(child)
	return paths

func _on_chase_state_changed(is_in_chase):
	if is_in_chase:
		background_music.stop()
		chase_music.play()
	else:
		chase_music.stop()
		background_music.play()

func _on_case_body_entered(body):
	if body.name == "Player":
		global.set_case_status(true)  # Oppdaterer status i global.gd
		case.queue_free()  # Fjerner kofferten fra scenen
		show_message(" Kofferten er plukket opp!", 3)

func _on_store_transition_point_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true


func change_scene():
	if Global.transition_scene == true:
		if Global.current_scene == "world":
			get_tree().change_scene_to_file("res://Scenes/store.tscn")
			Global.finish_changescenes()

func update_initial_message():
	if global.get_case_status():
		show_message(" Kofferten er plukket opp, finn mopeden!", 0)
	else:
		show_message(" Finn butikken og plukk opp kofferten", 0)
