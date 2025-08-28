extends RefCounted
class_name CropStateMachine

var context: CropBed
var current_state: ICropState
var states: Dictionary = {}

func initialise(ctx: CropBed) -> void:
	self.context = ctx
	self.states = {
		&"empty": CropEmptyState.new(),
		&"planted": CropPlantedState.new(),
		&"growing": CropGrowingState.new(),
		&"harvestable": CropHarvestableState.new()
	}
	for state_key in states:
		states[state_key].machine = self
		states[state_key].crop_bed = self.context

	change_state(&"empty")

func change_state(state_key: StringName) -> void:
	if not states.has(state_key):
		printerr("CropStateMachine: Attempted to transition to unknown state '%s'" % state_key)
		return
	if current_state:
		current_state.exit()
	current_state = states[state_key]
	current_state.enter()

# --- Delegate all events to the current state ---
func on_growth_tick() -> void: current_state.on_growth_tick()
func on_hydrate() -> void: current_state.on_hydrate()
func on_plant(resource: BillboardPlantResource) -> void: current_state.on_plant(resource)
func on_harvest() -> void: current_state.on_harvest()
func on_new_day() -> void: current_state.on_new_day()
