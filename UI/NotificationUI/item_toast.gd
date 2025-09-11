extends PanelContainer
class_name ItemToast

@onready var item_icon: TextureRect = $MarginContainer/HBoxContainer/ItemIcon
@onready var message_label: Label = $MarginContainer/HBoxContainer/MessageLabel

@export var in_ms := 0.2
@export var out_ms := 0.2

var _alive := false
signal finished

func start(text:String, icon:Texture2D, hold_s:float):
	_alive = true
	item_icon.texture = icon
	message_label.text = text
	_play(in_ms, hold_s, out_ms)

func _play(in_d:float, hold:float, out_d:float) -> void:
	modulate.a = 0.0
	position.x += 16
	var t = get_tree().create_tween(); t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(self, "modulate:a", 1.0, in_d).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(self, "position:x", position.x - 16, in_d)
	await t.finished
	if not _alive: return
	await get_tree().create_timer(hold,true).timeout
	if not _alive: return
	var t2 = get_tree().create_tween(); t2.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t2.tween_property(self, "modulate:a", 0.0, out_d).set_trans(Tween.TRANS_QUAD)
	await t2.finished
	_alive = false
	finished.emit()

func cancel_now():
	if not _alive: return
	_alive = false
	visible = false
	emit_signal("finished") # manager will recycle
