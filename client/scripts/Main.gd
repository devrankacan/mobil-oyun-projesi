extends Node2D

## Renders the arena: all players (as circles) and food pellets, driven by
## state snapshots pushed from NetworkManager. No client-side prediction yet —
## position is whatever the server last reported.

var players_state: Array = []
var food_state: Array = []

const PLAYER_COLOR := Color(0.2, 0.7, 1.0)
const SELF_COLOR := Color(1.0, 0.6, 0.1)
const FOOD_COLOR := Color(0.3, 0.9, 0.4)

@onready var joystick: Node = $TouchJoystick
@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	NetworkManager.state_received.connect(_on_state_received)
	NetworkManager.connect_to_server("Player%d" % (randi() % 10000))

func _on_state_received(players: Array, food: Array) -> void:
	players_state = players
	food_state = food
	for p in players_state:
		if p.id == NetworkManager.your_id and p.alive:
			camera.position = Vector2(p.pos.x, p.pos.y)
			break
	queue_redraw()

func _process(_delta: float) -> void:
	var dir: Vector2 = joystick.get_direction()
	NetworkManager.send_input(dir.x, dir.y)

func _draw() -> void:
	for f in food_state:
		var pos: Vector2 = Vector2(f.pos.x, f.pos.y)
		draw_circle(pos, 5.0, FOOD_COLOR)

	for p in players_state:
		if not p.alive:
			continue
		var pos: Vector2 = Vector2(p.pos.x, p.pos.y)
		var color := SELF_COLOR if p.id == NetworkManager.your_id else PLAYER_COLOR
		draw_circle(pos, float(p.size), color)
