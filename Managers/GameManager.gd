extends Node
## Singleton 'GameManager'

@export var main_camera: Camera3D
@export var follow_cam: ThirdPersonObserverCamera
@export var debug_board: DebugTaskboard
@export var player_menu := preload("uid://q81mp7mnrdap")
var player_menu_scene: CanvasItem

var _debug_visible := false
var ui_layer: CanvasLayer
var hud_node: Control
var _ui_modals := {}   # tag -> true
var crosshair_ui:Control
func _enter_tree() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
func _ready() -> void:
	ui_layer = get_tree().get_first_node_in_group(&"ui_layer")
	var hud_controller:Node = ui_layer.find_child("HUDController")
	hud_node = hud_controller.get_child(0)
	crosshair_ui = hud_node.find_child("Crosshair")
	
	debug_board = ui_layer.find_child("DebugTaskboard")
	if is_instance_valid(debug_board):
		debug_board.focus_camera = Callable(self, "focus_camera")
	_use_main_camera()
	_apply_ui_block_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	# Handle temporary cursor visibility override
	if event.is_action_pressed("force_show_cursor"):
		# Force the cursor to be visible, overriding the current state
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_released("force_show_cursor"):
		# When the key is released, let the main state function determine the correct mode
		_apply_ui_block_state()
		
	if event.is_action_pressed("set_camera_1"):
		_use_main_camera()
	elif event.is_action_pressed("set_camera_2"):
		_use_follow_camera()

	if event.is_action_pressed("open_debug_interface"):
		_toggle_debug()

	if event.is_action_pressed("open_inventory"):
		if player_menu_scene == null:
			player_menu_scene = player_menu.instantiate()
			ui_layer.add_child(player_menu_scene)
			get_tree().paused = true
			_begin_ui_modal("inventory")
		else:
			get_tree().paused = false
			if is_instance_valid(player_menu_scene):
				player_menu_scene.queue_free()
			player_menu_scene = null
			_end_ui_modal("inventory")

	if event.is_action_pressed("ui_cancel"):
		var ui_was_open := is_ui_blocking()
		if ui_was_open:
			# Close player menu if it's open
			if is_instance_valid(player_menu_scene):
				player_menu_scene.queue_free()
				player_menu_scene = null
			
			# Close debug menu if it's open
			if _debug_visible:
				_debug_visible = false
				if is_instance_valid(debug_board):
					debug_board.visible = false
			
			_ui_modals.clear()
			get_tree().paused = false
			
			# Re-evaluate the UI and mouse state
			_apply_ui_block_state()

# Public for cameras/UI
func is_ui_blocking() -> bool:
	return _ui_modals.size() > 0

# Called by the debug board via Callable
func focus_camera(target: Variant) -> void:
	_use_follow_camera()
	follow_cam.focus_on(target, true)

func _use_main_camera() -> void:
	if main_camera:
		main_camera.current = true
	if follow_cam:
		follow_cam.enable(false)
	hud_node.visible = true
	_apply_ui_block_state()

func _use_follow_camera() -> void:
	if follow_cam and follow_cam.camera:
		follow_cam.enable(true)
		follow_cam.camera.current = true
		hud_node.visible = false
	_apply_ui_block_state()

func _toggle_debug() -> void:
	_debug_visible = not _debug_visible
	if is_instance_valid(debug_board):
		debug_board.visible = _debug_visible
	if _debug_visible:
		_begin_ui_modal("debug")
	else:
		_end_ui_modal("debug")
func set_reticle_obstructed(is_action_obstructed:bool)->void:
	if is_action_obstructed:
		crosshair_ui.modulate = Color.DARK_RED
	else:
		crosshair_ui.modulate = Color.WHITE
		
# --- UI gate helpers ---
func _begin_ui_modal(tag: String) -> void:
	_ui_modals[tag] = true
	_apply_ui_block_state()

func _end_ui_modal(tag: String) -> void:
	_ui_modals.erase(tag)
	_apply_ui_block_state()

func _apply_ui_block_state() -> void:
	# Mouse mode
	if is_ui_blocking():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		var using_follow := follow_cam and follow_cam.camera and follow_cam.camera.current
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if using_follow else Input.MOUSE_MODE_VISIBLE
