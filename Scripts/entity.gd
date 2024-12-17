extends CharacterBody2D
class_name Entity

# Assets
@onready var soundSwish:Array[AudioStream]=[preload("res://Sounds/wingedmacewoosh1.wav"),
						 preload("res://Sounds/wingedmacewoosh2.wav"),
						 preload("res://Sounds/wingedmacewoosh3.wav")]

var movementSpeed
var life
var maxLife

var targetVelocity=Vector2.ZERO
var currentVelocity=Vector2.ZERO
@onready var game:Node2D=get_parent()
@onready var camera:Camera2D=game.get_node("Camera")
@onready var baseScale=scale
@onready var sprite=$Sprite

var team:bool=false

func play(sound,where=Vector2(0,0)):
	game.play(sound,where)

func playPool(soundA:Array[AudioStream],where=Vector2(0,0)):
	game.playPool(soundA,where)

const ENTITY_DAMAGE_POINT_BASE=0.5
var damagePoint:float=ENTITY_DAMAGE_POINT_BASE # Time needed between the attack order and the attack landing

const ENTITY_RECOVERY_BASE=0.5
var recovery:float=ENTITY_RECOVERY_BASE # Idle time between the attack landing and being able to use another action

const ENTITY_DAMAGE_BASE=10
var damage:float=ENTITY_DAMAGE_BASE # Actual damage

const ENTITY_ATTACK_COOLDOWN_BASE=2
var attackCooldown=ENTITY_ATTACK_COOLDOWN_BASE

var attackSpeed:float=1 # Multiplicator of attack cooldown, damage point and recovery

const ENTITY_ATTACK_PHASE={
	NONE=0,
	LAUNCHED=1,
	RECOVERY=2
}

const ENTITY_TYPE={
	NONE=0, # No AI
	PLAYER=1, # No AI, controlled by keyboard, one at a time !
	MINION=2, # Has AI, moves
	BUILDING=3, # Has AI
}

var type=ENTITY_TYPE.NONE

var attackPhase=ENTITY_ATTACK_PHASE.NONE
var attackTimer:float=0 # The actual incrementing timer
var currentTarget:Node2D = null

# Detection and attack areas
@onready var detectionArea:Area2D = $DetectionArea2D
@onready var attackArea:Area2D = $AttackArea2D
@onready var hitBox:CollisionShape2D=$Hitbox

var detectedEnemies = []
var inRangeEnemies = []
var canAttack = false
var creator: Node2D = null

@export var spawnMax:int
var spawnCurrent:int
var spawnedBatch:Array[Entity]
var spawnModel:String

func _on_timer_timeout() -> void:
	if(spawnCurrent < spawnMax):
		spawnCurrent+=1
		pass
		# TODO
		#var child = minion.instantiate()
		#child.team=team
		#child.creator= self
		#child.position= $SpawningPoint.global_position
		#get_parent().add_child(child)

func attack():
	if type==ENTITY_TYPE.PLAYER or currentTarget:
		if currentTarget:
			print("BONK", currentTarget.name)
		else:
			print("BONK")
		# Apply damage logic here

func modelApply(whatModel)->void:
	type=whatModel.type
	
	canAttack=whatModel.canAttack
	set_deferred("detectionArea.monitorable",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	set_deferred("detectionArea.monitoring",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	set_deferred("attackArea.monitorable",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	set_deferred("attackArea.monitoring",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	#detectionArea.monitoring=	canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING)
	#attackArea.monitorable=		canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING)
	#attackArea.monitoring=		canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING)
	if type==ENTITY_TYPE.BUILDING:
		spawnModel=whatModel.spawnModel
		if spawnModel!="":
			spawnMax=whatModel.spawnMax
		hitBox.shape=RectangleShape2D.new()
	else:
		movementSpeed=whatModel.movementSpeed
	if canAttack:
		damagePoint=whatModel.damagePoint
		recovery=whatModel.recovery
		damage=whatModel.damage
		attackCooldown=whatModel.attackCooldown
	set_deferred("hitBox.scale",Vector2(whatModel.collisionSize,whatModel.collisionSize))
	
func resetToDefault():
	damagePoint=ENTITY_DAMAGE_POINT_BASE
	recovery=ENTITY_RECOVERY_BASE
	damage=ENTITY_DAMAGE_BASE
	attackCooldown=ENTITY_ATTACK_COOLDOWN_BASE

func _ready():
	resetToDefault()
	print("ready")

func _process(delta: float) -> void:
	# Damage rythm
	if canAttack and attackPhase==ENTITY_ATTACK_PHASE.NONE:
		scale=lerp(scale,baseScale,delta*10)
		if type==ENTITY_TYPE.PLAYER and Input.get_action_strength("attack")>0:
			attackPhase=ENTITY_ATTACK_PHASE.LAUNCHED
	else:
		attackTimer+=delta*attackSpeed
	if attackPhase==ENTITY_ATTACK_PHASE.LAUNCHED:
		scale=lerp(scale,baseScale*1.2,delta*10)
		if attackTimer>damagePoint:
			attackTimer-=damagePoint
			attackPhase=ENTITY_ATTACK_PHASE.RECOVERY
			attack() # TODO
			playPool(soundSwish,position)
	if attackPhase==ENTITY_ATTACK_PHASE.RECOVERY:
		scale=lerp(scale,baseScale*0.8,delta*5)
		if attackTimer>recovery:
			attackTimer=0
			attackPhase=ENTITY_ATTACK_PHASE.NONE

func _physics_process(delta: float) -> void:
	if type==ENTITY_TYPE.BUILDING:
		return
	
	if type==ENTITY_TYPE.PLAYER:
		targetVelocity=Input.get_vector("move_left","move_right","move_up","move_down")
		if attackPhase==ENTITY_ATTACK_PHASE.LAUNCHED:
			targetVelocity/=3
			if sprite.flip_h:
				targetVelocity.x+=0.1
			else:
				targetVelocity.x-=0.1
		if attackPhase==ENTITY_ATTACK_PHASE.RECOVERY:
			targetVelocity/=4
			if sprite.flip_h:
				targetVelocity.x-=0.1
			else:
				targetVelocity.x+=0.1
	
	if type==ENTITY_TYPE.MINION:
		if attackPhase == ENTITY_ATTACK_PHASE.NONE:
			if currentTarget:
				# Move toward the target
				targetVelocity = (currentTarget.global_position - global_position).normalized()
			else:
				targetVelocity = Vector2.ZERO
	
	currentVelocity=lerp(currentVelocity,targetVelocity,delta*10)
	velocity=currentVelocity*movementSpeed
	
	move_and_slide()
		
	if type==ENTITY_TYPE.PLAYER:
		camera.global_position=lerp(camera.global_position,global_position,delta*10)
	if velocity.length_squared() > 100:
		play_walk_animation(velocity)
	else:
		currentVelocity=lerp(currentVelocity,targetVelocity,delta*10)
		play_idle_animation()

func play_walk_animation(direction):
	sprite.play("move")
	if attackPhase==ENTITY_ATTACK_PHASE.NONE:
		if direction.x < 0:
			sprite.flip_h = true
		if direction.x > 0:
			sprite.flip_h = false

func play_idle_animation():
	sprite.play("idle")

# Detection area signals
func _on_detection_area_body_entered(body):
	print("body entered",body.name)
	if body.team != team:
		detectedEnemies.append(body)
		print("Enemy detected:", body.name)
		if not currentTarget:
			currentTarget = body

func _on_detection_area_body_exited(body):
	if body in detectedEnemies:
		detectedEnemies.erase(body)
		print("Enemy left:", body.name)
		if currentTarget == body:
			currentTarget = detectedEnemies[0] if detectedEnemies.size() > 0 else null

# Attack area signals
func _on_attack_area_body_entered(body):
	if body.team != team:
		inRangeEnemies.append(body)
		currentTarget = body
		canAttack = true
		print("Target in attack range:", body.name)

func _on_attack_area_body_exited(body):
	if currentTarget == body:
		inRangeEnemies.erase(body)
		if inRangeEnemies.size() > 0:
			currentTarget = inRangeEnemies[0]
		elif detectedEnemies.size() > 0:
			currentTarget = detectedEnemies[0]
			canAttack = false
		else:
			currentTarget = null
			canAttack = false
		print("Target left attack range:", body.name)
