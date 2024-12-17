extends Node2D

@onready var audioManager=$AudioManager#preload("res://Scenes/AudioManager.tscn")
@onready var rng=RandomNumberGenerator.new()
@onready var entityModel=preload("res://Scenes/entity.tscn")
var player

var model={
	"player":{
		"type":Entity.ENTITY_TYPE.PLAYER, # DON'T FORGET THE TYPE
		"canAttack":true,
		"maxLife":200,
		"movementSpeed":200,
		"damagePoint":0.5,
		"recovery":0.5,
		"damage":10,
		"attackCooldown":2,
		"collisionSize":32
	},
	"minion":{
		"type":Entity.ENTITY_TYPE.MINION,
		"canAttack":true,
		"maxLife":20,
		"movementSpeed":50,
		"damagePoint":0.5,
		"recovery":0.5,
		"damage":10,
		"attackCooldown":2,
		"collisionSize":16
	},
	"minionHeavy":{
		"type":Entity.ENTITY_TYPE.MINION,
		"canAttack":true,
		"maxLife":20,
		"movementSpeed":50,
		"damagePoint":0.75,
		"recovery":0.75,
		"damage":20,
		"attackCooldown":3,
		"collisionSize":16
	},
	"bakery":{
		"type":Entity.ENTITY_TYPE.BUILDING,
		"maxLife":1500,
		"canAttack":false,
		"spawnModel":"minion",
		"spawnMax":5,
		"factoryTime":20,
		"collisionSize":144
	}
	# etc etc
}

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

func modelApply(what:Entity,whatModel:String,where:Vector2=Vector2.ZERO)->void:
	print("created ",what)
	what.modelApply(model[whatModel])
	add_child(what)
	what.global_position=where

func spawn(whatModel:String,where:Vector2=Vector2.ZERO)->Entity:
	var m=entityModel.instantiate()
	call_deferred("modelApply",m,whatModel,where)
	print("spawn ",m)
	return m

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn("player",Vector2(50,50))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
