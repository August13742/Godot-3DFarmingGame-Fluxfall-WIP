class_name State
## enter, update, exit(delta), handle_input(event)


extends Node

#var blocked_actions: Set[String] = {}
var root_entity:Node3D

func enter():
	pass

func update(_delta: float):
	pass

func exit():
	pass

func handle_input(_event: InputEvent):
	if _event.is_action_pressed("jump"):
		if can_jump():
			jump()
			
			
			
func can_jump() -> bool:
	return true  # default: all states can jump
	
#func handle_input(event: InputEvent) -> void:
	#if event is InputEventAction and not blocked_actions.has(event.action):
		#match event.action:
			#"jump":
				#jump()
			#"sprint":
				#start_sprint()
				
func jump():
	root_entity.velocity.y = root_entity.jump_force
	root_entity.state_machine.change_state("Airbourne")

func set_root(entity: Node3D) -> void:
	root_entity = entity
