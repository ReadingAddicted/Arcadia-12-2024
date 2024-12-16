extends Node2D

@onready var audioManager=$AudioManager#preload("res://Scenes/AudioManager.tscn")
@onready var rng=RandomNumberGenerator.new()

func play(sound,where=Vector2(0,0)):
	audioManager.play(sound,where)

func playPool(soundA:Array[AudioStream],where=Vector2(0,0)):
	play(soundA.pick_random(),where)

# Returns a new group of targeted entities  
func groupGetHit(group:Array[Node2D],where:Vector2,ray:float)->Array[Node2D]:
	var bonked:Array[Node2D]=[]
	ray*=ray
	for e in group:
		if e.global_position.distance_squared_to(where)<=ray:
			bonked.append(e)
	return bonked

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass