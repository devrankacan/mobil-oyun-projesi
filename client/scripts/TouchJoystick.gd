extends Control

## Virtual joystick for mobile: drag anywhere within this control to set a
## direction vector, capped to length 1. Returns to zero on release.

const MAX_RADIUS := 100.0

var _active := false
var _origin := Vector2.ZERO
var _direction := Vector2.ZERO

func get_direction() -> Vector2:
	return _direction

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_active = true
			_origin = event.position
			_direction = Vector2.ZERO
		else:
			_active = false
			_direction = Vector2.ZERO
		queue_redraw()
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and _active:
		var offset: Vector2 = event.position - _origin
		_direction = offset.limit_length(MAX_RADIUS) / MAX_RADIUS
		queue_redraw()

func _draw() -> void:
	if not _active:
		return
	draw_circle(_origin, MAX_RADIUS, Color(1, 1, 1, 0.15))
	draw_circle(_origin + _direction * MAX_RADIUS, 30.0, Color(1, 1, 1, 0.35))
