extends Node
class_name StateMachine


var current_state:State
var states := {}

@onready var root_entity:CharacterBody3D = owner

func _ready():
	states["Idle"] = $Idle
	states["Walk"] = $Walk
	states["Sprint"] = $Sprint
	states["Airbourne"] = $Airbourne

	for state in states.values():
		state.set_root(root_entity)
		
	change_state.call_deferred("Idle")



func change_state(state: String):
	if current_state:
		current_state.exit()
	current_state = states.get(state)
	if current_state:
		current_state.enter()

func update(delta: float):
	if current_state:
		current_state.update(delta)

func handle_input(event: InputEvent):
	if current_state:
		current_state.handle_input(event)
