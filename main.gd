extends Node2D

var enemy_list = [
	preload("res://RedEnemy.tscn"),
	preload("res://blue_enemy.tscn")
]

@onready var player_node = get_player_node()

func get_player_node():
	var player_root = $Player
	for child in player_root.get_children():
		if "add_xp" in child:
			return child
	push_error("Player node with add_xp not found!")
	return null

@onready var spawn_list = [
	$NormalEnemySpawn,
	$NormalEnemySpawn2,
	$NormalEnemySpawn3,
	$NormalEnemySpawn4,
	$NormalEnemySpawn5
]

# Define all waves here, each array maps to spawn_list
# Null = nothing
var waves = [
	[0, 0, 0, 0, 0], # Wave 1
	[0, 1, 0, 1, 0], # Wave 2
	[1, 0, 1, 0, 1]  # Wave 3, etc.
]

var current_wave = 0
var living_enemies: Array = []

func _ready() -> void:
	start_wave(current_wave)

func start_wave(wave_index: int) -> void:
	if wave_index >= waves.size():
		print("All waves finished!")
		return
	
	print("Starting wave %d" % (wave_index + 1))
	living_enemies.clear()
	spawn_wave(waves[wave_index])

# For setting up specific enemies per spawnpoint in a wave
func spawn_wave(enemy_indices: Array):
	for i in spawn_list.size():
		var spawn_point = spawn_list[i]
		var enemy_index = enemy_indices[i]
		if enemy_index == null:
			continue  # No enemy to spawn at this point
		var enemy_scene = enemy_list[enemy_index]
		var enemy_instance = enemy_scene.instantiate()
		enemy_instance.enemy_died.connect(player_node.add_xp)
		add_child(enemy_instance)
		enemy_instance.global_position = spawn_point.global_position
		living_enemies.append(enemy_instance)
		enemy_instance.tree_exited.connect(_on_enemy_died.bind(enemy_instance))

# Called when an enemy is removed from the scene tree
func _on_enemy_died(enemy):
	living_enemies.erase(enemy)
	if living_enemies.is_empty():
		print("Wave %d complete!" % (current_wave + 1))
		current_wave += 1
		start_wave(current_wave)
