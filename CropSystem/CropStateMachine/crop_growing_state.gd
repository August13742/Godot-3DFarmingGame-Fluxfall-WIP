extends ICropState
class_name CropGrowingState

	
	
func on_growth_tick() -> void:
	if not crop_bed.hydrated:
		return # Or add withering logic

	if randf() < crop_bed.growth_chance:
		crop_bed.current_calculation_stage += 1
		var target_stage_index = clamp(
			floori(crop_bed.current_calculation_stage / float(crop_bed.stages_per_visual_change)),
			0, CropBed.Stage.Harvestable
			)

		if target_stage_index != crop_bed.current_stage as int:
			crop_bed.current_stage = target_stage_index as CropBed.Stage
			crop_bed.apply_billboard_stage(crop_bed.crop_resource, crop_bed.current_stage)

		if crop_bed.current_stage == CropBed.Stage.Harvestable:
			machine.change_state(&"harvestable")
