extends Control

@onready var play_button = $ContentLayer/CenterContainer/ContentBox/MarginContainer/ButtonsVBox/PlayButton
@onready var option_button = $ContentLayer/CenterContainer/ContentBox/MarginContainer/ButtonsVBox/OptionButton
@onready var credit_button = $ContentLayer/CenterContainer/ContentBox/MarginContainer/ButtonsVBox/CreditButton

var TEX_NORMAL: Texture2D
var TEX_HOVER: Texture2D

func _ready() -> void:
	TEX_NORMAL = load("res://Button.png")
	TEX_HOVER = load("res://assets/hover_frame.png")
	
	play_button.pressed.connect(_on_play_pressed)
	
	play_button.text = "Play"
	option_button.text = "Option"
	credit_button.text = "Kredit"
	
	var brown_color := Color("#422300")
	for btn in [play_button, option_button, credit_button]:
		# Set a permanent font color for all states to prevent flickering/turning white
		btn.add_theme_color_override("font_color", brown_color)
		btn.add_theme_color_override("font_hover_color", brown_color)
		btn.add_theme_color_override("font_pressed_color", brown_color)
		btn.add_theme_color_override("font_focus_color", brown_color)
		_setup_button_hover(btn)

func _setup_button_hover(btn: Button) -> void:
	btn.mouse_entered.connect(func(): _set_button_texture(btn, TEX_HOVER))
	btn.mouse_exited.connect(func(): _set_button_texture(btn, TEX_NORMAL))

func _set_button_texture(btn: Button, tex: Texture2D) -> void:
	# Duplicate the style to avoid affecting other buttons if they share the same resource
	var style = btn.get_theme_stylebox("normal").duplicate()
	if style is StyleBoxTexture:
		style.texture = tex
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_stylebox_override("focus", style)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Main.tscn")
