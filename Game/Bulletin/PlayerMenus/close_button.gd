extends Button



func _ready() -> void:
	self.pressed.connect(_on_pressed)


func _on_pressed():
	(owner as CanvasItem).visible = false
