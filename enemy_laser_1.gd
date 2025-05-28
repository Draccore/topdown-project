extends CharacterBody2D

@onready var hitbox = $hitbox
@export var damage: float
@export var speed: float
var dir : float
var spawnPos : Vector2
var spawnRot : float
var zdex : int
var damage_done : bool

func _ready():
	global_position = spawnPos
	global_rotation = spawnRot
	z_index = zdex
	await get_tree().create_timer(3).timeout
	queue_free()



func _physics_process(delta):
	velocity = Vector2(0, +speed).rotated(dir)
	move_and_slide()
	var overlapping_objects = hitbox.get_overlapping_areas()
	for area in overlapping_objects:
		var enemy = area.get_parent()
		enemy.take_damage(damage)
		queue_free()
