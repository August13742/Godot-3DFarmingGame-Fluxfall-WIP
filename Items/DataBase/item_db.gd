## AUTO-GENERATED FILE. DO NOT EDIT.
class_name ItemDB

enum Keys {
	NULL,
	Rope,
	Pickaxe,
	Plant,
	Stick,
	Stone,
}

const ITEM_IDS: Dictionary = {
	Keys.NULL: null,
	Keys.Rope:"rope",
	Keys.Pickaxe:"pickaxe",
	Keys.Plant:"plant",
	Keys.Stick:"stick",
	Keys.Stone:"stone",
}

const PATHS: Dictionary = {
	"rope": "res://Items/Resources/Craftables/tests1_resource.tres",
	"pickaxe": "res://Items/Resources/Craftables/tests2_resource.tres",
	"plant": "res://Items/Resources/plant_resource.tres",
	"stick": "res://Items/Resources/stick_resource.tres",
	"stone": "res://Items/Resources/stone_resource.tres",
}

const CRAFTABLES: Dictionary = {
	"rope": PATHS["rope"],
	"pickaxe": PATHS["pickaxe"],
}
