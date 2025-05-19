extends Node2D

var speed = 400
var target = null
var damage = 20
var range_radius = 150  # Default range, will be set by tower
var tower_type = "rock"

func _ready():
	# Set initial position to tower's global position
	global_position = get_parent().global_position

func set_visual_by_type():
	var color = Color(0,0,0,1) # default black
	if tower_type == "paper":
		color = Color(1,1,1,1)
	elif tower_type == "scissors":
		color = Color(0,0,1,1)
	$ColorRect.color = color

func _process(delta):
	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		position += direction * speed * delta
		
		# Check if we hit the target or if we've gone beyond our range
		if global_position.distance_to(target.global_position) < 10:
			if "take_damage" in target:
				target.take_damage(damage, tower_type)
			queue_free()
		elif global_position.distance_to(get_parent().global_position) > range_radius:
			queue_free()
	else:
		queue_free() 
