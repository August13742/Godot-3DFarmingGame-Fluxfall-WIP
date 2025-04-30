extends State
class_name IdleState

var player: CharacterBody3D

func enter():
	player = owner.root_entity
	player.velocity.x = 0
	player.velocity.z = 0



	player.animation_player.call_deferred("play", "Idle")
	if player.state_machine_debug:
		print("[Debug/States]: Entering IDLE")


func update(_delta:float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() > 0:
		if Input.is_action_pressed("sprint"):
			owner.change_state("Sprint")
		else:
			owner.change_state("Walk")
	elif !player.is_on_floor():
		owner.change_state("Airbourne")

func handle_input(_event:InputEvent): pass
func exit(): pass
