extends Control

@onready var play_button = $ContentLayer/CenterContainer/ContentBox/MarginContainer/ButtonsVBox/PlayButton
@onready var option_button = $ContentLayer/CenterContainer/ContentBox/MarginContainer/ButtonsVBox/OptionButton
@onready var credit_button = $ContentLayer/CenterContainer/ContentBox/MarginContainer/ButtonsVBox/CreditButton

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	# Option dan Credit bisa diisi nanti
	
	play_button.text = "Play"
	option_button.text = "Option"
	credit_button.text = "Kredit"

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")
