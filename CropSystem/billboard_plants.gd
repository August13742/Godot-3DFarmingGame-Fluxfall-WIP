extends Node3D
class_name BillboardPlant

@export var billboard_resource:BillboardPlantResource

@onready var imposter_mesh: MeshInstance3D = $Visuals/ImposterMesh

func _late_init()->void:
	if owner.crop_resource == null:
		printerr("Crop Bed target is null")
