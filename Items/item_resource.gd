extends Resource
class_name ItemResource


@export var item_id:String
@export var display_name:String
@export var tags:Array[ItemTag.Tag]
@export_multiline var description:String
@export var icon: Texture2D
@export var stack_size:int = 99
