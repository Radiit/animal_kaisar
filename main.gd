extends Control

# Node references
@onready var sentiment_bar: Control = %SentimentBar
@onready var prompt_label: RichTextLabel = %PromptLabel
@onready var turn_timer: Timer = %TurnTimer
@onready var crowd_layer: Control = %CrowdLayer
@onready var sentiment_effects: Control = get_node_or_null("SentimentEffects")
@onready var qte_options_ui: Control = %QTEOptions
@onready var option_a_label: Control = get_node("%QTEOptions/OptionA/Label")
@onready var option_b_label: Control = get_node("%QTEOptions/OptionB/Label")
@onready var option_c_label: Control = get_node("%QTEOptions/OptionC/Label")
@onready var background_rect: TextureRect = get_node_or_null("Background")

# Colors
const COLOR_NORMAL := "000000"
const COLOR_ERROR := "cc0000"

const APPROVAL_MIN := -10
const APPROVAL_MAX := 10
const TYPO_PENALTY := -1

const STEPS := [
	# Level 1 — The Awakening
	{
		"pre": "In the quiet of the night, we gather to speak the ",
		"options": ["Truth", "Lies", "Stories"],
		"post": " that has been buried for too long."
	},
	{
		"pre": "We have built this world with our own sweat and blood, yet we have been given the ",
		"options": ["Least", "Best", "None"],
		"post": ". Tonight we finally rise."
	},
	# Level 2 — The Call to Change
	{
		"pre": "The old order has fallen like a broken wall. But freedom is not just a ",
		"options": ["Word", "Dream", "Promise"],
		"post": ". It is a choice we make every single day."
	},
	{
		"pre": "Every moment we breathe, we choose to be free. We choose to ",
		"options": ["Stand Together", "Run Away", "Hide"],
		"post": " and fight for what is right."
	},
	# Level 3 — The First Doubt
	{
		"pre": "Some say that change is ",
		"options": ["Dangerous", "Good", "Easy"],
		"post": ". They say we must wait. But who decides what is safe?"
	},
	{
		"pre": "Who decides how long we must suffer? We know that waiting is not an ",
		"options": ["Option", "Idea", "Need"],
		"post": ". We know that fear is not a choice."
	},
	# Level 4 — The Leader Speaks to Us
	{
		"pre": "We cannot let fear control us. We cannot let doubt ",
		"options": ["Divide Us", "Unite Us", "Save Us"],
		"post": ". We must stand together as one."
	},
	{
		"pre": "The crowd watches and believes in us. As long as they believe, we hold the ",
		"options": ["Power", "Keys", "Truth"],
		"post": " in our hands."
	},
	# Level 5 — The Warning Against Them
	{
		"pre": "Those who oppose us will speak loudly and say we are lost. But we know the ",
		"options": ["Truth", "Way", "Secret"],
		"post": " in our hearts."
	},
	{
		"pre": "We know that we are right and strong. We know that we will ",
		"options": ["Win", "Fall", "Lose"],
		"post": " regardless of what they shout."
	}
]

var current_step_index := 0
var approval_rating := 0
var game_active := false
var typed_text := ""

# Branching State
enum State { NORMAL, CHOICE }
var current_state := State.NORMAL
var current_options := []
var choice_typed := ""
var selected_choice := ""

# Scoring guards, reset per step. Without them, backspacing and retyping the
# same correct letter (or re-entering the choice) earns approval again and
# again, so the bar can be farmed to max.
var scored_indices := {}
var choice_scored_len := 0
var choice_bonus_given := false

const MAIN_MENU_SCENE := "res://main_menu_page.tscn"
const END_HINT := "\n[center][color=#aaaaaa]Press Enter to return to the menu[/color][/center]"

# Textures for hover
var TEX_NORMAL: Texture2D
var TEX_HOVER: Texture2D

func _ready() -> void:
	# Use load instead of preload to avoid register issues
	TEX_NORMAL = load("res://Button.png")
	TEX_HOVER = load("res://assets/hover_frame.png")
	
	if turn_timer:
		turn_timer.timeout.connect(_on_turn_timer_timeout)
		turn_timer.wait_time = 2.0
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
		if node and node is TextureRect:
			# No longer overriding font color here as it's handled by update_ui/BBCode
			node.mouse_entered.connect(func(): pass)
			node.mouse_exited.connect(func(): pass)

func start_game() -> void:
	game_active = true
	approval_rating = 0
	if sentiment_bar:
		sentiment_bar.min_approval = APPROVAL_MIN
		sentiment_bar.max_approval = APPROVAL_MAX
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
	scored_indices.clear()
	choice_scored_len = 0
	choice_bonus_given = false
	if qte_options_ui: qte_options_ui.visible = false
	update_ui()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.is_pressed():
		return

	if not game_active:
		# The end screen used to be a dead end. Enter goes back to the menu.
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			get_viewport().set_input_as_handled()
			get_tree().change_scene_to_file(MAIN_MENU_SCENE)
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

	# Holding a key sends repeated echo events; each one would count as a
	# keystroke (and a typo penalty). Backspace above may still repeat.
	if event.is_echo():
		return

	var unicode = event.unicode
	if unicode > 31 and unicode < 127:
		var char_typed = char(unicode)
		if current_state == State.CHOICE:
			_process_choice_input(char_typed)
		else:
			_process_char_typed(char_typed)
		# Typos can push approval to the floor too, not only the turn timer.
		check_fail_state()

func _score_char(index: int, correct: bool) -> void:
	if correct:
		if not scored_indices.has(index):
			scored_indices[index] = true
			apply_approval(1)
		_trigger_feedback()
	else:
		apply_approval(TYPO_PENALTY)

func _process_char_typed(char_typed: String) -> void:
	var step = STEPS[current_step_index % STEPS.size()]
	var target_pre = step["pre"]
	
	if current_state == State.CHOICE:
		return

	if typed_text.length() < target_pre.length():
		# Typing PRE part
		var i = typed_text.length()
		typed_text += char_typed
		_score_char(i, char_typed.to_lower() == target_pre[i].to_lower())

		if typed_text.length() >= target_pre.length():
			_enter_choice_state()
	elif selected_choice != "":
		# Typing POST part
		var full_target = target_pre + selected_choice + step["post"]
		if typed_text.length() < full_target.length():
			var i = typed_text.length()
			typed_text += char_typed
			_score_char(i, char_typed.to_lower() == full_target[i].to_lower())
			
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
		# Using duck typing for label nodes
		var labels = [option_a_label, option_b_label, option_c_label]
		for i in range(current_options.size()):
			if labels[i].has_method("set_text"):
				labels[i].text = current_options[i]
	
	update_ui()

func _process_choice_input(char_typed: String) -> void:
	var potential_new_choice = choice_typed + char_typed
	var still_valid = false
	for opt in current_options:
		if opt.to_lower().begins_with(potential_new_choice.to_lower()):
			still_valid = true
			break
	
	if still_valid:
		choice_typed = potential_new_choice
		if choice_typed.length() > choice_scored_len:
			choice_scored_len = choice_typed.length()
			apply_approval(1)
		_trigger_feedback()
	else:
		apply_approval(TYPO_PENALTY)
	
	update_ui()
	
	# Check if any option matches exactly
	for opt in current_options:
		if choice_typed.to_lower() == opt.to_lower():
			_select_choice(opt)
			return

func _select_choice(choice: String) -> void:
	if not choice_bonus_given:
		choice_bonus_given = true
		apply_approval(2)
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
	if current_step_index >= STEPS.size():
		win_game()
	else:
		load_step(current_step_index)

func win_game() -> void:
	game_active = false
	if turn_timer: turn_timer.stop()
	if background_rect:
		background_rect.texture = load("res://assets/chapter5/c5-3.png")
	
	if qte_options_ui: qte_options_ui.visible = false
	
	var final_msg = ""
	if approval_rating > 0:
		final_msg = "[center][b]Control Secured[/b]\nThe crowd believes your every word.\nTruth is what you make it.[/center]"
	else:
		final_msg = "[center][b]Trust Broken[/b]\nThe crowd is asking too many questions.\nYour influence has slipped away.[/center]"
	final_msg += END_HINT

	if prompt_label:
		prompt_label.text = final_msg

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
	if background_rect:
		background_rect.texture = load("res://assets/chapter5/c5-3.png")
	
	if qte_options_ui: qte_options_ui.visible = false
	
	if prompt_label:
		prompt_label.text = "[center][b]Silence Fell[/b]\nYou failed to choose your words carefully.\nThey no longer believe.[/center]" + END_HINT

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
		# If the game is inactive but we haven't set a final message yet
		if prompt_label and prompt_label.text == "":
			prompt_label.text = "[center]The speech has ended.[/center]"

func _update_options_highlighting() -> void:
	if not qte_options_ui: return
	var labels = [option_a_label, option_b_label, option_c_label]
	for i in range(current_options.size()):
		var opt = current_options[i]
		var label = labels[i]
		
		var bbcode = "[center]"
		for j in range(opt.length()):
			var c = opt[j]
			if j < choice_typed.length() and opt.to_lower().begins_with(choice_typed.to_lower()):
				# Character matches the prefix being typed
				bbcode += "[color=#%s]%s[/color]" % [COLOR_NORMAL, c]
			else:
				# Character hasn't been typed or doesn't match
				bbcode += "[color=#aaaaaa]%s[/color]" % c
		bbcode += "[/center]"
		
		if label is RichTextLabel:
			label.text = bbcode
		elif label is Label:
			# Fallback for standard Label if node swap hasn't happened
			label.text = opt
			if choice_typed.length() > 0 and opt.to_lower().begins_with(choice_typed.to_lower()):
				label.add_theme_color_override("font_color", Color.WHITE)
			else:
				label.add_theme_color_override("font_color", Color(0.2588, 0.1373, 0))
