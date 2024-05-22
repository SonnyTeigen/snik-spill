extends CharacterBody2D
#Dette er siste versjon!
# Eksporterer en variabel for å holde en referanse til en Path2D-node
@export var patrol_path: Path2D
@export var player: Node2D

@onready var inner_vision_cone = $InnerVisionCone
@onready var outer_vision_cone = $OuterVisionCone
@onready var agent: NavigationAgent2D = $NavigationAgent2D
var agent2: NavigationAgent2D
@onready var agentReg = $"../NavigationRegion2D"

# Signaler
signal guard_alerted(location)
signal guard_down(location)
signal chase_state_changed(is_in_chase)

# Tilstander
enum States { PATROL_PATH, PATROL_FREE, CHASE, SUSPICIOUS, MOVE_TO_LAST_SEEN, LOOK_AROUND, BLIND_CHASE, RETURN_TO_PATH }
var original_state = States.PATROL_PATH  # Holder styr på den opprinnelige tilstanden hvis den endres
var state = States.PATROL_FREE

# Variabel for å lagre den siste retningen og kontrollere "peilingen"
var peil_angle = 0
var peil_direction = 1
var max_peil_angle = 0.5  # Maksimal peilevinkel i radianer

# Patruljeinnstillinger
var patrol_speed = 20.0
var chase_speed = 60.0
var free_patrol_direction = Vector2.ZERO

# Spillerreferanse og Synsdeteksjon
var player_ref: Node
var player_in_vision_cone = false
var raycast_target_detected = false
var start_position = Vector2()

var smooth_direction = Vector2()

var look_around_phase = 0

var look_around_duration = 5.0  # Standard varighet
var blind_chase_speed_factor = 1.5
var direction_change_count = 0  # Teller for retningsskifter
# Variabler for å spore om spilleren er oppdaget
var is_player_detected = false

# Path for patruljering
var path_follow: PathFollow2D

# Legg til variabler for å holde styr på siste observert posisjon
var last_seen_position = Vector2()
var suspicious_timer = Timer.new()
var search_timer = Timer.new()
var update_timer = Timer.new()

var look_around_timer = Timer.new()
var blind_chase_timer = Timer.new()  # Timer for hvor lenge blind chase varer
var continue_chase_timer = Timer.new()
var patrol_free_pause_timer = Timer.new()

# Definerer standardvinkler for synskegler i radianer
var default_outer_cone_angle = deg_to_rad(90)  # 90 grader
var default_inner_cone_angle = deg_to_rad(45)  # 45 grader


# Initialisering
func _ready():
	Global.intro_played = true
	# Initialiser synskeglene med standardvinkler
	if $OuterVisionCone:
		$OuterVisionCone.set("angle", default_outer_cone_angle)
	if $InnerVisionCone:
		$InnerVisionCone.set("angle", default_inner_cone_angle)
	
	agent = get_node("NavigationAgent2D")
	agent.max_speed = chase_speed
	add_to_group("guards")
	player_ref = get_node("/root/"+ Global.save_scene+"/Player")
	
	if patrol_path:
		path_follow = patrol_path.get_child(0) as PathFollow2D
		if path_follow:
			start_position = path_follow.global_position
			print("Patruljerute og følger satt opp.")
			change_state(States.PATROL_PATH)
			update_animations_and_sounds()
		else:
			print("PathFollow2D ikke funnet under angitt Path2D.")
	else:
		print("Ingen patruljerute satt. Vakten vil bruke fri patruljering.")
	
	# Opprette og konfigurere timer for suspicious pause og search
	add_child(suspicious_timer)
	suspicious_timer.wait_time = 2.0
	suspicious_timer.one_shot = true
	suspicious_timer.connect("timeout", Callable(self, "_on_suspicious_timeout"))
	
	add_child(search_timer)
	search_timer.wait_time = 5.0
	search_timer.one_shot = true
	search_timer.connect("timeout", Callable(self, "_on_search_timeout"))
	
	add_child(look_around_timer)
	look_around_timer.wait_time = 5.0
	look_around_timer.one_shot = true
	look_around_timer.connect("timeout", Callable(self, "_on_look_around_timeout"))
	
	add_child(blind_chase_timer)
	blind_chase_timer.wait_time = 10.0
	blind_chase_timer.one_shot = true
	blind_chase_timer.connect("timeout", Callable(self, "_on_blind_chase_timeout"))
	
	add_child(continue_chase_timer)
	continue_chase_timer.wait_time = 7.0
	continue_chase_timer.one_shot = true
	continue_chase_timer.connect("timeout", Callable(self, "_on_continue_chase_timeout"))

	
	patrol_free_pause_timer.wait_time = 3.0  # Pause på 3 sekunder
	patrol_free_pause_timer.one_shot = true
	add_child(patrol_free_pause_timer)
	
	$OuterVisionCone.connect("body_entered", Callable(self, "_on_body_entered_outer_vision_cone"))
	$OuterVisionCone.connect("body_exited", Callable(self, "_on_body_exited_outer_vision_cone"))
	$InnerVisionCone.connect("body_entered", Callable(self, "_on_body_entered_inner_vision_cone"))

func _physics_process(delta: float) -> void:
	var dir = to_local(agent.get_next_path_position()).normalized()
	velocity = dir * chase_speed
	match state:
		States.PATROL_FREE:
			patrol_free(delta)
		States.PATROL_PATH:
			follow_path(delta)
		States.CHASE:
			chase_player(delta)
		States.SUSPICIOUS:
			pass # foreløpig placeholder
		States.MOVE_TO_LAST_SEEN:
			move_towards_last_seen_position()
		States.LOOK_AROUND:
			perform_look_around()
		States.BLIND_CHASE:
			perform_blind_chase(delta)
		States.RETURN_TO_PATH:
			return_to_original_path()
	
	move_and_slide()
	
	update_vision()
	
	if is_player_detected:
		update_last_seen_position()
		if state == States.SUSPICIOUS:
			move_towards_last_seen_position()
		elif state != States.CHASE and state != States.SUSPICIOUS:
			change_state(States.SUSPICIOUS)
		continue_chase_timer.stop()
	elif state == States.CHASE and not is_player_detected:
		if continue_chase_timer.is_stopped():
			continue_chase_timer.start()
	
	update_animations_and_sounds()
	update_outer_vision_cone()

func _process(delta):
	player_to_jail()

func player_to_jail():
	if Global.transition_to_jai_scene == true:
		get_tree().change_scene_to_file("res://Scenes/jail.tscn")
		Global.game_first_loading = false
		Global.finish_changescenes()

func play_footstep_sound():
	if !$FootstepSound.playing:
		$FootstepSound.play()

func stop_footstep_sound():
	if $FootstepSound.playing:
		$FootstepSound.stop()

# Patruljeringslogikk
func patrol_free(delta):
	if free_patrol_direction.length() == 0 or randf() < 0.01 or patrol_free_pause_timer.is_stopped() or agent.velocity.length() < 0.1:
		# Bestem en ny retning når agenten nesten har stoppet
		direction_change_count += 1
		if direction_change_count % 3 == 0:
			patrol_free_pause_timer.start()
			agent.velocity = Vector2.ZERO
		else:
			free_patrol_direction = Vector2(randi() % 2, randi() % 2) * 100 * (1 if randf() > 0.5 else -1)
			var random_position = global_position + free_patrol_direction
			agent.set_target_position(random_position)
			agent.velocity = free_patrol_direction.normalized() * patrol_speed
	update_vision()  # Oppdater synet


func follow_path(delta):
	if path_follow:
		path_follow.progress += patrol_speed * delta
		var current_position = global_position
		var target_position = path_follow.global_position
		agent.set_target_position(target_position)
		velocity = (target_position - current_position).normalized() * patrol_speed
		agent.velocity = velocity
		

func chase_player(delta: float):
	agent.set_target_position(player.global_position)
	agent.max_speed = chase_speed
	agent.velocity = player.global_position - global_position
	if agent.is_target_reached():
		print("Target reached")

# Syns- og deteksjonshåndtering
func update_outer_vision_cone():
	var query_parameters = PhysicsRayQueryParameters2D.new()
	query_parameters.from = global_position
	query_parameters.to = player_ref.global_position
	query_parameters.exclude = [self]
	query_parameters.collision_mask = 1 | 1 << 2

	var result = get_world_2d().direct_space_state.intersect_ray(query_parameters)
	var raycast_target_detected = result and result.collider == player_ref

	player_in_vision_cone = player_ref in $OuterVisionCone.get_overlapping_bodies()
	is_player_detected = player_in_vision_cone and raycast_target_detected

	if is_player_detected:
		if state != States.CHASE and state != States.SUSPICIOUS:
			change_state(States.SUSPICIOUS)
	elif state == States.CHASE and not is_player_detected:
		last_seen_position = player_ref.global_position
		if continue_chase_timer.is_stopped():
			continue_chase_timer.start()

	if $OuterVisionCone:
		$OuterVisionCone.set("angle", default_outer_cone_angle)
	if $InnerVisionCone:
		$InnerVisionCone.set("angle", default_inner_cone_angle)

func _on_body_entered_outer_vision_cone(body):
	if body == player_ref and state != States.CHASE:
		var query_parameters = PhysicsRayQueryParameters2D.new()
		query_parameters.from = global_position
		query_parameters.to = player_ref.global_position
		query_parameters.exclude = [self]
		query_parameters.collision_mask = 1 | 1 << 2

		var result = get_world_2d().direct_space_state.intersect_ray(query_parameters)
		if result and result.collider == player_ref:
			last_seen_position = body.global_position
			change_state(States.SUSPICIOUS)

func _on_body_entered_inner_vision_cone(body):
	if body == player_ref:
		var query_parameters = PhysicsRayQueryParameters2D.new()
		query_parameters.from = global_position
		query_parameters.to = player_ref.global_position
		query_parameters.exclude = [self]
		query_parameters.collision_mask = 1 | 1 << 2

		var result = get_world_2d().direct_space_state.intersect_ray(query_parameters)
		if result and result.collider == player_ref:
			change_state(States.CHASE)

func _on_search_timeout():
	if state == States.SUSPICIOUS:
		change_state(States.PATROL_PATH)

func _on_suspicious_timeout():
	if state == States.SUSPICIOUS:
		print("Suspicious timeout, moving to last seen position")
		move_towards_last_seen_position()

func _on_look_around_timeout():
	print("Done looking around.")
	if original_state == States.PATROL_PATH and not is_player_detected:
		change_state(States.RETURN_TO_PATH)
		print("Returning to original patrol path 2.")
	else:
		state = States.PATROL_FREE
		print("Returning to patrol.")

func _on_blind_chase_timeout():
	print("Blind chase timeout reached.")
	if original_state == States.PATROL_PATH and not is_player_detected:
		change_state(States.RETURN_TO_PATH)
		print("No longer detecting player, returning to original patrol path.")
	else:
		change_state(States.PATROL_FREE)
		print("Returning to free patrol.")

func _on_continue_chase_timeout():
	print("Continued chase period ended.")
	if not is_player_detected:
		change_state(States.BLIND_CHASE)
		print("Player lost, entering blind chase.")
		blind_chase_timer.start()
	else:
		state = States.CHASE

# Suspicious pause før bevegelse mot siste observerte punkt
func move_towards_last_seen_position():
	if suspicious_timer.is_stopped():
		# Start suspicious pause
		print("Starting suspicious pause")
		velocity = Vector2.ZERO  # Stopp vakten
		if state != States.SUSPICIOUS:
			change_state(States.SUSPICIOUS)
		suspicious_timer.start()
	else:
		# Når timeren er ferdig, beveg mot siste observerte punkt
		agent.set_target_position(last_seen_position)
		agent.max_speed = patrol_speed
		if agent.is_target_reached():
			change_state(States.LOOK_AROUND)
			look_around_timer.start()
			print("Reached last seen position. Starting to look around.")

func perform_look_around():
	if player_nearby():
		look_around_duration = 3.0
	else:
		look_around_duration = 5.0

	look_around_timer.start(look_around_duration)
	look_around_phase += 1
	var angles = [0.5, -1.0, 0.5, 0]

	if look_around_phase < angles.size():
		var target_angle = angles[look_around_phase]
		$OuterVisionCone.rotation += target_angle
		$InnerVisionCone.rotation += target_angle
		if $RayCast2D:
			$RayCast2D.rotation += target_angle
	else:
		look_around_phase = 0
		change_state(States.PATROL_FREE)
		print("Look around complete. Returning to patrol.")

func perform_blind_chase(delta):
	if randf() < 0.05:
		var random_direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()
		var random_position = global_position + random_direction * 100  # Doblet rekkevidde til 100
		agent.set_target_position(random_position)
		agent.velocity = random_direction * blind_chase_speed_factor * chase_speed  # Justert for faktisk hastighet
	
	if state == States.BLIND_CHASE and is_player_detected:
		change_state(States.CHASE)
		continue_chase_timer.stop()
	elif state == States.CHASE and not is_player_detected:
		continue_chase_timer.start()
		perform_peiling()

func player_nearby() -> bool:
	return global_position.distance_to(player_ref.global_position) < 50

func _on_body_exited_outer_vision_cone(body):
	if body == player_ref:
		print("Player exited the outer vision cone.")
		player_in_vision_cone = false
		if state == States.CHASE:
			if continue_chase_timer.is_stopped():
				print("Player lost, starting continue chase timer.")
				continue_chase_timer.start()
		else:
			print("Player lost, entering suspicious search.")
			if search_timer.is_stopped():
				search_timer.start()

func update_last_seen_position():
	last_seen_position = player_ref.global_position
	if state != States.CHASE:
		move_towards_last_seen_position()

func return_to_original_path():
	stop_all_warningsounds()
	if path_follow:
		agent.set_target_position(start_position)
		agent.max_speed = patrol_speed

		var distance_to_target = global_position.distance_to(start_position)
		
		if distance_to_target > 10:
			velocity = (start_position - global_position).normalized() * patrol_speed
			agent.velocity = velocity
			update_vision()
		else:
			global_position = start_position
			path_follow.progress = 0
			change_state(States.PATROL_PATH)
			print("Returned to original patrol path and resumed patrol.")
			update_vision()
	else:
		print("PathFollow2D is not valid.")

func reset_vision_directions():
	if agent.velocity.length() > 0:
		var new_direction = agent.velocity.normalized()
	else:
		var new_direction = Vector2.RIGHT
	update_vision()

func update_vision():
	var direction = get_current_direction()
	if direction.length() > 0.1:  # En liten terskel for å unngå spinning når hastigheten nærmer seg null
		update_cones(direction)
	if state != States.CHASE or not is_player_detected:
		perform_peiling()

func perform_peiling():
	var peil_speed = 0.01
	peil_angle += peil_speed * peil_direction
	if peil_angle > max_peil_angle or peil_angle < -max_peil_angle:
		peil_direction *= -1
	for cone in [$OuterVisionCone, $InnerVisionCone, $RayCast2D]:
		if cone:
			cone.rotation += peil_angle

func get_current_direction() -> Vector2:
	match state:
		States.PATROL_PATH:
			return get_direction_from_path()
		States.PATROL_FREE:
			return agent.velocity.normalized() if agent.velocity.length() > 0 else Vector2.ZERO
		States.CHASE:
			return agent.velocity.normalized() if agent.velocity.length() > 0 else (player_ref.global_position - global_position).normalized()
		States.BLIND_CHASE:
			return agent.velocity.normalized() if agent.velocity.length() > 0 else Vector2.ZERO
		States.MOVE_TO_LAST_SEEN:
			return (last_seen_position - global_position).normalized()
		_:
			return Vector2.RIGHT

func get_direction_from_path() -> Vector2:
	if path_follow:
		path_follow.progress += 0.01
		var next_position = path_follow.global_position
		path_follow.progress -= 0.01
		return (next_position - global_position).normalized()
	return Vector2.ZERO

func update_cones(direction: Vector2):
	if direction.length() < 0.1:  # Ignorer oppdateringer hvis retningen er for liten
		return

	var t = 0.1
	smooth_direction = smooth_direction + (direction - smooth_direction) * t

	var angle = smooth_direction.angle()
	for cone in [$OuterVisionCone, $InnerVisionCone, $RayCast2D]:
		if cone:
			cone.rotation = angle

func change_state(new_state: States):
	if state != new_state:
		
		# Hvis du går ut av CHASE tilstanden, stopp chase musikken
		if state == States.CHASE and new_state != States.CHASE:
			emit_signal("chase_state_changed", false)
		
		state = new_state
		
		if new_state == States.SUSPICIOUS:
			agent.velocity = Vector2.ZERO  # Stopp vakten
			if $SuspiciousSound.playing:
				$SuspiciousSound.stop()
			$SuspiciousSound.play()
			suspicious_timer.start()
		elif new_state == States.CHASE:
			if $ChaseSound.playing:
				$ChaseSound.stop()
			$ChaseSound.play()
			emit_signal("chase_state_changed", true)
		else:
			agent.max_speed = patrol_speed  # Gjenopprett normal hastighet for andre tilstander

func calculate_initial_direction() -> Vector2:
	var initial_position = global_position
	path_follow.offset += 1
	var next_position = path_follow.global_position
	path_follow.offset = 0
	return (next_position - initial_position).normalized()

func update_animations_and_sounds():
	var anim = $Sprite
	var moving = velocity.length() > 1

	if moving:
		anim.play("walk")
		play_footstep_sound()
	else:
		anim.play("idle")
		stop_footstep_sound()

	anim.flip_h = velocity.x > 0

	match state:
		States.CHASE:
			if not $ChaseSound.playing:
				$ChaseSound.play()
		States.SUSPICIOUS:
			if not $SuspiciousSound.playing:
				$SuspiciousSound.play()
		_:
			stop_all_warningsounds()

func stop_all_warningsounds():
	$ChaseSound.stop()
	$SuspiciousSound.stop()

func get_random_point_within_bounds():
	var x_min = -1000
	var x_max = 1000
	var y_min = -1000
	var y_max = 1000

	var random_point = Vector2(
		randf_range(x_min, x_max),
		randf_range(y_min, y_max)
	)

	return random_point


func _on_detection_area_body_entered(body):
	if body.has_method("player"):
		Global.transition_to_jai_scene = true
