class_name ActionContext extends RefCounted

var agent:WorkerAgent
var inventory:InventoryComponent
var job: JobInstance
var binding_key: StringName = &""
var item_id: StringName = &""
var amount:int = 0
var item_template: ItemResource
var capability_script: Script
