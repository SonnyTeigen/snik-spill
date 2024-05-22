extends Node2D

@onready var global = get_node("/root/Global")  # Få tilgang til global script
@onready var player = $Player
@onready var case = $Case

@onready var ui_label = $UILayer/Control/Label
@onready var message_timer = $UILayer/MessageTimer

@onready var background_music = $BackgroundMusic
@onready var chase_music = $ChaseMusic

func _ready():
	if Global.store_convo_played == false:
		$Conversation.visible = true
		get_tree().paused = true
	$ControlUi/Camera2D.enabled = true
	$ControlUi/Camera2D.make_current()
	case.connect("body_entered", Callable(self, "_on_case_body_entered"))
	message_timer.connect("timeout", Callable(self, "_on_MessageTimer_timeout"))
	update_initial_message()
	background_music.play()  # Start bakgrunnsmusikken når spillet lastes
# Called every frame. 'delta' is the elapsed time since the previous frame.

	for guard in get_tree().get_nodes_in_group("guards"):
		guard.connect("guard_alerted", Callable(self, "_on_guard_alerted"))
		guard.connect("guard_down", Callable(self, "_on_guard_down"))
		guard.connect("chase_state_changed", Callable(self, "_on_chase_state_changed"))

func _process(delta):
	if Input.is_action_pressed("o"):
		print(Global.store_convo_played)
	if get_tree().paused == false:
		$UILayer.visible = true
	else: 
		$UILayer.visible = false
	change_scenes()

func _on_store_exit_point_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true
		Global.store_exit_id = 0  # Hovedutgangen

func _on_store_roof_exit_point_body_entered(body):
	if body.has_method("player"):
		Global.transition_scene = true
		Global.store_exit_id = 1  # Takutgangen

# Eksempel på funksjon som sjekker om spilleren kan forlate scenen
func _on_exit_body_entered(body):
	if body.name == "Player" and global.get_case_status():
		show_message(" Du kan gå nå!", 0)
		get_tree().change_scene("res://Scenes/exit_scene.tscn")  # Bytt til avslutningsscene

func _on_case_body_entered(body):
	if body.name == "Player":
		global.set_case_status(true)  # Oppdaterer status i global.gd
		case.queue_free()  # Fjerner kofferten fra scenen
		show_message(" Kofferten er plukket opp!", 3)

func change_scenes():
	if Global.transition_scene == true:
		if Global.current_scene == "store":
			get_tree().change_scene_to_file("res://Scenes/world.tscn")
			Global.finish_changescenes()

func show_message(text: String, duration: float):
	ui_label.text = text
	if duration > 0:
		message_timer.start(duration)

func update_initial_message():
	if Global.get_case_status():
		show_message(" Kofferten er plukket opp, finn mopeden", 0)
	else:
		show_message(" Plukk opp kofferten og forlat området", 0)

func _on_chase_state_changed(is_in_chase):
	if is_in_chase:
		background_music.stop()
		chase_music.play()
	else:
		chase_music.stop()
		background_music.play()
