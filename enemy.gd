extends CharacterBody2D

@export var maxhp: float
@export var xp_value: int

var spawnPos : Vector2
var current_hp: float
var is_dead = false

@onready var projectile = load("res://enemy_laser_1.tscn")
@onready var main = $".."
@onready var cooldown = $Timer

signal enemy_died(xp_amount: int)

func _ready():
	current_hp = maxhp
	velocity.y = 150
	await get_tree().create_timer(0.5).timeout
	velocity.y = 0

func _physics_process(delta: float) -> void:
	move_and_slide()

func take_damage(damage):
	print("DAMAGED!!!!")
	if is_dead:
		return
	current_hp = current_hp - damage
	print(damage)
	if current_hp <= 0:
		die()

func shoot():
	var instance = projectile.instantiate()
	instance.dir = rotation
	instance.spawnPos = global_position
	instance.spawnRot = rotation
	instance.zdex = z_index - 1
	instance.damage = 10
	main.add_child.call_deferred(instance)

func _on_timer_timeout() -> void:
	shoot()
	cooldown.start()

func die():
	if is_dead:
		return
	is_dead = true
	emit_signal("enemy_died", xp_value)
	queue_free()
