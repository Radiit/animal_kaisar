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
	# CHAPTER 1
	{
		"background": "res://assets/chapter1/c1-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter1/c1-2.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter1/c1-3.png",
		"name": "Major",
		"text": "As long as humans rule, we only work for them. We provide the labor, and they take the rewards.\nIt's time for us to rise up and take back our lives."
	},
	{
		"background": "res://assets/chapter1/c1-3.png",
		"name": "Major",
		"text": "Ptok Ptok Ptok, hweee hweee hweee, ngok ngoookkkk !!!!! Ptok Ptok Ptok, hweee hweee hweee, ngok ngoookkkkm !!!!!! Ptok Ptok Ptok, hweee hweee hweee, ngok ngoookkkk"
	},
	{
		"background": "res://assets/chapter1/c1-4.png",
		"name": "",
		"text": "Not long after the old major announced his revolution, he died.\nBut his words ignited hope. \nFor the first time, the animals imagined a life of freedom and equality."
	},
	# CHAPTER 2
	{
		"background": "res://assets/chapter2/c2-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter2/c2-2.png",
		"name": "",
		"text": "Not long after that, humans were driven from the ranch. Doors were opened, barns were torn down, and the old name of the ranch was abandoned. Now, everything belongs to the animals."
	},
	{
		"background": "res://assets/chapter2/c2-3.png",
		"name": "Napoleon",
		"text": "We did it. We are free."
	},
	{
		"background": "res://assets/chapter2/c2-4.png",
		"name": "Boxer",
		"text": "No more whips. No more human commands."
	},
	{
		"background": "res://assets/chapter2/c2-5.png",
		"name": "",
		"text": "They believe a new age has begun. Seven rules are laid out, and all animals are united in one promise: equality.",
		"show_center_after": "res://assets/chapter2/frame-c2-5.png"
	},
	# CHAPTER 3
	{
		"background": "res://assets/chapter3/c3-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter3/c3-2.png",
		"name": "Napoleon",
		"text": "This farm must remain safe. Not all animals can understand big decisions."
	},
	{
		"background": "res://assets/chapter3/c3-3.png",
		"name": "",
		"text": "Every rule change is made to sound reasonable. Any dissatisfaction is answered with reasons. Every doubt is forced to silence before it can grow."
	},
	# CHAPTER 4
	{
		"background": "res://assets/chapter4/c4-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter4/c4-2.png",
		"name": "",
		"text": "Now, you stand in that line. Not as a witness, but as a voice that must be heard. In front of the animals, every word you type will shape their beliefs.",
		"show_center_after": "res://assets/chapter4/c4-2-frame.png",
		"center_text": "Now, you stand in that line. Not as a witness, but as a voice that must be heard. In front of the animals, every word you type will shape their beliefs."
	},
	{
		"background": "res://assets/chapter4/c4-3.png",
		"name": "Squerel",
		"text": "Listen carefully.\nWhat we do is for the common good."
	},
	{
		"background": "res://assets/chapter4/c4-4.png",
		"name": "",
		"text": "But words are not always easy to control. One typo can trigger doubts. Too many mistakes, and their trust starts to crumble."
	},
	# CHAPTER 5
	{
		"background": "res://assets/chapter5/c5-1.png",
		"name": "",
		"text": ""
	},
	{
		"background": "res://assets/chapter5/c5-3.png",
		"name": "",
		"text": "",
		"show_center_after": "res://assets/chapter5/c5-2-frame.png"
	},
	{
		"background": "res://assets/chapter5/c5-3.png",
		"name": "",
		"text": "",
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
			next_button.text = "Tap to Begin"
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
