extends Node2D

@onready var controlui = get_node("/root/World/ControlUi")
# Called when the node enters the scene tree for the first time.

func _ready():
	play_intro()

func _process(delta):
	if Input.is_action_pressed("esc"):
		$Node2D.visible = false
		controlui.visible = true

func play_intro():
	if Global.intro_played == false:
		$Node2D.visible = true
		$Node2D/AnimationPlayer.play("fade_in")
		await get_tree().create_timer(6).timeout
		$Node2D/AnimationPlayer.play("fade_out")
		await get_tree().create_timer(3).timeout
		$Node2D.visible = false
		controlui.visible = true
		Global.intro_played = true
	else:
		$Node2D.visible = false
