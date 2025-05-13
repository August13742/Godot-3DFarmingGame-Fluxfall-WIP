extends State
class_name IdleState



func enter():

	root_entity.velocity.x = 0
	root_entity.velocity.z = 0

	var current_animation:String = animation_player.current_animation if animation_player != null else ""
	if current_animation != "":
		if animation_player.get_animation(current_animation).loop_mode == 1:
			animation_player.play("Idle",0.5)
		else:
			animation_player.queue("Idle")
	else:
		animation_player.call_deferred("play", "Idle",0.5)
	#(animation_player as AnimationPlayer).play(StateMachine.Idle,1.0)
	if root_entity.state_machine_debug:
		print("[Debug/States]: Entering IDLE")


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
