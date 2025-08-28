extends ICropState
class_name CropPlantedState

func enter() -> void:
	# Make the seed stage visible.
	crop_bed.crop_component.visible = true
	crop_bed.apply_billboard_stage(crop_bed.crop_resource, CropBed.Stage.Seed)
	# Immediately transition to growing. This state exists for logical clarity
	# and could be expanded later (e.g., to require watering before growing).
	machine.change_state(&"growing")
