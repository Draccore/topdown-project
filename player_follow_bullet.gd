extends CharacterBody2D

@onready var hitbox = $Sprite2D/Hitbox
@onready var sprite = $Sprite2D
@export var base_damage: float = 5
var damage: float = 5
var dir : float
var spawnPos : Vector2
var spawnRot : float
var zdex : int

var age: float = 0.0
var distance_along_laser: float = 0.0

@export var player: Node2D # Reference to the player node

# Curve controls
var curve_height: float = 5.0

# Static (shared) dict to prevent multi-segment hits per frame
static var damaged_this_frame := {}

func _ready():
	if player:
		spawnPos = player.global_position
		dir = player.global_rotation
	global_position = spawnPos + Vector2.UP.rotated(dir) * distance_along_laser
	global_rotation = spawnRot
	z_index = zdex

func _physics_process(delta):
	age += delta

	# Only one segment (the one with the lowest distance_along_laser) should clear the damaged_this_frame dict per frame.
	if distance_along_laser == 0:
		damaged_this_frame.clear()

	var target_enemy = null
	if player and "laser_target_enemy" in player and player.laser_target_enemy and is_instance_valid(player.laser_target_enemy):
		target_enemy = player.laser_target_enemy

	if target_enemy:
		var start_point = player.global_position
		var end_point = target_enemy.global_position
		var control_point = (start_point + end_point) / 2 + Vector2(0, -curve_height)
		var laser_length = start_point.distance_to(end_point)
		var t = clamp(distance_along_laser / max(laser_length, 1), 0, 1)
		global_position = get_quadratic_bezier_point(t, start_point, control_point, end_point)
		# Optional: face along the curve
		if t < 1.0:
			var next_t = min(t + 0.01, 1.0)
			var next_pos = get_quadratic_bezier_point(next_t, start_point, control_point, end_point)
			global_rotation = (next_pos - global_position).angle()
		else:
			global_rotation = (end_point - global_position).angle()
	else:
		# Straight line fallback
		var base_pos = spawnPos
		var base_dir = dir
		if player:
			base_pos = player.global_position
			base_dir = player.global_rotation
		var forward = Vector2.UP.rotated(base_dir)
		global_position = base_pos + forward * distance_along_laser
		global_rotation = base_dir

	var overlapping_objects = hitbox.get_overlapping_areas()
	for area in overlapping_objects:
		var enemy = area.get_parent()
		if enemy and enemy.has_method("take_damage"):
			var enemy_id = enemy.get_instance_id()
			# Only allow one segment to damage per enemy per frame
			if damaged_this_frame.has(enemy_id):
				continue
			if player and player.can_laser_damage_enemy(enemy):
				enemy.take_damage(damage)
				player.mark_laser_damaged_enemy(enemy)
				damaged_this_frame[enemy_id] = true
				if player and "notify_laser_enemy_hit" in player and not (player.laser_target_enemy and is_instance_valid(player.laser_target_enemy)):
					player.notify_laser_enemy_hit(enemy)
			break # Only hit one enemy per frame per segment

func get_quadratic_bezier_point(t, start, control, end):
	return ((1 - t) * (1 - t)) * start + 2 * (1 - t) * t * control + (t * t) * end
