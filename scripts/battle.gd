extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $HUD
@onready var units_container: Node2D = $Units
@onready var props_container: Node2D = $Props
@onready var terrain_container: Node2D = $Terrain

var selected_units: Array[Node2D] = []
var is_box_selecting: bool = false
var box_start_pos: Vector2 = Vector2.ZERO
var box_current_pos: Vector2 = Vector2.ZERO

var total_soviet_initial: int = 12
var total_german_initial: int = 12
var is_game_over: bool = false

func _ready() -> void:
	hud.select_all_pressed.connect(_on_select_all)
	hud.zoom_in_pressed.connect(func(): camera.change_zoom(0.15))
	hud.zoom_out_pressed.connect(func(): camera.change_zoom(-0.15))
	hud.restart_pressed.connect(_on_restart)
	hud.exit_to_menu_pressed.connect(_on_exit_to_menu)
	
	if GameManager.is_new_game or not GameManager.saved_battle_data:
		_setup_new_battle()
	else:
		_load_saved_battle(GameManager.saved_battle_data)
		
	_update_unit_counts()

func _setup_new_battle() -> void:
	var soviet_squad = [
		{"type": "officer", "pos": Vector2(350, 950)},
		{"type": "rifle",   "pos": Vector2(420, 850)},
		{"type": "rifle",   "pos": Vector2(420, 1050)},
		{"type": "rifle",   "pos": Vector2(300, 750)},
		{"type": "rifle",   "pos": Vector2(300, 1150)},
		{"type": "smg",     "pos": Vector2(500, 880)},
		{"type": "smg",     "pos": Vector2(500, 1020)},
		{"type": "smg",     "pos": Vector2(460, 780)},
		{"type": "smg",     "pos": Vector2(460, 1120)},
		{"type": "mg",      "pos": Vector2(380, 700)},
		{"type": "mg",      "pos": Vector2(380, 1200)},
		{"type": "officer", "pos": Vector2(250, 950)}
	]
	for s in soviet_squad:
		_spawn_unit("soviet", s["type"], s["pos"])
		
	var german_squad = [
		{"type": "officer", "pos": Vector2(2850, 950)},
		{"type": "rifle",   "pos": Vector2(2780, 850)},
		{"type": "rifle",   "pos": Vector2(2780, 1050)},
		{"type": "rifle",   "pos": Vector2(2900, 750)},
		{"type": "rifle",   "pos": Vector2(2900, 1150)},
		{"type": "smg",     "pos": Vector2(2700, 880)},
		{"type": "smg",     "pos": Vector2(2700, 1020)},
		{"type": "smg",     "pos": Vector2(2740, 780)},
		{"type": "smg",     "pos": Vector2(2740, 1120)},
		{"type": "mg",      "pos": Vector2(2820, 700)},
		{"type": "mg",      "pos": Vector2(2820, 1200)},
		{"type": "officer", "pos": Vector2(2950, 950)}
	]
	for g in german_squad:
		_spawn_unit("german", g["type"], g["pos"])
		
	camera.position = Vector2(500, 950)

func _spawn_unit(faction: String, unit_type: String, pos: Vector2) -> Node2D:
	var unit_scene = preload("res://scenes/unit.tscn")
	var u = unit_scene.instantiate()
	u.faction = faction
	u.unit_type = unit_type
	u.global_position = pos
	units_container.add_child(u)
	u.unit_died.connect(_on_unit_died)
	return u

func _on_unit_died(_unit: Node2D) -> void:
	_update_unit_counts()
	_check_game_over()
	_auto_save()

func _update_unit_counts() -> void:
	var soviet_cnt = 0
	var german_cnt = 0
	var units = get_tree().get_nodes_in_group("units")
	for u in units:
		if u.is_alive:
			if u.faction == "soviet":
				soviet_cnt += 1
			else:
				german_cnt += 1
	hud.update_counts(soviet_cnt, german_cnt)

func _check_game_over() -> void:
	if is_game_over:
		return
	var soviet_cnt = 0
	var german_cnt = 0
	var units = get_tree().get_nodes_in_group("units")
	for u in units:
		if u.is_alive:
			if u.faction == "soviet":
				soviet_cnt += 1
			else:
				german_cnt += 1
				
	if german_cnt == 0:
		is_game_over = true
		GameManager.clear_save()
		hud.show_game_over(true, total_soviet_initial - soviet_cnt, total_german_initial)
	elif soviet_cnt == 0:
		is_game_over = true
		GameManager.clear_save()
		hud.show_game_over(false, total_soviet_initial, total_german_initial - german_cnt)

func _unhandled_input(event: InputEvent) -> void:
	if is_game_over or get_tree().paused:
		return
		
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var world_pos = get_global_mouse_position()
			if event.pressed:
				box_start_pos = world_pos
				box_current_pos = world_pos
				is_box_selecting = true
			else:
				is_box_selecting = false
				queue_redraw()
				var dist = box_start_pos.distance_to(world_pos)
				if dist < 15.0:
					_handle_single_tap(world_pos)
				else:
					_handle_box_selection(box_start_pos, world_pos)
					
	elif event is InputEventMouseMotion and is_box_selecting:
		box_current_pos = get_global_mouse_position()
		queue_redraw()

func _handle_single_tap(tap_pos: Vector2) -> void:
	var clicked_unit: Node2D = null
	var units = get_tree().get_nodes_in_group("units")
	for u in units:
		if u.is_alive and u.global_position.distance_to(tap_pos) < 32.0:
			clicked_unit = u
			break
			
	if clicked_unit:
		if clicked_unit.faction == "soviet":
			_select_single_unit(clicked_unit)
		elif clicked_unit.faction == "german" and selected_units.size() > 0:
			SoundManager.play_sound("order")
			for u in selected_units:
				u.current_target = clicked_unit
				u.move_to(clicked_unit.global_position)
	else:
		if selected_units.size() > 0:
			SoundManager.play_sound("order")
			_spawn_order_ring(tap_pos)
			_move_selected_formation(tap_pos)

func _select_single_unit(unit: Node2D) -> void:
	_clear_selection()
	selected_units.append(unit)
	unit.set_selected(true)
	hud.update_selection_info(selected_units)

func _handle_box_selection(p1: Vector2, p2: Vector2) -> void:
	var rect = Rect2(p1, Vector2.ZERO).expand(p2)
	_clear_selection()
	
	var units = get_tree().get_nodes_in_group("units")
	for u in units:
		if u.is_alive and u.faction == "soviet" and rect.has_point(u.global_position):
			selected_units.append(u)
			u.set_selected(true)
			
	hud.update_selection_info(selected_units)

func _on_select_all() -> void:
	_clear_selection()
	var units = get_tree().get_nodes_in_group("units")
	for u in units:
		if u.is_alive and u.faction == "soviet":
			selected_units.append(u)
			u.set_selected(true)
	hud.update_selection_info(selected_units)

func _clear_selection() -> void:
	for u in selected_units:
		if is_instance_valid(u):
			u.set_selected(false)
	selected_units.clear()
	hud.update_selection_info(selected_units)

func _move_selected_formation(dest: Vector2) -> void:
	var count = selected_units.size()
	if count == 1:
		selected_units[0].move_to(dest)
		return
		
	var cols = int(ceil(sqrt(count)))
	var spacing = 45.0
	for i in range(count):
		var row = i / cols
		var col = i % cols
		var offset = Vector2((col - cols * 0.5) * spacing, (row - cols * 0.5) * spacing)
		selected_units[i].move_to(dest + offset)

func _spawn_order_ring(pos: Vector2) -> void:
	var fx = preload("res://scenes/fx.tscn").instantiate()
	add_child(fx)
	fx.global_position = pos
	fx.setup_fx("order_ring", 0.5)

func _draw() -> void:
	if is_box_selecting:
		var rect = Rect2(box_start_pos, box_current_pos - box_start_pos)
		draw_rect(rect, Color(0.2, 0.9, 0.2, 0.18), true)
		draw_rect(rect, Color(0.3, 1.0, 0.3, 0.8), false, 2.0)

func _auto_save() -> void:
	if is_game_over:
		return
	var data = {
		"cam_x": camera.position.x,
		"cam_y": camera.position.y,
		"zoom": camera.zoom.x,
		"units": []
	}
	for u in units_container.get_children():
		if u.has_method("get_save_data"):
			data["units"].append(u.get_save_data())
	GameManager.save_battle_state(data)

func _load_saved_battle(data: Dictionary) -> void:
	camera.position = Vector2(data.get("cam_x", 600), data.get("cam_y", 1000))
	var z = data.get("zoom", 1.0)
	camera.zoom = Vector2(z, z)
	
	for child in units_container.get_children():
		child.queue_free()
		
	var unit_scene = preload("res://scenes/unit.tscn")
	for u_data in data.get("units", []):
		var u = unit_scene.instantiate()
		units_container.add_child(u)
		u.load_save_data(u_data)
		u.unit_died.connect(_on_unit_died)

func _on_restart() -> void:
	get_tree().paused = false
	GameManager.start_new_game()

func _on_exit_to_menu() -> void:
	get_tree().paused = false
	if not is_game_over:
		_auto_save()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
