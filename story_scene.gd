extends Control

@onready var background_sprite: TextureRect = $Background
@onready var transition_sprite: TextureRect = $TransitionBG
@onready var dialogue_label: RichTextLabel = %DialogueLabel
@onready var name_label: Label = %NameLabel
@onready var name_frame: TextureRect = %NameFrame
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var next_button: Button = %NextButton
@onready var dialogue_container: Control = $UI/DialogueContainer
@onready var fade_overlay: ColorRect = $UI/FadeOverlay
@onready var center_frame: TextureRect = %CenterFrame
@onready var center_label: Label = %CenterLabel
@onready var ui_container: VBoxContainer = $UI/NameAndNextContainer

var story_data = [
	# SCENE 1 — The First Voice
	{
		"background": "res://assets/chapter1/c1-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter1/c1-2.png",
		"name": "",
		"text": "On a quiet night, everyone gathered in the old hall at the center of the settlement."
	},
	{
		"background": "res://assets/chapter1/c1-2.png",
		"name": "",
		"text": "In the middle of the crowd stood an elder, speaking about a world that had never been fair —"
	},
	{
		"background": "res://assets/chapter1/c1-2.png",
		"name": "",
		"text": "— about labor that never returned to the hands that created it,"
	},
	{
		"background": "res://assets/chapter1/c1-2.png",
		"name": "",
		"text": "and about a dream of finally owning their own future."
	},
	{
		"background": "res://assets/chapter1/c1-3.png",
		"name": "Elder",
		"text": "“We built all of this."
	},
	{
		"background": "res://assets/chapter1/c1-3.png",
		"name": "Elder",
		"text": "Yet we have been given the least of it."
	},
	{
		"background": "res://assets/chapter1/c1-3.png",
		"name": "Elder",
		"text": "It is time we decide our own fate.”"
	},
	{
		"background": "res://assets/chapter1/c1-4.png",
		"name": "",
		"text": "His words lit a fire that had long been buried."
	},
	# SCENE 2 — The Turning Point
	{
		"background": "res://assets/chapter2/c2-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter2/c2-2.png",
		"name": "",
		"text": "Not long after, the old order collapsed. The gates were opened, and the old signs came down,"
	},
	{
		"background": "res://assets/chapter2/c2-2.png",
		"name": "",
		"text": "and the rules no one had ever questioned were torn apart one by one."
	},
	{
		"background": "res://assets/chapter2/c2-3.png",
		"name": "The Pig",
		"text": "“Now it’s our turn.”"
	},
	{
		"background": "res://assets/chapter2/c2-4.png",
		"name": "Horsh",
		"text": "“No more speaking for us.”"
	},
	{
		"background": "res://assets/chapter2/c2-5.png",
		"name": "",
		"text": "They believed a new age had begun."
	},
	# SCENE 3 — The First Crack
	{
		"background": "res://assets/chapter3/c3-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter2/c2-2.png",
		"name": "",
		"text": "But every major change creates those who want to control its direction."
	},
	{
		"background": "res://assets/chapter2/c2-2.png",
		"name": "",
		"text": "Beneath the promise of freedom, new voices began to guide, calm, and justify everything that followed."
	},
	{
		"background": "res://assets/chapter3/c3-2.png",
		"name": "Pig Boss",
		"text": "“Order must be protected."
	},
	{
		"background": "res://assets/chapter3/c3-2.png",
		"name": "Pig Boss",
		"text": "Not everyone needs to know everything.”"
	},
	{
		"background": "res://assets/chapter3/c3-3.png",
		"name": "",
		"text": "Every decision was made to sound reasonable."
	},
	{
		"background": "res://assets/chapter3/c3-3.png",
		"name": "",
		"text": "Every doubt was answered with an explanation that felt convincing enough to accept."
	},
	# SCENE 4 — Your Role
	{
		"background": "res://assets/chapter4/c4-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter4/c4-2.png",
		"name": "",
		"text": "Now you stand inside that current."
	},
	{
		"background": "res://assets/chapter4/c4-2.png",
		"name": "",
		"text": "Not as a witness, but as the voice that shapes what others believe."
	},
	{
		"background": "res://assets/chapter4/c4-3.png",
		"name": "MicPig",
		"text": "“Listen carefully."
	},
	{
		"background": "res://assets/chapter4/c4-3.png",
		"name": "MicPig",
		"text": "We are only saying what they need to understand.”"
	},
	{
		"background": "res://assets/chapter4/c4-4.png",
		"name": "",
		"text": "Here, words are never just words."
	},
	{
		"background": "res://assets/chapter4/c4-4.png",
		"name": "",
		"text": "One small mistake can break their trust. Too many errors, and your influence begins to slip away."
	},
	# SCENE 5 — How It Works
	{
		"background": "res://assets/chapter5/c5-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter5/c5-3.png",
		"name": "",
		"text": "",
		"show_center_after": "res://assets/chapter5/c5-2-frame.png",
		"center_text": ""
	},
	# SCENE 6 — Transition to Gameplay
	#{
		#"background": "res://assets/chapter5/c5-3.png",
		#"name": "",
		#"text": "In a place like this, truth is never fixed."
	#},
	#{
		#"background": "res://assets/chapter5/c5-3.png",
		#"name": "",
		#"text": "Truth is whatever sounds convincing enough to be believed."
	#},
	{
		"background": "res://assets/chapter5/c5-3.png",
		"name": "MicPig",
		"text": "“One more time."
	},
	{
		"background": "res://assets/chapter5/c5-3.png",
		"name": "MicPig",
		"text": "We are not forcing anyone."
	},
	{
		"background": "res://assets/chapter5/c5-3.png",
		"name": "MicPig",
		"text": "We are only keeping things together.”"
	},
	{
		"background": "res://assets/chapter5/c5-3.png",
		"name": "",
		"text": "If you succeed, they will keep believing. \nAnd as long as they believe, control stays in your hands.",
		"show_center_after": "res://assets/chapter5/c5-3-frame.png",
		"is_last_slide": true
	}
]

var current_index = 0
var TEX_NORMAL: Texture2D
var TEX_HOVER: Texture2D
var is_transitioning = false
var is_showing_special = false

func _ready() -> void:
	TEX_NORMAL = load("res://Button.png")
	TEX_HOVER = load("res://assets/hover_frame.png")
	
	if next_button:
		next_button.mouse_entered.connect(_on_next_button_hover)
		next_button.mouse_exited.connect(_on_next_button_normal)
		next_button.pressed.connect(_on_next_pressed)
	
	if dialogue_label:
		dialogue_label.scroll_active = false
	
	if transition_sprite:
		transition_sprite.modulate.a = 0
	
	if center_frame:
		center_frame.visible = false
	
	display_current_step()

func display_current_step() -> void:
	if current_index >= story_data.size():
		# Slower, more gentle transition
		is_transitioning = true
		if next_button: next_button.visible = false
		var tween = create_tween()
		tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.5)
		await tween.finished
		get_tree().change_scene_to_file("res://Main.tscn")
		return
	
	is_showing_special = false
	if center_frame: center_frame.visible = false
	if center_label: center_label.text = ""
	
	# Reset button position and style
	_reset_next_button_layout()
	
	var data = story_data[current_index]
	var new_tex = load(data["background"])
	
	if current_index == 0 or background_sprite.texture == new_tex:
		background_sprite.texture = new_tex
		is_transitioning = false 
		_update_ui_content(data)
		return

	is_transitioning = true
	if next_button: next_button.visible = false
	
	if transition_sprite:
		transition_sprite.texture = background_sprite.texture
		transition_sprite.modulate.a = 1.0
	
	background_sprite.texture = new_tex
	_update_ui_content(data, true)
	
	var tween = create_tween()
	if tween and transition_sprite:
		tween.tween_property(transition_sprite, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
		await tween.finished
	
	is_transitioning = false
	
	if data["text"] != "":
		next_button.visible = true
		_play_typewriter(data["text"])
	elif data.has("show_center_after"):
		_show_special_frame(data)
	else:
		_start_auto_next(3.0)

func _play_typewriter(text: String) -> void:
	var char_count = text.length()
	var target_duration = char_count / 30.0 
	target_duration = clamp(target_duration, 1.0, 5.0) 
	
	animation_player.speed_scale = 5.0 / target_duration
	animation_player.play("typewriter")

func _update_ui_content(data: Dictionary, during_transition: bool = false) -> void:
	if name_frame:
		if data["name"] != "":
			name_frame.visible = true
			name_label.text = data["name"]
		else:
			name_frame.visible = false
	
	if data["text"] != "":
		dialogue_container.visible = true
		dialogue_label.text = "[center]%s[/center]" % data["text"]
		dialogue_label.visible_ratio = 0
		
		if not during_transition:
			next_button.visible = true
			_play_typewriter(data["text"])
		else:
			next_button.visible = false
	else:
		dialogue_container.visible = false
		next_button.visible = false
		dialogue_label.text = ""
		dialogue_label.visible_ratio = 1.0
		
		if not during_transition:
			if data.has("show_center_after"):
				_show_special_frame(data)
			else:
				_start_auto_next(3.0)

func _start_auto_next(duration: float) -> void:
	var timer_index = current_index
	await get_tree().create_timer(duration).timeout
	if current_index == timer_index and not is_transitioning and not is_showing_special:
		current_index += 1
		display_current_step()

func _on_next_pressed() -> void:
	if is_transitioning: 
		return
	
	if is_showing_special:
		current_index += 1
		display_current_step()
		return

	if animation_player.is_playing() and animation_player.current_animation == "typewriter":
		animation_player.seek(animation_player.current_animation_length, true)
		animation_player.stop()
		dialogue_label.visible_ratio = 1.0
	else:
		var data = story_data[current_index]
		if data.has("show_center_after") and not is_showing_special:
			_show_special_frame(data)
		else:
			current_index += 1
			display_current_step()

func _show_special_frame(data: Dictionary) -> void:
	is_showing_special = true
	var path = data["show_center_after"]
	if center_frame:
		center_frame.texture = load(path)
		center_frame.visible = true
		center_frame.modulate.a = 0
		
		if data.has("center_text"):
			center_label.text = data["center_text"]
		else:
			center_label.text = ""
			
		var tween = create_tween()
		tween.tween_property(center_frame, "modulate:a", 1.0, 0.5)
	
	if dialogue_container: dialogue_container.visible = false
	if name_frame: name_frame.visible = false
	
	# Tampilkan tombol NEXT
	if next_button:
		next_button.visible = true
		if data.has("is_last_slide") and data["is_last_slide"]:
			# REPOSITION BUTTON TO CENTER BOTTOM FOR LAST SLIDE
			next_button.text = "Begin"
			next_button.add_theme_color_override("font_color", Color("#422300"))
			
			# Move button out of container to center it
			next_button.get_parent().remove_child(next_button)
			$UI.add_child(next_button)
			
			next_button.custom_minimum_size = Vector2(300, 80)
			
			# Set anchors manually to Center-Bottom (0.5, 1, 0.5, 1) to prevent stretching
			next_button.anchor_left = 0.5
			next_button.anchor_top = 1.0
			next_button.anchor_right = 0.5
			next_button.anchor_bottom = 1.0
			
			# Set manual offsets to control position and size
			next_button.offset_left = -150
			next_button.offset_right = 150
			next_button.offset_top = -250 # Lebih tinggi lagi
			next_button.offset_bottom = -170
		else:
			next_button.text = "NEXT"

func _reset_next_button_layout() -> void:
	if next_button and next_button.get_parent() != ui_container:
		next_button.get_parent().remove_child(next_button)
		ui_container.add_child(next_button)
		next_button.text = "NEXT"
		next_button.custom_minimum_size = Vector2(180, 60)
		next_button.remove_theme_color_override("font_color")

func _on_next_button_hover() -> void:
	_set_button_texture(TEX_HOVER)

func _on_next_button_normal() -> void:
	_set_button_texture(TEX_NORMAL)

func _set_button_texture(tex: Texture2D) -> void:
	if next_button:
		var button_bg = next_button.get_node_or_null("ButtonBG")
		if button_bg and button_bg is TextureRect:
			button_bg.texture = tex
