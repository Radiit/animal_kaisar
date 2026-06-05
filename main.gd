extends Control

# Node references
@onready var sentiment_bar: Control = %SentimentBar
@onready var prompt_label: RichTextLabel = %PromptLabel
@onready var turn_timer: Timer = %TurnTimer
@onready var crowd_layer: Control = %CrowdLayer
@onready var sentiment_effects: Control = get_node_or_null("SentimentEffects")

# Colors
const COLOR_NORMAL := "000000"
const COLOR_ERROR := "5c7717"

const APPROVAL_MIN := 0
const APPROVAL_MAX := 100
const TYPO_PENALTY := -2

const STEPS := [
	{
		"text": "Saudara saudara kita akan membawa rakyat menuju masa depan yang gratis maju dan cerdas demi hidup yang adil sejahtera dan aman"
	},
	{
		"text": "Kita harus bersatu bersama demi kandang yang lebih baik untuk semua penghuni desa ini tanpa terkecuali"
	},
	{
		"text": "Jangan pernah menyerah pada keadaan karena kita adalah bangsa yang kuat dan tangguh dalam menghadapi segala rintangan"
	},
	{
		"text": "Pendidikan adalah kunci utama untuk membuka pintu kesuksesan bagi generasi muda kita di masa yang akan datang"
	},
	{
		"text": "Mari kita bangun bersama sebuah ekosistem yang mendukung pertumbuhan ekonomi kreatif dan inovatif bagi seluruh lapisan masyarakat"
	}
]

var current_step_index := 0
var approval_rating := 50
var game_active := false
var typed_text := ""

func _ready() -> void:
	if turn_timer:
		turn_timer.timeout.connect(_on_turn_timer_timeout)
		turn_timer.wait_time = 1.0
		turn_timer.one_shot = false

	if prompt_label:
		prompt_label.bbcode_enabled = true

	start_game()

func start_game() -> void:
	game_active = true
	approval_rating = 50
	current_step_index = 0
	typed_text = ""
	load_step(current_step_index)
	
	if turn_timer:
		turn_timer.start()

	update_ui()

func load_step(index: int) -> void:
	current_step_index = index
	typed_text = ""
	update_ui()

func _input(event: InputEvent) -> void:
	if not game_active or not event is InputEventKey or not event.is_pressed():
		return
	
	if event.is_action_pressed("ui_text_backspace"):
		if typed_text.length() > 0:
			typed_text = typed_text.left(typed_text.length() - 1)
			update_ui()
		return

	var unicode = event.unicode
	if unicode > 31 and unicode < 127:
		var char_typed = char(unicode)
		_process_char_typed(char_typed)

func _process_char_typed(char_typed: String) -> void:
	var step: Dictionary = STEPS[current_step_index % STEPS.size()]
	var full_text = String(step.get("text", ""))
	
	if typed_text.length() < full_text.length():
		var i = typed_text.length()
		typed_text += char_typed
		
		if char_typed.to_lower() == full_text[i].to_lower():
			apply_approval(1)
			if crowd_layer and crowd_layer.has_method("cheer"): 
				crowd_layer.cheer()
			
			if sentiment_effects and sentiment_effects.has_method("spawn_feedback"):
				var paper = get_node_or_null("Paper")
				var mic = get_node_or_null("Stage/Mic")
				var p_pos = paper.global_position if paper else Vector2.ZERO
				var m_pos = mic.global_position if mic else Vector2.ZERO
				
				var rects: Array[Rect2] = []
				if crowd_layer:
					# Explicit check for members if they exist as properties or nodes
					if "bg1" in crowd_layer and crowd_layer.bg1: rects.append(crowd_layer.bg1.get_global_rect())
					if "bg2" in crowd_layer and crowd_layer.bg2: rects.append(crowd_layer.bg2.get_global_rect())
					if "bg3" in crowd_layer and crowd_layer.bg3: rects.append(crowd_layer.bg3.get_global_rect())
				
				sentiment_effects.spawn_feedback(p_pos, m_pos, rects)
		else:
			apply_approval(TYPO_PENALTY)
		
		update_ui()
		
		if typed_text.length() >= full_text.length():
			_on_line_completed()

func _on_line_completed() -> void:
	current_step_index += 1
	load_step(current_step_index % STEPS.size())

func _on_turn_timer_timeout() -> void:
	if not game_active:
		return
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
		var step: Dictionary = STEPS[current_step_index % STEPS.size()]
		var full_text = String(step.get("text", ""))
		
		var bbcode = "[center]"
		for i in range(full_text.length()):
			var char_to_show = full_text[i]
			if i < typed_text.length():
				if typed_text[i].to_lower() == full_text[i].to_lower():
					bbcode += "[color=#%s]%s[/color]" % [COLOR_NORMAL, char_to_show]
				else:
					bbcode += "[color=#%s]%s[/color]" % [COLOR_ERROR, char_to_show]
			else:
				bbcode += "[color=#aaaaaa]%s[/color]" % char_to_show
		bbcode += "[/center]"
		
		if prompt_label:
			prompt_label.text = bbcode
	else:
		if prompt_label:
			prompt_label.text = "[center]Pidato selesai[/center]"
