extends ICropState
class_name CropHarvestableState

func enter() -> void:
	crop_bed.monitoring = true

func on_harvest() -> void:
	machine.change_state(&"empty")
