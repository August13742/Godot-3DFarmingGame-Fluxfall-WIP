class_name ICropState extends RefCounted

var machine: CropStateMachine
var crop_bed: CropBed

func enter() -> void: pass
func exit() -> void: pass
func on_growth_tick() -> void: pass
func on_hydrate() -> void: pass
func on_plant(_new_crop_resource: BillboardPlantResource) -> void: pass
func on_harvest() -> void: pass
func on_new_day() -> void: pass
