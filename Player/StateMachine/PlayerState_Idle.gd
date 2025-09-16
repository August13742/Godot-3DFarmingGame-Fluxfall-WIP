class_name PlayerState_Idle extends PlayerStateBase

func enter() -> void:
	root.velocity.x = 0.0
	root.velocity.z = 0.0
	if animator:
		animator.travel(&"Idle")

func update(_delta: float) -> void:
	var input_dir: Vector2 = (root as PlayerController).current_input_direction
	if not root.is_on_floor():
		machine.change_state(PlayerStateMachine.StateKey.Airborne); return
	if input_dir.length() > 0.0:
		if Input.is_action_pressed("sprint"):
			machine.change_state(PlayerStateMachine.StateKey.Sprint)
		else:
			machine.change_state(PlayerStateMachine.StateKey.Walk)

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and can_jump():
		jump()
