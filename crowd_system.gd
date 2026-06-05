extends Control

@export var crowd_size := 40
@export var animal_textures: Array[Texture2D] = []

@export_group("Spawn Zones")
@export var bg1: Control
@export var bg2: Control
@export var bg3: Control

var crowd_members: Array[TextureRect] = []
var original_positions: Dictionary = {}

func _ready() -> void:
	# Small delay to ensure children are fully ready
	call_deferred("spawn_crowd")

func spawn_crowd() -> void:
	# Auto-assign placeholders if not set in inspector
	if not bg1: bg1 = get_node_or_null("CrowdBackground")
	if not bg2: bg2 = get_node_or_null("CrowdBackground2")
	if not bg3: bg3 = get_node_or_null("CrowdBackground3")

	# Clear existing members
	for member in crowd_members:
		if is_instance_valid(member):
			member.queue_free()
	crowd_members.clear()
	original_positions.clear()

	if animal_textures.is_empty():
		push_warning("CrowdSystem: No animal textures assigned!")
		return

	# Hide placeholders
	for bg in [bg1, bg2, bg3]:
		if bg:
			if bg is ColorRect:
				bg.color.a = 0
			bg.self_modulate.a = 0

	# Define Zones
	var zones = [bg1, bg2, bg3].filter(func(node): return node != null)

	for parent_node in zones:
		var rect: Rect2 = parent_node.get_rect()
		
		# Density settings
		var target_size := randf_range(90.0, 110.0) # Larger animals
		var h_sep := target_size * 0.9 # Packed but with more space for larger size
		var v_sep := target_size * 0.6 # Vertical overlap for depth
		
		var cols := int(ceil(rect.size.x / h_sep)) + 1
		var rows := int(ceil(rect.size.y / v_sep)) + 1

		for r in range(rows):
			for c in range(cols):
				var animal := TextureRect.new()
				animal.texture = animal_textures.pick_random()
				animal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				animal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				# Variation in size
				var s := target_size * randf_range(0.9, 1.1)
				animal.size = Vector2(s, s)
				
				# Position with staggering and slight randomness
				var stagger := (h_sep * 0.5) if (r % 2 == 1) else 0.0
				var pos_x := (c * h_sep) + stagger + randf_range(-5, 5) - (s * 0.5)
				var pos_y := (r * v_sep) + randf_range(-5, 5) - (s * 0.5)
				
				# Clamp to keep within or slightly overlapping the zone
				animal.position = Vector2(pos_x, pos_y)
				
				parent_node.add_child(animal)
				crowd_members.append(animal)
				original_positions[animal] = animal.position
	
	_sort_crowd()

func _sort_crowd() -> void:
	var members = crowd_members.duplicate()
	members.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)
	for i in range(members.size()):
		members[i].get_parent().move_child(members[i], members[i].get_parent().get_child_count() - 1)

func cheer() -> void:
	for animal in crowd_members:
		# Reduced chance to cheer per character to keep it subtle
		if randf() > 0.95:
			_animate_jump(animal)

func _animate_jump(node: Control) -> void:
	if not original_positions.has(node): return
	if node.has_meta("is_jumping") and node.get_meta("is_jumping"): return
	
	node.set_meta("is_jumping", true)
	var base_pos = original_positions[node]
	var tween := create_tween()
	var jump_height := randf_range(3, 7) # Even smaller jump
	var duration := randf_range(0.1, 0.15)
	
	tween.tween_property(node, "position:y", base_pos.y - jump_height, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", base_pos.y, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(func(): node.set_meta("is_jumping", false))
