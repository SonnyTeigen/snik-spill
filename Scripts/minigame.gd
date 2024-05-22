extends Control

var correct_numbers
var current_numbers
var press_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	make_code()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if current_numbers == correct_numbers:
		Global.jail_puzzle_solved = true
	if press_count > 3:
		make_code()
		current_numbers = null
		$NinePatchRect/Label2.text = ""
		press_count = 0

func make_code():
	var rand_number1 = str(randi_range(1,9))
	var rand_number2 = str(randi_range(1,9))
	var rand_number3 = str(randi_range(1,9))
	var rand_number4 = str(randi_range(1,9))
	correct_numbers = rand_number1+rand_number2+rand_number3+rand_number4
	$NinePatchRect/Label.text = "Current code is "+correct_numbers

func current_typed_numbers(number):
	if current_numbers == null:
		current_numbers = str(number)
	else:
		current_numbers += str(number)
	$NinePatchRect/Label2.text = current_numbers
	

func _on_button_1_pressed():
	current_typed_numbers(1)
	press_count += 1

func _on_button_2_pressed():
	current_typed_numbers(2)
	press_count += 1

func _on_button_3_pressed():
	current_typed_numbers(3)
	press_count += 1

func _on_button_4_pressed():
	current_typed_numbers(4)
	press_count += 1

func _on_button_5_pressed():
	current_typed_numbers(5)
	press_count += 1

func _on_button_6_pressed():
	current_typed_numbers(6)
	press_count += 1

func _on_button_7_pressed():
	current_typed_numbers(7)
	press_count += 1

func _on_button_8_pressed():
	current_typed_numbers(8)
	press_count += 1

func _on_button_9_pressed():
	current_typed_numbers(9)
	press_count += 1
