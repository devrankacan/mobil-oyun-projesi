extends Control

signal play_pressed(player_name: String)

@onready var name_edit: LineEdit = $CenterContainer/VBoxContainer/NameEdit
@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	name_edit.text_submitted.connect(func(_t): _on_play_pressed())

func _on_play_pressed() -> void:
	var player_name := name_edit.text.strip_edges()
	if player_name.is_empty():
		player_name = "Oyuncu%d" % (randi() % 10000)
	play_button.disabled = true
	status_label.text = "Bağlanıyor..."
	play_pressed.emit(player_name)

func show_error(message: String) -> void:
	play_button.disabled = false
	status_label.text = message
