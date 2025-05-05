extends State
class_name IdleState

#var player: CharacterBody3D

func enter():
	root_entity = owner.root_entity
	root_entity.velocity.x = 0
	root_entity.velocity.z = 0

	var current_animation:String = root_entity.animation_player.current_animation
	if current_animation != "":
		if root_entity.animation_player.get_animation(current_animation).loop_mode == 1:
			root_entity.animation_player.play("Idle",0.5)
		else:
			root_entity.animation_player.queue("Idle")
	else:
		root_entity.animation_player.call_deferred("play", "Idle",0.5)
	#(root_entity.animation_player as AnimationPlayer).play("Idle",1.0)
	if root_entity.state_machine_debug:
		print("[Debug/States]: Entering IDLE")


func update(_delta:float):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir.length() > 0:
		if Input.is_action_pressed("sprint"):
			
			owner.change_state("Sprint")
		else:
			owner.change_state("Walk")
	if !root_entity.is_on_floor():
		owner.change_state("Airbourne")
		




		
		
#func handle_input(_event:InputEvent):
	#pass

func exit(): pass
