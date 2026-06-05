extends Control

# Node references
@onready var sentiment_bar: Control = %SentimentBar
@onready var prompt_label: RichTextLabel = %PromptLabel
@onready var turn_timer: Timer = %TurnTimer
@onready var crowd_layer: Control = %CrowdLayer
@onready var sentiment_effects: Control = get_node_or_null("SentimentEffects")
@onready var qte_options_ui: Control = %QTEOptions
@onready var option_a_label: Label = get_node("%QTEOptions/OptionA/Label")
@onready var option_b_label: Label = get_node("%QTEOptions/OptionB/Label")
@onready var option_c_label: Label = get_node("%QTEOptions/OptionC/Label")

# Colors
const COLOR_NORMAL := "000000"
const COLOR_ERROR := "5c7717"

const APPROVAL_MIN := 0
const APPROVAL_MAX := 100
const TYPO_PENALTY := -2

const STEPS := [
	{
		"pre": "Saudara saudara kita akan membuat ikan sehingga ",
		"options": ["Rakyat", "Kucing", "Pejabat"],
		"post": " bisa menikmati hidangan lezat setiap hari tanpa terkecuali"
	},
	{
		"pre": "Kita harus bersatu bersama demi ",
		"options": ["Kandang", "Negara", "Masa Depan"],
		"post": " yang lebih baik untuk semua penghuni desa ini tanpa terkecuali"
	},
	{
		"pre": "Jangan pernah menyerah pada keadaan karena kita adalah ",
		"options": ["Pemenang", "Pejuang", "Bangsa Kuat"],
		"post": " yang tangguh dalam menghadapi segala rintangan yang menghadang"
	}
]

var current_step_index := 0
var approval_rating := 50
var game_active := false
var typed_text := ""

# Branching State
enum State { NORMAL, CHOICE }
var current_state := State.NORMAL
var current_options := []
var choice_typed := ""
var selected_choice := ""

# Textures for hover
var TEX_NORMAL: Texture2D
var TEX_HOVER: Texture2D

func _ready() -> void:
	# Use load instead of preload to avoid register issues
	TEX_NORMAL = load("res://Button.png")
	TEX_HOVER = load("res://assets/hover_frame.png")
	
	if turn_timer:
		turn_timer.timeout.connect(_on_turn_timer_timeout)
		turn_timer.wait_time = 1.0
		turn_timer.one_shot = false
	if prompt_label:
		prompt_label.bbcode_enabled = true
	
	_setup_hover_signals()
	start_game()

func _setup_hover_signals() -> void:
	var options = [
		{"node": get_node_or_null("%QTEOptions/OptionA"), "label": option_a_label},
		{"node": get_node_or_null("%QTEOptions/OptionB"), "label": option_b_label},
		{"node": get_node_or_null("%QTEOptions/OptionC"), "label": option_c_label}
	]
	for opt in options:
		var node = opt["node"]
		var label = opt["label"]
		if node and node is TextureRect:
			node.mouse_entered.connect(func(): label.add_theme_color_override("font_color", Color("#422300")))
			node.mouse_exited.connect(func(): _update_options_highlighting()) # Revert to normal highlighting state

func start_game() -> void:
	game_active = true
	approval_rating = 50
	current_step_index = 0
	current_state = State.NORMAL
	load_step(current_step_index)
	if turn_timer: turn_timer.start()
	update_ui()

func load_step(index: int) -> void:
	current_step_index = index
	typed_text = ""
	current_state = State.NORMAL
	selected_choice = ""
	if qte_options_ui: qte_options_ui.visible = false
	update_ui()

func _input(event: InputEvent) -> void:
	if not game_active or not event is InputEventKey or not event.is_pressed():
		return
	
	if event.is_action_pressed("ui_text_backspace"):
		if current_state == State.CHOICE:
			if choice_typed.length() > 0:
				choice_typed = choice_typed.left(choice_typed.length() - 1)
				update_ui()
		else:
			if typed_text.length() > 0:
				typed_text = typed_text.left(typed_text.length() - 1)
				var step = STEPS[current_step_index % STEPS.size()]
				if typed_text.length() < step["pre"].length():
					selected_choice = ""
				update_ui()
		return

	var unicode = event.unicode
	if unicode > 31 and unicode < 127:
		var char_typed = char(unicode)
		if current_state == State.CHOICE:
			_process_choice_input(char_typed)
		else:
			_process_char_typed(char_typed)

func _process_char_typed(char_typed: String) -> void:
	var step = STEPS[current_step_index % STEPS.size()]
	var target_pre = step["pre"]
	
	if typed_text.length() < target_pre.length():
		# Typing PRE part
		var i = typed_text.length()
		typed_text += char_typed
		if char_typed.to_lower() == target_pre[i].to_lower():
			apply_approval(1)
			_trigger_feedback()
		else:
			apply_approval(TYPO_PENALTY)
		
		if typed_text.length() >= target_pre.length():
			_enter_choice_state()
	else:
		# Typing POST part
		var full_target = target_pre + selected_choice + step["post"]
		if typed_text.length() < full_target.length():
			var i = typed_text.length()
			typed_text += char_typed
			if char_typed.to_lower() == full_target[i].to_lower():
				apply_approval(1)
				_trigger_feedback()
			else:
				apply_approval(TYPO_PENALTY)
			
			if typed_text.length() >= full_target.length():
				_on_line_completed()
	
	update_ui()

func _enter_choice_state() -> void:
	current_state = State.CHOICE
	var step = STEPS[current_step_index % STEPS.size()]
	current_options = step["options"]
	choice_typed = ""
	selected_choice = ""
	
	if qte_options_ui:
		qte_options_ui.visible = true
		option_a_label.text = current_options[0]
		option_b_label.text = current_options[1]
		option_c_label.text = current_options[2]
	
	update_ui()

func _process_choice_input(char_typed: String) -> void:
	choice_typed += char_typed
	update_ui()
	
	# Check if any option matches
	for opt in current_options:
		if choice_typed.to_lower() == opt.to_lower():
			_select_choice(opt)
			return

func _select_choice(choice: String) -> void:
	apply_approval(10)
	_trigger_feedback()
	current_state = State.NORMAL
	selected_choice = choice
	if qte_options_ui: qte_options_ui.visible = false
	
	var step = STEPS[current_step_index % STEPS.size()]
	typed_text = step["pre"] + choice
	update_ui()

func _trigger_feedback() -> void:
	if crowd_layer and crowd_layer.has_method("cheer"): 
		crowd_layer.cheer()
	if sentiment_effects and sentiment_effects.has_method("spawn_feedback"):
		var paper = get_node_or_null("Paper")
		var mic = get_node_or_null("Stage/Mic")
		var p_pos = paper.global_position if paper else Vector2.ZERO
		var m_pos = mic.global_position if mic else Vector2.ZERO
		var rects: Array[Rect2] = []
		if crowd_layer:
			if "bg1" in crowd_layer and crowd_layer.bg1: rects.append(crowd_layer.bg1.get_global_rect())
			if "bg2" in crowd_layer and crowd_layer.bg2: rects.append(crowd_layer.bg2.get_global_rect())
			if "bg3" in crowd_layer and crowd_layer.bg3: rects.append(crowd_layer.bg3.get_global_rect())
		sentiment_effects.spawn_feedback(p_pos, m_pos, rects)

func _on_line_completed() -> void:
	current_step_index += 1
	load_step(current_step_index % STEPS.size())

func _on_turn_timer_timeout() -> void:
	if not game_active: return
	apply_approval(-1)
	update_ui()
	check_fail_state()

func apply_approval(delta: int) -> void:
	approval_rating = clampi(approval_rating + delta, APPROVAL_MIN, APPROVAL_MAX)

func check_fail_state() -> void:
	if approval_rating <= APPROVAL_MIN and game_active:
		lose_game()

func lose_game() -> void:
	game_active = false
	if turn_timer: turn_timer.stop()
	update_ui()

func update_ui() -> void:
	if sentiment_bar:
		sentiment_bar.approval = approval_rating
	
	if game_active:
		var step = STEPS[current_step_index % STEPS.size()]
		var pre = step["pre"]
		var post = step["post"]
		
		var bbcode = "[center]"
		
		# Draw PRE part
		for i in range(pre.length()):
			var c = pre[i]
			if i < typed_text.length():
				if typed_text[i].to_lower() == pre[i].to_lower():
					bbcode += "[color=#%s]%s[/color]" % [COLOR_NORMAL, c]
				else:
					bbcode += "[color=#%s]%s[/color]" % [COLOR_ERROR, c]
			else:
				bbcode += "[color=#aaaaaa]%s[/color]" % c
		
		# Draw CHOICE part
		if current_state == State.CHOICE:
			bbcode += "[color=#422300] ___ [/color]"
			_update_options_highlighting()
		else:
			if selected_choice != "":
				for i in range(selected_choice.length()):
					var c = selected_choice[i]
					bbcode += "[color=#%s]%s[/color]" % [COLOR_NORMAL, c]
				
				# Draw POST part
				var post_start = pre.length() + selected_choice.length()
				for i in range(post.length()):
					var c = post[i]
					var global_idx = post_start + i
					if global_idx < typed_text.length():
						if typed_text[global_idx].to_lower() == post[i].to_lower():
							bbcode += "[color=#%s]%s[/color]" % [COLOR_NORMAL, c]
						else:
							bbcode += "[color=#%s]%s[/color]" % [COLOR_ERROR, c]
					else:
						bbcode += "[color=#aaaaaa]%s[/color]" % c
			else:
				bbcode += "[color=#422300] ___ [/color]"
		
		bbcode += "[/center]"
		if prompt_label:
			prompt_label.text = bbcode
	else:
		if prompt_label:
			prompt_label.text = "[center]Pidato selesai[/center]"

func _update_options_highlighting() -> void:
	if not qte_options_ui: return
	var labels = [option_a_label, option_b_label, option_c_label]
	for i in range(current_options.size()):
		var opt = current_options[i]
		var label = labels[i]
		if choice_typed.length() > 0 and opt.to_lower().begins_with(choice_typed.to_lower()):
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			label.add_theme_color_override("font_color", Color(0.2588, 0.1373, 0))
