extends ItemResource
class_name CraftableResource


#@export var item_id:String
#@export var display_name:String
#@export_multiline var description:String
#@export var icon: Texture2D
#@export var stack_size:int = 99


@export var required_material:Dictionary[ItemDB.Keys,int]
