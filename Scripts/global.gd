extends Node

var save_scene = "World"
var current_scene = "world"
var transition_scene = false
var transition_to_jai_scene = false

var player_exit_store_posx = 85
var player_exit_store_posy = 312
var player_exit_jail_posx = 502
var player_exit_jail_posy = 207
var player_exit_roof_posx = 370
var player_exit_roof_posy = 120
var player_start_posx = 2567
var player_start_posy = 261
var player_start_jail_posx = 420
var player_start_jail_posy = 330


var store_exit_id = 0


# Variabel for å holde styr på koffertstatus
var has_case = false

var jail_puzzle_solved = false
var game_first_loading = true
var menu_open = true
var intro_played = false
var world_convo_played = false
var store_convo_played = false
var jail_convo_played = false

func finish_changescenes():
	if transition_scene == true:
		transition_scene = false
		if current_scene =="world":
			current_scene = "store"
			save_scene = "Store"
		else:
			save_scene = "World"
			current_scene = "world"
	if transition_to_jai_scene == true:
		transition_to_jai_scene = false
		current_scene = "jail"
		save_scene = "Jail"

func set_case_status(status: bool):
	has_case = status

func get_case_status() -> bool:
	return has_case
