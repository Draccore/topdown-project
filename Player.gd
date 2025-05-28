extends CharacterBody2D

@onready var main = $".."
@onready var projectile = load("res://playerbullet1.tscn")
@onready var cooldown = $Timer
@onready var hptext = $"../Label"
@onready var hp_bar = $hpbar
@onready var level_label = $"../LevelLabel"
@onready var xp_label = $"../XPLabel"

@export var Speed : float 
@export var MaxHealth : float
@export var Defence : float
@export var Attack : float

var Health : float
var Level: int = 1
var XP: int = 0
var XPToNext: int = 100


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
	Health = MaxHealth
	hp_bar.set_health(Health, MaxHealth)
	update_xp_display()
	print("Level up! Now level %d" % Level)

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
