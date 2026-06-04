extends Control
@onready var background: ColorRect = $Background
@onready var foreground: ColorRect = $Foreground
@onready var pig_icon: TextureRect = $PigIcon
@export var min_approval := 0
@export var max_approval := 100
@export var bg_color := Color("#c94b4b")
@export var fg_color := Color("#34c759")
var approval := 50:
	set(value):
		approval = clampi(value, min_approval, max_approval)
		if is_node_ready():
			_update_bar()

func _ready() -> void:
	background.color = bg_color
	foreground.color = fg_color
	custom_minimum_size = Vector2(0, 60) 
	resized.connect(_update_bar)
	call_deferred("_update_bar")

func _update_bar() -> void:
	var range := float(max_approval - min_approval)
	if range <= 0.0:
		return
	var ratio := float(approval - min_approval) / range
	var w := size.x
	var h := size.y
	
	# Background (merah penuh)
	background.position = Vector2.ZERO
	background.size = Vector2(w, h)
	
	# Foreground (hijau, sesuai ratio)
	foreground.position = Vector2(w * ratio, 0)
	foreground.size = Vector2(w * (1.0 - ratio), h)
	
	# Pig icon di tengah (borderline)
	var pig_x = w * ratio - pig_icon.size.x * 0.5
	var pig_y = -pig_icon.size.y * 0.25
	pig_icon.position = Vector2(pig_x, pig_y)
	
	# Z-index
	pig_icon.z_index = 2
	foreground.z_index = 1
	background.z_index = 0
