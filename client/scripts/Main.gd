extends Node2D

## Renders the arena: all players (as circles) and food pellets, driven by
## state snapshots pushed from NetworkManager. No client-side prediction yet —
## position is whatever the server last reported.

const ARENA_WIDTH := 2000.0
const ARENA_HEIGHT := 2000.0

const PLAYER_COLOR := Color(0.2, 0.7, 1.0)
const SELF_COLOR := Color(1.0, 0.6, 0.1)
const FOOD_COLOR := Color(0.3, 0.9, 0.4)
const BOUNDARY_COLOR := Color(0.9, 0.2, 0.3)
const BACKGROUND_COLOR := Color(0.12, 0.13, 0.16)

var players_state: Array = []
var food_state: Array = []
var _was_alive := true

@onready var joystick: Node = $TouchJoystick
@onready var camera: Camera2D = $Camera2D
@onready var start_screen: Control = $UI/StartScreen
@onready var hud: Control = $UI/HUD
@onready var size_label: Label = $UI/HUD/SizeLabel
@onready var death_screen: Control = $UI/DeathScreen

func _ready() -> void:
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	NetworkManager.state_received.connect(_on_state_received)
	NetworkManager.disconnected.connect(_on_disconnected)
	start_screen.play_pressed.connect(_on_play_pressed)

func _on_play_pressed(player_name: String) -> void:
	joystick.mouse_filter = Control.MOUSE_FILTER_STOP
	start_screen.visible = false
	hud.visible = true
	NetworkManager.connect_to_server(player_name)

func _on_disconnected() -> void:
	hud.visible = false
	start_screen.visible = true
	start_screen.show_error("Bağlantı koptu, tekrar dene.")

func _on_state_received(players: Array, food: Array) -> void:
	players_state = players
	food_state = food

	var found_self := false
	for p in players_state:
		if p.id == NetworkManager.your_id:
			found_self = true
			if p.alive:
				camera.position = Vector2(p.pos.x, p.pos.y)
				size_label.text = "Boy: %d" % int(p.size)
				if not _was_alive:
					death_screen.visible = false
				_was_alive = true
			else:
				if _was_alive:
					death_screen.visible = true
				_was_alive = false
			break

	if not found_self:
		death_screen.visible = false

	queue_redraw()

func _process(_delta: float) -> void:
	if start_screen.visible:
		return
	var dir: Vector2 = joystick.get_direction()
	NetworkManager.send_input(dir.x, dir.y)

func _draw() -> void:
	draw_rect(Rect2(0, 0, ARENA_WIDTH, ARENA_HEIGHT), BACKGROUND_COLOR, true)
	draw_rect(Rect2(0, 0, ARENA_WIDTH, ARENA_HEIGHT), BOUNDARY_COLOR, false, 6.0)

	for f in food_state:
		var pos: Vector2 = Vector2(f.pos.x, f.pos.y)
		draw_circle(pos, 5.0, FOOD_COLOR)

	for p in players_state:
		if not p.alive:
			continue
		var pos: Vector2 = Vector2(p.pos.x, p.pos.y)
		var is_self: bool = p.id == NetworkManager.your_id
		var color := SELF_COLOR if is_self else _color_for_id(p.id)
		draw_circle(pos, float(p.size), color)
		var label_pos := pos + Vector2(0, -float(p.size) - 12.0)
		draw_string(ThemeDB.fallback_font, label_pos, p.name, HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color.WHITE)

func _color_for_id(id: String) -> Color:
	var h := hash(id)
	return Color.from_hsv(float(h % 360) / 360.0, 0.6, 0.85)
