extends StaticBody2D

@onready var minion = preload("res://Scenes/minion.tscn")

func _on_timer_timeout() -> void:
	var child = minion.instantiate()
	child.position = $SpawningPoint.global_position
	get_parent().add_child(child)
