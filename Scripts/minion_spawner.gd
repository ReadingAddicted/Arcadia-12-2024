extends StaticBody2D

@export var team: bool = true
@onready var minion = preload("res://Scenes/minion.tscn")
@export var max_minions: int = 5
var amount_minions: int = 0

func _on_timer_timeout() -> void:
	if(amount_minions < max_minions):
		var child = minion.instantiate()
		child.team = team
		child.creator = self
		child.position = $SpawningPoint.global_position
		get_parent().add_child(child)
		amount_minions += 1
