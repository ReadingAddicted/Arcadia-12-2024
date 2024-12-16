extends Node2D

@onready var audioManager=$AudioManager#preload("res://Scenes/AudioManager.tscn")
@onready var rng=RandomNumberGenerator.new()

func play(sound,where=Vector2(0,0)):
	audioManager.play(sound,where)

func playPool(soundA,where=Vector2(0,0)):
	play(soundA[rng.randi_range(0,soundA.size()-1)],where)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
