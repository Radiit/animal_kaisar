extends Control

@export var tex_shout_kiri: Texture2D
@export var tex_shout_kanan: Texture2D
@export var tex_ptok: Texture2D

var last_spawn_time := 0.0
@export var spawn_cooldown := 0.15 # Minimum time between any effects

func _ready() -> void:
	# Ensure it's on top and doesn't block input
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_as_top_level(true)

func spawn_feedback(paper_pos: Vector2, mic_pos: Vector2, crowd_rects: Array[Rect2]) -> void:
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_spawn_time < spawn_cooldown:
		return
		
	last_spawn_time = current_time

	# Lowered chances to avoid clutter
	if randf() > 0.8:
		_spawn_at_podium(paper_pos, mic_pos)
	
	if randf() > 0.7:
		_spawn_at_crowd(crowd_rects)

func _spawn_at_podium(paper_pos: Vector2, mic_pos: Vector2) -> void:
	if randf() > 0.5:
		# Shout Kiri above paper
		var pos = paper_pos + Vector2(-40, -60)
		_create_effect(tex_shout_kiri, pos, randf_range(0.7, 0.9))
	else:
		# Shout Kanan above mic
		var pos = mic_pos + Vector2(20, -50)
		_create_effect(tex_shout_kanan, pos, randf_range(0.4, 0.6))

func _spawn_at_crowd(rects: Array[Rect2]) -> void:
	if rects.is_empty(): return
	var rect = rects.pick_random()
	var pos = Vector2(
		randf_range(rect.position.x, rect.position.x + rect.size.x),
		randf_range(rect.position.y, rect.position.y + rect.size.y)
	)
	
	var type = randi() % 3
	var tex: Texture2D
	var effect_scale := randf_range(0.4, 0.6) # Small over crowd
	
	match type:
		0: tex = tex_shout_kiri
		1: tex = tex_shout_kanan
		2: tex = tex_ptok
	
	_create_effect(tex, pos, effect_scale)

func _create_effect(tex: Texture2D, pos: Vector2, effect_scale: float) -> void:
	if not tex: return
	
	var tex_rect := TextureRect.new()
	tex_rect.texture = tex
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.modulate.a = 0.8
	
	# Original size scaled
	var effect_size = tex.get_size() * effect_scale
	tex_rect.size = effect_size
	tex_rect.position = pos - (effect_size * 0.5)
	
	add_child(tex_rect)
	
	# Animation: Float up and fade out
	var tween = create_tween().set_parallel(true)
	var duration := 0.6
	tween.tween_property(tex_rect, "position:y", tex_rect.position.y - 30, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(tex_rect, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	
	tween.finished.connect(func(): tex_rect.queue_free())
