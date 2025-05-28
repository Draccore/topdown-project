extends Control

@onready var bar = $ProgressBar

func set_health(current: int, max: int) -> void:
	bar.max_value = max
	bar.value = current
