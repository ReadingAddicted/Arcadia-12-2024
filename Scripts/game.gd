extends Node2D
class_name Game

@onready var audioManager=$AudioManager#preload("res://Scenes/AudioManager.tscn")
@onready var rng=RandomNumberGenerator.new()
@onready var entityModel=preload("res://Scenes/entity.tscn")
var player

var model={
	"player":{
		"type":Entity.ENTITY_TYPE.PLAYER, # DON'T FORGET THE TYPE
		"canAttack":true,
		"maxLife":200,
		"lifeRegen":1,
		"movementSpeed":200,
		"damagePoint":0.5,
		"recovery":0.5,
		"damage":10,
		"attackCooldown":2,
		"collisionSize":32,
		"animationIdle":"BakerIdle",
		"animationMove":"BakerMove",
		"animationAttack":"BakerAttack",
		"animationDeath":"BakerDeath"
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
		"collisionSize":16,
		"animationIdle":"MinionIdle",
		"animationMove":"MinionMove",
		"animationAttack":"MinionAttack",
		"animationDeath":"MinionDeath"
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
	if Input.get_action_raw_strength("spawn")>0:
		spawn("minion")

static func groupPurge(ug:Array[Entity])->void:
	for e in ug:
		if e==null or not is_instance_valid(e) or e.dead:
			ug.erase(e)

static func groupGetClosest(what:Entity,ug:Array[Entity])->Entity:
	if ug==null:
		return null
	
	Game.groupPurge(ug)
	if ug.size()<=0:
		return null
	
	if ug.size()==1:
		return ug[0]
	
	if ug.size()==2:
		return ug[0] if what.position.distance_squared_to(ug[0].position)<=what.position.distance_squared_to(ug[1].position) else ug[1]
	
	var closest:Entity=ug[0]
	var distance:float=what.position.distance_squared_to(closest.position)
	for e in ug:
		var d=what.position.distance_squared_to(e.position)
		if d<distance:
			d=distance
			closest=e
	return closest
