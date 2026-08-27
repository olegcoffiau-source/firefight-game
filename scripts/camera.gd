extends Camera2D

@export var pan_speed: float = 600.0
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0

var map_bounds: Rect2 = Rect2(0, 0, 3200, 2000)
var is_dragging: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_cam_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	zoom = Vector2(1.0, 1.0)
	position = Vector2(600, 1000)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE or (event.button_index == MOUSE_BUTTON_RIGHT):
			if event.pressed:
				is_dragging = true
				drag_start_mouse_pos = event.position
				drag_start_cam_pos = position
			else:
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			change_zoom(0.1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			change_zoom(-0.1, event.position)
			
	elif event is InputEventMouseMotion and is_dragging:
		var delta_pos = (event.position - drag_start_mouse_pos) / zoom.x
		position = drag_start_cam_pos - delta_pos
		_clamp_camera()

func change_zoom(amount: float, screen_center: Vector2 = Vector2.ZERO) -> void:
	var new_zoom = clamp(zoom.x + amount, min_zoom, max_zoom)
	zoom = Vector2(new_zoom, new_zoom)
	_clamp_camera()

func _clamp_camera() -> void:
	var viewport_size = get_viewport_rect().size / zoom.x
	var half_w = viewport_size.x * 0.5
	var half_h = viewport_size.y * 0.5
	
	position.x = clamp(position.x, map_bounds.position.x + half_w, map_bounds.end.x - half_w)
	position.y = clamp(position.y, map_bounds.position.y + half_h, map_bounds.end.y - half_h)
