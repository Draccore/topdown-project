extends CharacterBody2D

@onready var main = $".."
@onready var projectile = load("res://playerbullet1.tscn")
@onready var cooldown = $Timer
@onready var hp_bar = $hpbar
@onready var level_label = $"../LevelLabel"
@onready var xp_label = $"../XPLabel"
@onready var laser_scene = load("res://player_follow_bullet.tscn")

@export var Speed : float
@export var MaxHealth : float
@export var Defence : float
@export var Attack : float
@export var HealthRegen: float = 2.0
@export var HealthRegenInterval: float = 1.0

var regen_timer: float = 0.0
var Health : float
var Level: int = 1
var XP: int = 0
var XPToNext: int = 50
var laser_active: bool = false
var laser_segment_index: int = 0
var segment_spacing: float = 0.5
var laser_length: float = 600.0

# Laser target coordination
var laser_target_enemy: Node2D = null

# Shared cooldown dictionary for laser damage (enemy_id : last_damage_time)
var laser_enemy_cooldowns := {}

func _ready():
	level_label.text = "Level: %d" % Level
	xp_label.text = "XP: %d/%d" % [XP, XPToNext]
	Health = MaxHealth
	hp_bar.set_health(Health, MaxHealth)

func _physics_process(delta):
	var direction := Input.get_axis("left","right")
	velocity.x = direction * Speed
	velocity.y = 0
	move_and_slide()
	# Health regeneration
	if Health < MaxHealth:
		regen_timer += delta
		if regen_timer >= HealthRegenInterval:
			Health = min(Health + HealthRegen, MaxHealth)
			hp_bar.set_health(Health, MaxHealth)
			regen_timer = 0.0

func add_xp(amount: int) -> void:
	XP += amount
	while XP >= XPToNext:
		XP -= XPToNext
		level_up()
	update_xp_display()

func level_up() -> void:
	Level += 1
	XPToNext = int(XPToNext * 1.2)
	MaxHealth += 10
	Attack += 0.2
	Health = MaxHealth
	HealthRegen += 1
	hp_bar.set_health(Health, MaxHealth)
	update_xp_display()
	print("Level up! Now level %d" % Level)
	if Level == 2:
		spawn_laser()

func update_xp_display():
	level_label.text = "Level: %d" % Level
	xp_label.text = "XP: %d/%d" % [XP, XPToNext]

func shoot():
	for offset in [Vector2.RIGHT * 5, Vector2.LEFT * 5]:
		_spawn_projectile(offset)

func _spawn_projectile(offset: Vector2):
	var spawn_point = global_position + offset.rotated(rotation)
	var instance = projectile.instantiate()
	instance.dir = rotation
	instance.spawnPos = spawn_point
	instance.spawnRot = rotation
	instance.damage = instance.base_damage * Attack
	instance.zdex = z_index - 1
	main.add_child.call_deferred(instance)

func _on_timer_timeout() -> void:
	shoot()
	cooldown.start()

func take_damage(damage):
	Health -= damage
	hp_bar.set_health(Health, MaxHealth)
	if Health <= 0:
		queue_free()

# Laser system
func spawn_laser():
	laser_active = true
	laser_segment_index = 0
	laser_target_enemy = null # clear any previous target

	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		laser_target_enemy = enemies[0] # Or implement your targeting logic
	else:
		laser_target_enemy = null

	var end_point = laser_target_enemy.global_position if (laser_target_enemy and is_instance_valid(laser_target_enemy)) else (global_position + Vector2.UP.rotated(rotation) * laser_length)
	var laser_vector = end_point - global_position
	var true_length = laser_vector.length()
	var num_segments = int(true_length / segment_spacing)
	for i in range(num_segments):
		var instance = laser_scene.instantiate()
		instance.dir = rotation
		instance.spawnPos = global_position
		instance.spawnRot = rotation
		instance.damage = instance.base_damage * Attack
		instance.zdex = z_index - 1
		instance.player = self
		instance.distance_along_laser = i * segment_spacing
		main.add_child(instance)
	laser_segment_index = num_segments

func remove_laser():
	laser_active = false
	laser_segment_index = 0
	laser_target_enemy = null

# Called by laser segments when one hits an enemy
func notify_laser_enemy_hit(enemy):
	if not laser_target_enemy or not is_instance_valid(laser_target_enemy):
		laser_target_enemy = enemy

# Laser shared cooldown helpers
func can_laser_damage_enemy(enemy, cooldown := 0.5):
	var enemy_id = enemy.get_instance_id()
	var last_time = laser_enemy_cooldowns.get(enemy_id, -1000)
	var current_time = Time.get_ticks_msec() / 1000.0
	return current_time - last_time >= cooldown

func mark_laser_damaged_enemy(enemy):
	var enemy_id = enemy.get_instance_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	laser_enemy_cooldowns[enemy_id] = current_time
