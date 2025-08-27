extends State
class_name IdleState


func enter():

	root_entity.velocity.x = 0
	root_entity.velocity.z = 0
	state_machine_animator.travel(&"Idle")
	


func update(_delta:float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() > 0:
		if Input.is_action_pressed("sprint"):

			owner.change_state(StateMachine.Sprint)
		else:
			owner.change_state(StateMachine.Walk)
	if !root_entity.is_on_floor():
		owner.change_state(StateMachine.Airbourne)





func exit(): pass
