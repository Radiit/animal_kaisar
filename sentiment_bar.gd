extends Control

@onready var background: TextureRect = $BarContainer/Background
@onready var foreground: TextureRect = $BarContainer/Foreground
@onready var pig_icon: TextureRect = $PigIcon

@export var min_approval := 0
@export var max_approval := 100

var approval := 50:
	set(value):
		approval = clampi(value, min_approval, max_approval)
		if is_node_ready():
			_update_bar()

func _ready() -> void:
	resized.connect(_update_bar)
	call_deferred("_update_bar")

func _update_bar() -> void:
	var approval_range := float(max_approval - min_approval)
	if approval_range <= 0.0:
		return

	# ratio 1.0 = Max Green (100% Approval), ratio 0.0 = Max Red (0% Approval)
	var ratio := float(approval - min_approval) / approval_range
	var w := size.x
	var h := size.y

	# junction_x moves from w (all Red at 0% approval) to 0 (all Green at 100% approval)
	var junction_x := w * (1.0 - ratio)

	# Red Bar (Left): Slides so its right edge is at junction_x
	background.size = Vector2(w, h)
	background.position = Vector2(junction_x - w, 0)

	# Green Bar (Right): Slides so its left edge is at junction_x
	foreground.size = Vector2(w, h)
	foreground.position = Vector2(junction_x, 0)

	# Pig icon follows junction, clamped within the bar
	var pig_half_w := pig_icon.size.x * 0.5
	var pig_x := clampf(junction_x - pig_half_w, 0, w - pig_icon.size.x)
	pig_icon.position = Vector2(pig_x, h * 0.5 - pig_icon.size.y * 0.5)
