class_name DebugTaskboard extends Control

@export var refresh_interval: float = 0.5
@export var focus_camera: Callable

@onready var tabs: TabContainer = $VBoxContainer/TabContainer
@onready var tree_pending: Tree = $VBoxContainer/TabContainer/Pending
@onready var tree_active: Tree = $VBoxContainer/TabContainer/Active
@onready var tree_agents: Tree = $VBoxContainer/TabContainer/Agents
@onready var btn_focus: Button = $VBoxContainer/HBoxContainer/FocusBtn
@onready var btn_requeue: Button = $VBoxContainer/HBoxContainer/RequeueBtn
@onready var btn_cancel: Button = $VBoxContainer/HBoxContainer/CancelBtn
@onready var btn_refresh: Button = $VBoxContainer/HBoxContainer/RefreshBtn
@onready var cb_auto: CheckBox = $VBoxContainer/HBoxContainer/AutoRefresh

var _btn_agent_inv: Button
var _selected_meta: Dictionary = {}
var _inv_window: Window
var _last_selection: Dictionary = {}  # {"type":"job/agent","job_id":int,"agent_id":int}

var _dirty := true
var _timer := 0.0

func _ready() -> void:
	_configure_trees()
	_connect_signals()
	_refresh.call_deferred()

	btn_refresh.pressed.connect(_refresh)
	btn_focus.pressed.connect(_on_focus)
	btn_requeue.pressed.connect(_on_requeue)
	btn_cancel.pressed.connect(_on_cancel)

	# Add Agent Inv button to the same toolbar
	_btn_agent_inv = Button.new()
	_btn_agent_inv.text = "Agent Inv"
	_btn_agent_inv.tooltip_text = "Show selected agent's inventory"
	_btn_agent_inv.disabled = true
	$VBoxContainer/HBoxContainer.add_child(_btn_agent_inv)
	_btn_agent_inv.pressed.connect(_on_show_agent_inventory)
	tree_pending.item_selected.connect(_on_any_selection_changed)
	tree_active.item_selected.connect(_on_any_selection_changed)
	tree_agents.item_selected.connect(_on_any_selection_changed)
	# Tab change can affect toolbar state even without a new click
	tabs.tab_changed.connect(func(_i): _on_any_selection_changed())

func _process(delta: float) -> void:
	if cb_auto and not cb_auto.button_pressed: return
	_timer += delta
	if _timer >= refresh_interval or _dirty:
		_timer = 0
		_refresh()
		_dirty = false

func _configure_trees() -> void:
	for t in [tree_pending, tree_active, tree_agents]:
		t.hide_root = true
		t.select_mode = Tree.SELECT_ROW
		t.column_titles_visible = true

	_set_cols(tree_pending, ["JobID","Template","Prio","Target","Pos"])
	_set_cols(tree_active,  ["JobID","Template","Prio","Status","Agent","Target","Bindings","Pos/Dist"])
	_set_cols(tree_agents,  ["AgentID","State","Pos","Notes"])

func _set_cols(tree: Tree, names: Array[String]) -> void:
	tree.columns = max(1, names.size())
	tree.column_titles_visible = true
	var _root := tree.create_item()
	for i in names.size():
		tree.set_column_title(i, names[i])

func _connect_signals() -> void:
	if not NPCJobBoard: return
	# Prefer fine-grained events; fall back to a generic "lists changed"
	if "job_lists_changed" in NPCJobBoard:
		NPCJobBoard.job_lists_changed.connect(func(): _dirty = true)
	# NPCEventSystem events
	if Engine.has_singleton("NPCEventSystem"):
		var bus = Engine.get_singleton("NPCEventSystem")
		for sig in ["job_opportunity_created","job_assigned","job_task_completed","job_finished"]:
			if bus.has_signal(sig):
				bus.connect(sig, func(_a=null,_b=null,_c=null,_d=null): _dirty = true)

func _refresh() -> void:
	if not NPCJobBoard: return

	# --- capture ---
	var prev: Dictionary = _last_selection if _selected_meta.is_empty() else _selected_meta
	prev = {} if prev.is_empty() else prev.duplicate(true)

	# --- rebuild Pending ---
	tree_pending.clear()
	_set_cols(tree_pending, ["JobID","Template","Prio","Target","Pos"])
	var root_p: TreeItem = tree_pending.create_item()
	var pending_jobs: Array = NPCJobBoard.get_pending_jobs()
	# Sort by priority (desc), then ID (asc)
	pending_jobs.sort_custom(func(a: JobInstance, b: JobInstance) -> bool:
		if a.priority != b.priority:
			return a.priority > b.priority
		else:
			return a.unique_id < b.unique_id
	)
	for j: JobInstance in pending_jobs:
		var it: TreeItem = tree_pending.create_item(root_p)
		_fill_job_row_pending(it, j)
	tree_pending.set_column_expand_ratio(3, 5) # Target tab gets a bit more space

	# --- rebuild Active ---
	tree_active.clear()
	_set_cols(tree_active, ["JobID","Template","Prio","Status","Agent","Target","Bindings","Pos/Dist"])
	var root_a: TreeItem = tree_active.create_item()
	var active_jobs: Array = NPCJobBoard.get_active_jobs()
	# Sort by priority (desc), then ID (asc)
	active_jobs.sort_custom(func(a: JobInstance, b: JobInstance) -> bool:
		if a.priority != b.priority:
			return a.priority > b.priority
		else:
			return a.unique_id < b.unique_id
	)
	for j: JobInstance in active_jobs:
		var it: TreeItem = tree_active.create_item(root_a)
		_fill_job_row_active(it, j)

	# --- rebuild Agents ---
	tree_agents.clear()
	_set_cols(tree_agents, ["AgentID","State","Pos","Notes"])
	var root_ag: TreeItem = tree_agents.create_item()
	var all_agents: Array = NPCJobBoard.get_all_agents()
	all_agents.sort_custom(func(a: WorkerAgent, b: WorkerAgent) -> bool: return a.worker_id < b.worker_id)
	for ag: WorkerAgent in all_agents:
		var it: TreeItem = tree_agents.create_item(root_ag)
		_fill_agent_row(it, ag)


	_restore_selection(prev)
	# If nothing restored, clear selected meta so toolbar disables cleanly
	_selected_meta = _get_selected_meta()
	_update_toolbar_state()


func _fill_job_row_pending(it: TreeItem, j: JobInstance) -> void:
	it.set_text(0, str(j.unique_id))
	it.set_text(1, j.template_name())
	it.set_text(2, str(j.priority))
	it.set_text(3, String(j.target_path))
	it.set_text(4, _format_vector3(j.target_pos))
	it.set_metadata(0, {
		&"type":"job", &"job_id": j.unique_id, &"active": false,
		&"agent_id": -1, &"target_pos": j.target_pos
	})

func _fill_job_row_active(it: TreeItem, j: JobInstance) -> void:
	var status_names = ["Pending","Active","Complete","Failed"]
	it.set_text(0, str(j.unique_id))
	it.set_text(1, j.template_name())
	it.set_text(2, str(j.priority))
	it.set_text(3, status_names[int(j.status)])
	it.set_text(4, str(j.assigned_agent_id) if j.assigned_agent_id >= 0 else "-")
	it.set_text(5, String(j.target_path))
	it.set_text(6, j.binding_summary())

	var pos_s := _format_vector3(j.target_pos)
	var ag: WorkerAgent = NPCJobBoard.get_agent(j.assigned_agent_id)
	if ag:
		var d := sqrt(ag.global_position.distance_squared_to(j.target_pos))
		pos_s = "%s | d=%.2f" % [pos_s, d]
	it.set_text(7, pos_s)

	it.set_metadata(0, {
		&"type":"job", &"job_id": j.unique_id, &"active": true,
		&"agent_id": j.assigned_agent_id, &"target_pos": j.target_pos
	})

func _fill_agent_row(it: TreeItem, ag: WorkerAgent) -> void:
	var s := NPCJobBoard.get_agent_status(ag.worker_id)

	var s_txt :String = "Idle" if s == NPCJobBoard.AgentStatus.Idle \
	else "Active" if s == NPCJobBoard.AgentStatus.Active else "Unknown"

	it.set_text(0, str(ag.worker_id))
	it.set_text(1, s_txt)
	it.set_text(2, _format_vector3(ag.global_position))
	var jid := NPCJobBoard.get_agent_job(ag.worker_id)
	it.set_text(3, &"Job " + str(jid) if jid >= 0 else "")
	it.set_metadata(0, { &"type":&"agent", &"agent_id": ag.worker_id })


func _update_toolbar_state() -> void:
	var inv_ok := false
	if not _selected_meta.is_empty():
		if _selected_meta.get(&"type") == &"agent" and _selected_meta.get(&"agent_id", -1) >= 0:
			inv_ok = true
		elif _selected_meta.get(&"type") == &"job" and _selected_meta.get(&"active", false) and _selected_meta.get(&"agent_id", -1) >= 0:
			inv_ok = true
	_btn_agent_inv.disabled = not inv_ok

func _on_any_selection_changed() -> void:
	_selected_meta = _get_selected_meta()
	_last_selection = _last_selection if _selected_meta.is_empty() else _selected_meta.duplicate(true)
	_update_toolbar_state()

func _capture_selection() -> Dictionary:
	var item :TreeItem= _current_tree().get_selected()
	if not item: return {}
	var meta :Dictionary = item.get_metadata(0)
	return meta.duplicate(true)

func _restore_selection(prev: Dictionary) -> void:
	if prev.is_empty(): return
	var _t: Tree = null
	var ok := false
	if prev.get(&"type") == &"job":
		var id:int = prev.get(&"job_id", -1)
		if id >= 0:
			ok = _select_job_in_tree(tree_active, id)
			if not ok:
				ok = _select_job_in_tree(tree_pending, id)
	elif prev.get(&"type") == &"agent":
		var aid:int = prev.get(&"agent_id", -1)
		if aid >= 0:
			ok = _select_agent_in_tree(tree_agents, aid)
	if ok:
		_selected_meta = _get_selected_meta()
		_update_toolbar_state()

func _select_job_in_tree(tree: Tree, job_id: int) -> bool:
	return _select_by_predicate(tree, func(item: TreeItem) -> bool:
		var md: Variant = item.get_metadata(0)
		if not (md is Dictionary):
			return false
		var t: Variant = md.get(&"type")
		var is_job: bool = (t == &"job")
		return is_job and int(md.get(&"job_id", -1)) == job_id
	)

func _select_agent_in_tree(tree: Tree, agent_id: int) -> bool:
	return _select_by_predicate(tree, func(item: TreeItem) -> bool:
		var md: Variant = item.get_metadata(0)
		if not (md is Dictionary):
			return false
		var t: Variant = md.get(&"type")
		var is_agent: bool = (t == &"agent")
		return is_agent and int(md.get(&"agent_id", -1)) == agent_id
	)

func _select_by_predicate(tree: Tree, pred: Callable) -> bool:
	var root: TreeItem = tree.get_root()
	if root == null:
		return false
	return _walk_and_select(tree, root.get_first_child(), pred)


func _walk_and_select(tree: Tree, it: TreeItem, pred: Callable) -> bool:
	var cur: TreeItem = it
	while cur != null:
		if bool(pred.call(cur)):
			cur.select(0)
			tree.scroll_to_item(cur)
			return true
		var child: TreeItem = cur.get_first_child()
		if child != null and _walk_and_select(tree, child, pred):
			return true
		cur = cur.get_next()
	return false

func _on_focus() -> void:
	var meta = _get_selected_meta()
	if meta.is_empty(): return
	if not focus_camera.is_valid(): return

	if meta.get(&"type") == &"job":
		if meta.get(&"active") and meta.get(&"agent_id") >= 0:
			var ag:WorkerAgent = NPCJobBoard.get_agent(meta.get(&"agent_id"))
			if ag: focus_camera.call(ag)  # Node3D
		else:
			focus_camera.call(meta.get(&"target_pos"))   # Vector3
	elif meta.get(&"type") == &"agent":
		var ag:WorkerAgent = NPCJobBoard.get_agent(meta.get(&"agent_id"))
		if ag: focus_camera.call(ag)

func _on_requeue() -> void:
	var meta = _get_selected_meta()
	if meta.is_empty() or meta.get(&"type") != &"job": return
	if meta.get(&"active"):
		if "debug_requeue" in NPCJobBoard:
			if NPCJobBoard.debug_requeue(meta.get(&"job_id")):
				_dirty = true

func _on_cancel() -> void:
	var meta = _get_selected_meta()
	if meta.is_empty() or meta.get(&"type") != "job": return
	if "debug_cancel" in NPCJobBoard:
		if NPCJobBoard.debug_cancel(meta.get(&"job_id")):
			_dirty = true

func _on_show_agent_inventory() -> void:
	# Toggle if already open
	if _inv_window and _inv_window.visible:
		_on_inv_close()
		return

	if _selected_meta.is_empty(): return
	var agent_id := -1
	if _selected_meta.get(&"type") == &"agent":
		agent_id = _selected_meta.get(&"agent_id")
	elif _selected_meta.get(&"type") == &"job" and _selected_meta.get(&"active"):
		agent_id = _selected_meta.get(&"agent_id")
	if agent_id < 0: return

	var ag: WorkerAgent = NPCJobBoard.get_agent(agent_id)
	if not ag:
		push_warning("Agent not found: %s" % agent_id)
		return

	var inv: InventoryComponent = InventoryManager.get_inventory(ag)
	if not inv:
		_show_text_popup("Agent %s has no InventoryComponent." % agent_id, "Agent Inventory")
		return

	_show_inventory_popup(inv, "Agent %s Inventory" % agent_id)

func _show_text_popup(text: String, title: String = "Info") -> void:
	if not _inv_window:
		_inv_window = Window.new()
		_inv_window.size = Vector2i(420, 320)
		add_child(_inv_window)
	_inv_window.title = title
	_inv_window.popup_centered()
	_inv_window.call_deferred(&"move_to_foreground")

	_inv_window.get_children().map(func(c): c.queue_free())
	var rt := RichTextLabel.new()
	rt.fit_content = true
	rt.bbcode_enabled = false
	rt.text = text
	rt.scroll_active = true
	rt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inv_window.add_child(rt)

func _show_inventory_popup(inv: InventoryComponent, title: String) -> void:
	_ensure_inv_window()

	# clear old content
	for c in _inv_window.get_children():
		c.queue_free()

	_inv_window.title = title
	_inv_window.popup_centered()
	_inv_window.call_deferred(&"move_to_foreground")

	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override(&"margin_left", 10)
	root.add_theme_constant_override(&"margin_right", 10)
	root.add_theme_constant_override(&"margin_top", 10)
	root.add_theme_constant_override(&"margin_bottom", 10)
	_inv_window.add_child(root)

	var tree := Tree.new()
	tree.hide_root = true
	tree.columns = 3
	tree.column_titles_visible = true
	tree.set_column_title(0, "Slot")
	tree.set_column_title(1, "ID")
	tree.set_column_title(2, "Count")
	for i in tree.columns:
		tree.set_column_expand(i, true)
		tree.set_column_custom_minimum_width(i, 80)
	tree.set_column_expand_ratio(1, 2)
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(tree)

	var root_item := tree.create_item()
	for i in inv.inventory.size():
		var slot := inv.inventory[i]
		if slot == null or slot.is_empty():
			continue
		var it := tree.create_item(root_item)
		var item_id: StringName = slot.item_instance.id
		it.set_text(0, str(i))
		it.set_text(1, String(item_id))
		it.set_text(2, str(slot.item_instance.count))


func _ensure_inv_window() -> void:
	if _inv_window: return
	_inv_window = Window.new()
	_inv_window.size = Vector2i(600, 420)
	_inv_window.min_size = Vector2i(420, 260)
	_inv_window.unresizable = false
	_inv_window.always_on_top = true
	_inv_window.title = "Inventory"

	# X button, Alt+F4, etc.
	_inv_window.close_requested.connect(_on_inv_close)


	add_child(_inv_window)

func _on_inv_close() -> void:
	if _inv_window:
		_inv_window.hide()


func _get_selected_meta() -> Dictionary:
	var t: Tree = _current_tree()
	if t == null:
		return {}
	var item: TreeItem = t.get_selected()
	if item == null:
		return {}
	var md: Variant = item.get_metadata(0)
	return md if (md is Dictionary) else {}

func _current_tree() -> Tree:
	var idx := tabs.current_tab
	match idx:
		0: return tree_pending
		1: return tree_active
		2: return tree_agents
		_: return null

func _format_vector3(v: Vector3) -> String:
	return "(%.2f, %.2f, %.2f)" % [v.x, v.y, v.z]
