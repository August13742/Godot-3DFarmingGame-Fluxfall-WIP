extends ICropState
class_name CropEmptyState

func enter() -> void:
	# Reset all relevant properties on the context.
	crop_bed.crop_component.visible = false
	crop_bed.crop_resource = null
	crop_bed.current_calculation_stage = 0
	crop_bed.current_stage = CropBed.Stage.Seed
	crop_bed.harvest_collision.disabled = true
	crop_bed.hydration_component.collision_on()

func on_plant(new_crop_resource: BillboardPlantResource) -> void:
	if new_crop_resource:
		crop_bed.crop_resource = new_crop_resource
		crop_bed.crop_component.crop_resource = new_crop_resource
		machine.change_state(&"planted")
