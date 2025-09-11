extends Control
class_name ItemToastManager

@onready var toast_container: VBoxContainer = $ToastContainer
@export var toast_scene:PackedScene = preload("uid://cm61nq1l7oqsg")

@export_range(1,5,1) var max_visible:int = 3
@export var lifetimes := {0:2.0, 1:2.5, 2:3.0, 3:4.0} ##severity:lifetime_sec 
@export var rate_min_gap_ms:= 120
@export var coalesce_window_sec:float = .25 ## same toasts within window are merged

var _queue:Array[Dictionary] = []
var _active: Array[ItemToast] = []
var _pool:Array[ItemToast] = []
var _last_ms:int = 0
var _pending_by_key := {}# key -> { 
# total_qty:int, last_ms:int, item_name:String, severity:int, icon:CompressedTexture2D }

func _enter_tree() -> void:
	if NotificationSystem && "item_toast_manager" in NotificationSystem :
		NotificationSystem.item_toast_manager = self
	self.process_mode = Node.PROCESS_MODE_ALWAYS

func post(item_name:String, quantity:int, severity:=1, icon:CompressedTexture2D=null, key:StringName=&""):
	var now := Time.get_ticks_msec()
	# Always coalesce keyed loot within window.
	if key != StringName(""):
		_register_pending(key, item_name, quantity, severity, icon, now)
		return

	if now - _last_ms < rate_min_gap_ms:
		return
	_last_ms = now
	var message := "%s × %d" % [item_name, quantity]
	_queue.append({ &"text": message, &"severity": severity, &"icon": icon, &"key": key })
	_try_spawn()


func _register_pending(key:StringName, item_name:String, quantity:int, sev:int, icon:CompressedTexture2D, stamp:int) -> void:
	var slot = _pending_by_key.get(key)
	if slot == null:
		slot = {&"total_qty": 0, &"item_name": item_name, &"severity": sev, &"icon": icon}
		_pending_by_key[key] = slot
	
	slot[&"total_qty"] += quantity
	slot[&"last_ms"] = stamp
	_pending_by_key[key] = slot# redundant if slot is a reference (Dictionary), but explicit for clarity.
	
func _process(_delta: float) -> void:
	if _pending_by_key.is_empty():
		return

	var now_ms := Time.get_ticks_msec()
	var coalesce_window_ms := int(coalesce_window_sec * 1000)
	
	# Iterate over a copy of the keys, as we will be modifying the dictionary.
	for key in _pending_by_key.keys():
		var slot = _pending_by_key.get(key)
		if now_ms - slot[&"last_ms"] > coalesce_window_ms:
			# This slot has expired, flush
			var msg_text := "%s × %d" % [slot[&"item_name"], slot[&"total_qty"]]
			var msg := {
				&"text": msg_text,
				&"severity": slot[&"severity"],
				&"icon": slot[&"icon"],
				&"key": key
			}
			_queue.append(msg)
			_pending_by_key.erase(key)
			_try_spawn() # Attempt to show the new toast immediately.


func _try_spawn():
	while _queue.size() > 0 and _active.size() < max_visible:
		var data = _queue.pop_front()
		var entry := _get_entry()
		_active.append(entry)
		toast_container.add_child(entry)
		var toast_lifetime :float= lifetimes.get(data.severity, 2.0)
		entry.start(data.text, data.icon, toast_lifetime)
		entry.finished.connect(_on_entry_finished.bind(entry), CONNECT_ONE_SHOT)

func _on_entry_finished(entry: ItemToast):
	if is_instance_valid(entry):
		_active.erase(entry)
		_recycle(entry)
	_try_spawn()

func _get_entry() -> ItemToast:
	if _pool.size() > 0:
		return _pool.pop_back()
	return toast_scene.instantiate()

func _recycle(e: ItemToast):
	toast_container.remove_child(e)
	_pool.append(e)

func clear_all():
	for e in _active:
		e.cancel_now()
	_active.clear()
	_queue.clear()
	_pending_by_key.clear()
