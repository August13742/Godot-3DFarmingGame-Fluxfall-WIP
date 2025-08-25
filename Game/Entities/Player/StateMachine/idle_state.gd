extends State
class_name IdleState


@onready var locomotion_blend: AnimationTree = $"../../VisualControl/Mannequin/LocomotionBlend"


func enter():

	root_entity.velocity.x = 0
	root_entity.velocity.z = 0

	#var current_animation:String = animation_player.current_animation if animation_player != null else ""
	#if current_animation == "Jump_Land":
			#animation_player.queue("Idle")
	#else:
		#animation_player.play("Idle",0.5)
	##(animation_player as AnimationPlayer).play(StateMachine.Idle,1.0)
	#if root_entity.state_machine_debug:
		#print("[Debug/States]: Entering IDLE")
	var anim_tween:Tween = create_tween()
	anim_tween.tween_method(
		func(val:float):
			locomotion_blend.set(&"parameters/blend_position",val),
			locomotion_blend.get(&"parameters/blend_position"),
			-1.,.25)


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
