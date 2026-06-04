extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var sentiment_bar: Control = $MarginContainer/VBoxContainer/SentimentBar
@onready var crowd_label: Label = $MarginContainer/VBoxContainer/CrowdLabel
@onready var prompt_label: Label = $MarginContainer/VBoxContainer/PromptLabel
@onready var input_box: LineEdit = $MarginContainer/VBoxContainer/InputBox
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var feedback_label: Label = $MarginContainer/VBoxContainer/FeedbackLabel
@onready var transcript_label: Label = $MarginContainer/VBoxContainer/TranscriptLabel
@onready var turn_timer: Timer = $TurnTimer

const APPROVAL_MIN := 0
const APPROVAL_MAX := 100

const POSITIVE_WORDS := {
	"gratis": 4,
	"maju": 3,
	"cerdas": 4,
	"sejahtera": 4,
	"adil": 3,
	"aman": 3,
	"rakyat": 2,
	"bersatu": 4,
	"damai": 3,
	"kuat": 2
}

const STEPS := [
	{
		"kind": "line",
		"text": "Saudara saudara kita akan membawa rakyat menuju"
	},
	{
		"kind": "choice",
		"prompt": "Saudara saudara jangan lupa untuk ____ susu agar kuat",
		"options": [
			{"text": "minum", "delta": 4},
			{"text": "meminum", "delta": 2},
			{"text": "makan", "delta": -4}
		]
	},
	{
		"kind": "line",
		"text": "masa depan yang gratis maju dan cerdas"
	},
	{
		"kind": "choice",
		"prompt": "Kita harus ____ bersama demi kandang yang lebih baik",
		"options": [
			{"text": "bersatu", "delta": 4},
			{"text": "diam", "delta": -3},
			{"text": "berpisah", "delta": -5}
		]
	},
	{
		"kind": "line",
		"text": "demi hidup yang adil sejahtera dan aman"
	}
]

var current_step_index := 0
var current_words: Array = []
var current_word_index := 0
var current_choice: Dictionary = {}

var approval_rating := 50
var score := 0
var streak := 0

var game_active := false
var transcript := ""
var feedback := "Tekan Start."

var current_step_failed := false


func _ready() -> void:
	title_label.text = "Propaganda Farm"

	input_box.text_changed.connect(_on_text_changed)
	start_button.pressed.connect(start_game)
	turn_timer.timeout.connect(_on_turn_timer_timeout)

	turn_timer.wait_time = 1.0
	turn_timer.one_shot = false

	start_button.focus_mode = Control.FOCUS_NONE
	input_box.placeholder_text = "Ketik langsung..."

	# DEBUG
	await get_tree().process_frame
	print("SentimentBar size: ", sentiment_bar.size)
	print("SentimentBar position: ", sentiment_bar.position)

	start_game()

func start_game() -> void:
	game_active = true
	approval_rating = 50
	score = 0
	streak = 0
	transcript = ""
	current_step_index = 0
	current_step_failed = false

	input_box.editable = true
	input_box.clear()

	load_step(current_step_index)
	turn_timer.start()

	update_ui()
	call_deferred("_focus_input")


func _focus_input() -> void:
	if game_active:
		input_box.grab_focus()


func load_step(index: int) -> void:
	if index >= STEPS.size():
		finish_game()
		return

	var step: Dictionary = STEPS[index]
	current_step_failed = false
	input_box.clear()

	if step.get("kind", "line") == "line":
		current_words = String(step.get("text", "")).split(" ", false)
		current_word_index = 0
		current_choice = {}
		feedback = "Orasi berlanjut."

	elif step.get("kind", "line") == "choice":
		current_words = []
		current_word_index = 0
		current_choice = step
		feedback = "Ketik kata yang paling tepat."

	else:
		current_words = []
		current_word_index = 0
		current_choice = {}
		feedback = "Langkah tidak dikenal."


func normalize_text(text: String) -> String:
	var s := text.strip_edges().to_lower()
	for ch in [
		",", ".", "!", "?", ":", ";",
		"\"", "'", "(", ")", "-", "—",
		"…"
	]:
		s = s.replace(ch, "")
	return s


func regex_escape(text: String) -> String:
	var s := text
	for ch in ["\\", ".", "+", "*", "?", "^", "$", "(", ")", "[", "]", "{", "}", "|", "/"]:
		s = s.replace(ch, "\\" + ch)
	return s


func sentiment_label() -> String:
	if approval_rating <= 10:
		return "Massa Murka"
	elif approval_rating <= 25:
		return "Publik Membara"
	elif approval_rating <= 45:
		return "Publik Curiga"
	elif approval_rating <= 60:
		return "Netral"
	elif approval_rating <= 80:
		return "Mulai Menerima"
	elif approval_rating <= 95:
		return "Antusias"
	return "Kultus Kepribadian"


func apply_approval(delta: int) -> void:
	approval_rating = clampi(approval_rating + delta, APPROVAL_MIN, APPROVAL_MAX)


func _on_text_changed(new_text: String) -> void:
	if not game_active:
		return

	if current_step_index >= STEPS.size():
		return

	var step: Dictionary = STEPS[current_step_index]
	var kind := String(step.get("kind", "line"))
	var typed := normalize_text(new_text)

	if typed == "":
		current_step_failed = false
		return

	if kind == "line":
		_handle_line_input(typed)
	elif kind == "choice":
		_handle_choice_input(typed)


func _handle_line_input(typed: String) -> void:
	if current_word_index >= current_words.size():
		return

	var expected := normalize_text(String(current_words[current_word_index]))

	# Masih aman selama typed adalah prefix dari expected
	if expected.begins_with(typed):
		current_step_failed = false
		feedback = "..."
		update_ui()

		# Begitu pas satu kata penuh, commit otomatis
		if typed == expected:
			_commit_word(expected)
		return

	# typo
	if not current_step_failed:
		current_step_failed = true
		streak = 0
		apply_approval(-4)
		feedback = "Slip of tongue! Publik menangkap salah ucapmu."
		update_ui()
		check_fail_state()


func _handle_choice_input(typed: String) -> void:
	var options: Array = current_choice.get("options", [])
	if options.is_empty():
		return

	var matched_option: Dictionary = {}
	var has_prefix := false

	# regex exact match ke salah satu opsi
	var pattern_parts: Array[String] = []
	for opt in options:
		var opt_text := normalize_text(String(opt.get("text", "")))
		if opt_text == "":
			continue

		pattern_parts.append(regex_escape(opt_text))

		if opt_text.begins_with(typed):
			has_prefix = true

	var regex := RegEx.new()
	var pattern := "^(" + "|".join(pattern_parts) + ")$"
	var err := regex.compile(pattern)

	if err == OK and regex.search(typed) != null:
		for opt in options:
			var opt_text := normalize_text(String(opt.get("text", "")))
			if opt_text == typed:
				matched_option = opt
				break
	else:
		# fallback kalau regex gagal
		for opt in options:
			var opt_text := normalize_text(String(opt.get("text", "")))
			if opt_text == typed:
				matched_option = opt
				break

	if not matched_option.is_empty():
		_commit_choice(matched_option)
		return

	if has_prefix:
		current_step_failed = false
		feedback = "..."
		update_ui()
		return

	# typo / slip tongue
	if not current_step_failed:
		current_step_failed = true
		streak = 0
		apply_approval(-4)
		feedback = "Slip of tongue! Pilihan kata meleset."
		update_ui()
		check_fail_state()


func _commit_word(expected: String) -> void:
	streak += 1
	score += 10 + streak

	transcript += String(current_words[current_word_index]) + " "

	if POSITIVE_WORDS.has(expected):
		apply_approval(int(POSITIVE_WORDS[expected]))
		score += 5
		feedback = "Publik menyambut baik."
	else:
		apply_approval(1)
		feedback = "Pidato berlanjut."

	current_word_index += 1
	current_step_failed = false
	input_box.clear()

	if current_word_index >= current_words.size():
		current_step_index += 1
		if current_step_index >= STEPS.size():
			finish_game()
			return
		load_step(current_step_index)

	update_ui()
	call_deferred("_focus_input")


func _commit_choice(option: Dictionary) -> void:
	var selected := String(option.get("text", ""))
	var delta := int(option.get("delta", 0))

	streak += 1
	score += 12 + streak

	transcript += "[" + selected + "] "
	apply_approval(delta)

	if delta > 0:
		feedback = "Pilihan kata tepat. Publik suka."
	elif delta == 0:
		feedback = "Pilihan aman."
	else:
		feedback = "Pilihan kata buruk. Publik tidak suka."

	current_step_failed = false
	input_box.clear()

	current_step_index += 1
	if current_step_index >= STEPS.size():
		finish_game()
		return

	load_step(current_step_index)
	update_ui()
	call_deferred("_focus_input")


func _on_turn_timer_timeout() -> void:
	if not game_active:
		return

	apply_approval(-1)

	if streak >= 5:
		score += 1

	feedback = "Waktu berjalan..."
	update_ui()
	check_fail_state()


func check_fail_state() -> void:
	if approval_rating <= APPROVAL_MIN and game_active:
		lose_game()


func finish_game() -> void:
	game_active = false
	turn_timer.stop()
	input_box.editable = false

	match approval_rating:
		96, 97, 98, 99, 100:
			feedback = "Kultus kepribadian terbentuk. Publik bersorak."
		81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95:
			feedback = "Publik antusias. Orasi berjalan mulus."
		61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80:
			feedback = "Publik mulai menerima."
		46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60:
			feedback = "Publik netral."
		26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45:
			feedback = "Publik mulai curiga."
		11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25:
			feedback = "Publik membara."
		_:
			feedback = "Massa murka."

	update_ui()


func lose_game() -> void:
	game_active = false
	turn_timer.stop()
	input_box.editable = false
	feedback = "Kandang murka. Orasi dihentikan."
	update_ui()


func update_ui() -> void:
	sentiment_bar.approval = approval_rating
	crowd_label.text = "Approval: %d/100 | %s | Score: %d | Streak: %d" % [
		approval_rating,
		sentiment_label(),
		score,
		streak
	]

	transcript_label.text = transcript.strip_edges()
	feedback_label.text = feedback

	if game_active and current_step_index < STEPS.size():
		var step: Dictionary = STEPS[current_step_index]
		var kind := String(step.get("kind", "line"))

		if kind == "line":
			if current_word_index < current_words.size():
				prompt_label.text = String(current_words[current_word_index])
			else:
				prompt_label.text = "Lanjut..."
		elif kind == "choice":
			prompt_label.text = String(step.get("prompt", "Pilih kata"))

			var options_text := ""
			var options: Array = step.get("options", [])
			for i in options.size():
				var opt: Dictionary = options[i]
				var label := char(65 + i) # A, B, C...
				options_text += "%s: %s" % [label, String(opt.get("text", ""))]
				if i < options.size() - 1:
					options_text += "    "

			feedback_label.text = feedback + "\n" + options_text
		else:
			prompt_label.text = "Lanjut..."
	else:
		prompt_label.text = "Pidato selesai"
