extends CharacterBody2D
# Bevegelseshastigheten til spilleren
const speed = 100
var has_case = false  # Holder styr på om spilleren har plukket opp kofferten
var is_hidden = false
var current_dir = "none"
var last_horizontal_dir = "right"  # Lagrer den siste horisontale retningen

# Bruker en ny variabel for å unngå navnekonflikt
var movement_velocity = Vector2.ZERO

func _physics_process(delta):
	player_movement(delta)
	# Utfør bevegelsen med riktig hastighetsvektor
	velocity = movement_velocity  # Setter innebygd velocity til vår beregnede vektor
	move_and_slide()  # Utfører bevegelsen

func player():
	pass

func player_movement(delta):
	movement_velocity = Vector2.ZERO  # Resetter hastighetsvektoren

	# Håndter input
	if Input.is_action_pressed("ui_right"):
		movement_velocity.x = speed
		current_dir = "right"
		last_horizontal_dir = "right"
	elif Input.is_action_pressed("ui_left"):
		movement_velocity.x = -speed
		current_dir = "left"
		last_horizontal_dir = "left"

	if Input.is_action_pressed("ui_down"):
		movement_velocity.y = speed
		current_dir = "down"
	elif Input.is_action_pressed("ui_up"):
		movement_velocity.y = -speed
		current_dir = "up"

	# Normaliser hastighetsvektoren hvis diagonal bevegelse er nødvendig
	if movement_velocity.length() > 0:
		movement_velocity = movement_velocity.normalized() * speed

	# Spill av animasjon basert på bevegelse
	if movement_velocity != Vector2.ZERO:
		play_anim(1, last_horizontal_dir)
	else:
		play_anim(0, last_horizontal_dir)

func play_anim(movement, direction):
	var anim = $AnimatedSprite2D

	anim.flip_h = direction == "left"  # Flip sprite hvis retningen er venstre
	if movement == 1: 
		anim.play("run")
	elif movement == 0:
		anim.play("idle")
