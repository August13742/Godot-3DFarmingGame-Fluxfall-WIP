extends Control


@onready var content_slot:TextureRect = $%Content
@onready var content_margin_container:MarginContainer = $%ContentMargin
@onready var panel:TextureRect = $%Panel

func _ready() -> void:
	_late_init.call_deferred()

func _late_init()->void:
	content_margin_container.rotation_degrees = -(self.rotation_degrees + 45)
	print("Self rotation:", self.rotation, " | Compensation:", -(self.rotation + 45))
