extends Node

## Singleton (autoload) that owns the WebSocket connection to the game server.
## Game scenes read `players` and `food` each frame instead of touching the socket directly.

signal connected
signal disconnected
signal state_received(players: Array, food: Array)

const SERVER_URL := "ws://158.220.115.16:7777/ws"

var socket := WebSocketPeer.new()
var your_id: String = ""
var _connecting := false

func connect_to_server(player_name: String) -> void:
	var url := "%s?name=%s" % [SERVER_URL, player_name.uri_encode()]
	var err := socket.connect_to_url(url)
	if err != OK:
		push_error("WebSocket connect failed: %s" % err)
		return
	_connecting = true

func send_input(dx: float, dy: float) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	var msg := {"type": "input", "dx": dx, "dy": dy}
	socket.send_text(JSON.stringify(msg))

func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN and _connecting:
		_connecting = false
		connected.emit()

	if state == WebSocketPeer.STATE_CLOSED:
		if _connecting or not your_id.is_empty():
			_connecting = false
			your_id = ""
			disconnected.emit()
		return

	while socket.get_available_packet_count() > 0:
		var packet := socket.get_packet().get_string_from_utf8()
		_handle_message(packet)

func _handle_message(text: String) -> void:
	var json := JSON.new()
	if json.parse(text) != OK:
		return
	var data: Dictionary = json.data
	match data.get("type", ""):
		"welcome":
			your_id = data.get("your_id", "")
		"state":
			state_received.emit(data.get("players", []), data.get("food", []))
