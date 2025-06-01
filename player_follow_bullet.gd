extends CharacterBody2D

@onready var hitbox = $Sprite2D/Hitbox
@onready var sprite = $Sprite2D
@export var base_damage: float = 5
var damage: float = 5
var dir : float
var spawnPos : Vector2
var spawnRot : float
var zdex : int
var damage_done : bool

var slither_amplitude: float = 10.0 # Increased side-to-side movement for a wider wave
var slither_frequency: float = 0.1 # Slower wave for smoother, slower direction change
var slither_time: float = 0.0

var age: float = 0.0
var distance_along_laser: float = 0.0 # How far this segment is from the player

@export var player: Node2D # Reference to the player node
var wave_speed: float = 2.0 # How fast the wave animates left/right

# TIP: For best visual connection, use a rectangle or capsule sprite for the segment, not a circle.

var hit_enemies := {} # Set to track already hit enemies

func _ready():
	if player:
		spawnPos = player.global_position
		dir = player.global_rotation
	global_position = spawnPos + Vector2.UP.rotated(dir) * distance_along_laser
	global_rotation = spawnRot
	z_index = zdex

func _physics_process(delta):
	age += delta
	# Do NOT increment distance_along_laser here!
	# Always use player's current position and rotation if available
	var base_pos = spawnPos
	var base_dir = dir
	if player:
		base_pos = player.global_position
		base_dir = player.global_rotation
	var forward = Vector2.UP.rotated(base_dir)
	var perp = forward.orthogonal().normalized()
	# Use distance_along_laser for a continuous wave, and animate with time
	var t = float(Time.get_ticks_msec()) / 1000.0
	var offset = perp * sin(distance_along_laser * slither_frequency + t * wave_speed) * slither_amplitude
	global_position = base_pos + forward * distance_along_laser + offset
	global_rotation = base_dir
	# Check for collisions
	var overlapping_objects = hitbox.get_overlapping_areas()
	for area in overlapping_objects:
		var enemy = area.get_parent()
		if enemy and not hit_enemies.has(enemy):
			enemy.take_damage(damage)
			hit_enemies[enemy] = true
