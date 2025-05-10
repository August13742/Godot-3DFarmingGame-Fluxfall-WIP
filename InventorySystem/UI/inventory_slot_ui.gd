extends TextureRect
class_name InventorySlotUI


@onready var slot_texture = $%ItemIcon.texture
@onready var slot_counter_label:Label = $%Counter

var connected_inventory_slot:InventorySlot = null
