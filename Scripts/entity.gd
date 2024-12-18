extends CharacterBody2D
class_name Entity

# Assets
@onready var soundSwish:Array[AudioStream]=[preload("res://Sounds/wingedmacewoosh1.wav"),
						 preload("res://Sounds/wingedmacewoosh2.wav"),
						 preload("res://Sounds/wingedmacewoosh3.wav")]

var movementSpeed:float
var life:float
var maxLife:float
var lifeRegen:float

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

var damagePoint:float=0 # Time needed between the attack order and the attack landing, in seconds
var recovery:float=0 # Idle time between the attack landing and being able to use another action, in seconds
var damage:float # Actual damage
var attackCooldown # In seconds
var attackSpeed:float=1 # Multiplicator of attack cooldown, damage point and recovery
var attackRange:float=0 # in pixels

var animation={
	"idle":"EmptyAnimation",
	"move":"EmptyAnimation",
	"attack":"EmptyAnimation",
	"death":"EmptyAnimation"
}

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
	PROJECTILE=4, # Has set movement and lifetime
}

const ENTITY_ATTACK_TYPE={
	NONE=0, # No AI
	MELEE=1, # Direct damage
	RANGED=2, # Create Temporary projectile entity
	PROJECTILE=3, # Has set movement and lifetime
}

var type=ENTITY_TYPE.NONE
var attackType=ENTITY_ATTACK_TYPE.NONE

var attackPhase=ENTITY_ATTACK_PHASE.NONE
var attackTimer:float=0 # The actual incrementing timer
var currentTarget:Entity = null

# Detection and attack areas
@onready var detectionArea:Area2D = $DetectionArea2D
@onready var attackArea:Area2D = $AttackArea2D
@onready var hitBox:CollisionShape2D=$Hitbox
var hitBoxSize=1
var spriteShift=Vector2.ZERO

var detectedEnemies:Array[Entity] = []
var inRangeEnemies:Array[Entity] = []
var canAttack = false
var creator:Entity = null

func isAtRangeOfTarget()->bool:
	# Broke into two lines for readibilty
	if currentTarget!=null and is_instance_valid(currentTarget) and not currentTarget.dead:
		return attackRange<=0 or position.distance_squared_to(currentTarget.position)<=attackRange*attackRange
	return false

@export var spawnMax:int
var spawnCurrent:int
var spawnedBatch:Array[Entity]
var spawnModel:String
var dead:bool=false
var bulletModel=null

func creation(what:Entity):
	what.team=team
	what.creator=self
	what.global_position = position
	if team:
		what.global_position-=Vector2(hitBox.scale.x,0)
	else:
		what.global_position+=Vector2(hitBox.scale.x,0)
	if what.type == ENTITY_TYPE.PROJECTILE:
		what.targetVelocity = (currentTarget.global_position - what.global_position).normalized()
		print("projectile created")
	else:
		print("minion created")
		
	
var factoryCurrent:float=0
var factoryTime:float # In seconds

func factoryLoop(delta:float):
	if spawnCurrent<spawnMax:
		factoryCurrent+=delta
		if factoryCurrent>=factoryTime:
			factoryCurrent-=factoryTime
			spawnCurrent+=1
			var e=game.spawn(spawnModel)
			game.add_child(e)
			call_deferred("creation",e)
	else:
		factoryCurrent=0

# Called once
func death(killer:Entity=null):
	if dead:
		return
	dead=true
	# Disable collision
	collision_layer=0
	collision_mask=0
	play_death_animation()
	if spawnMax>0:
		for e in spawnedBatch:
			e.creator=null
	if creator!=null:
		creator.spawnedBatch.erase(self)

# Called to receive damage
# Returns the damage passing through
func hurt(amount:float,attacker:Entity=null)->float:
	if not dead:
		life-=amount
		if life<=0:
			death(attacker)
		if dead:
			return amount+life
	return 0
		
func attack():
	if type==ENTITY_TYPE.PLAYER or currentTarget:
		if currentTarget:
			if attackType==ENTITY_ATTACK_TYPE.MELEE:
				if inRangeEnemies.has(currentTarget):
					var damageAmount = currentTarget.hurt(damage, self)
					print("BONKED ", currentTarget.name," for ",damageAmount," health")
				else:
					print("Attack dodged")
			if attackType==ENTITY_ATTACK_TYPE.RANGED:
				var e=game.spawn("fireball")
				game.add_child(e)
				call_deferred("creation",e)
			if attackType==ENTITY_ATTACK_TYPE.PROJECTILE:
				var damageAmount = currentTarget.hurt(damage, creator)
				print("BONKED ", currentTarget.name," for ",damageAmount," health")
				self.queue_free()
		else:
			print("BONK")
		# Apply damage logic here

func modelApply(whatModel:Dictionary)->void:
	type=whatModel.type
	
	if whatModel.get("animationIdle")!=null:
		animation.idle=whatModel.animationIdle
	if whatModel.get("animationMove")!=null:
		animation.move=whatModel.animationMove
	if whatModel.get("animationAttack")!=null:
		animation.attack=whatModel.animationAttack
	if whatModel.get("animationDeath")!=null:
		animation.death=whatModel.animationDeath
	canAttack=whatModel.canAttack
	if whatModel.get("lifeRegen")!=null:
		lifeRegen=whatModel.lifeRegen
	if whatModel.get("attackRange")!=null:
		attackRange=whatModel.attackRange
	set_deferred("detectionArea.monitorable",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	set_deferred("detectionArea.monitoring",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	set_deferred("attackArea.monitorable",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	set_deferred("attackArea.monitoring",canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING))
	if whatModel.get("spriteShift")!=null:
		spriteShift=whatModel.spriteShift
		
		
	#detectionArea.monitoring=	canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING)
	#attackArea.monitorable=		canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING)
	#attackArea.monitoring=		canAttack and (type==ENTITY_TYPE.MINION or type==ENTITY_TYPE.BUILDING)
	if type==ENTITY_TYPE.BUILDING:
		spawnModel=whatModel.spawnModel
		if spawnModel!="":
			spawnMax=whatModel.spawnMax
			factoryTime=whatModel.factoryTime
		elif whatModel.bulletModel != "":
			bulletModel = whatModel.bulletModel
		$Hitbox.shape=RectangleShape2D.new()
	else:
		movementSpeed=whatModel.movementSpeed
	if canAttack:
		attackType=whatModel.attackType
		set_deferred("DetectionArea.DetectionCircle.scale", Vector2(whatModel.detectionSize, whatModel.detectionSize))
		set_deferred("AttackArea.AttackAreaCircle.scale", Vector2(whatModel.attackAreaSize, whatModel.attackAreaSize))
		if whatModel.get("damagePoint")!=null:
			damagePoint=whatModel.damagePoint
		if whatModel.get("recovery")!=null:
			recovery=whatModel.recovery
		damage=whatModel.damage
		attackCooldown=whatModel.attackCooldown
	hitBoxSize=whatModel.collisionSize

func _ready():
	if hitBox.shape is RectangleShape2D:
		hitBox.shape.size=Vector2(hitBoxSize,hitBoxSize)
	else:
		hitBox.shape.radius=hitBoxSize
	sprite.position=spriteShift
	print("ready")

func _process(delta: float) -> void:
	# Damage rythm
	if dead:
		attackPhase=ENTITY_ATTACK_PHASE.NONE
		factoryTime=0
		return
	
	life+=lifeRegen*delta
	if life>maxLife:
		life=maxLife
	if canAttack and attackPhase==ENTITY_ATTACK_PHASE.NONE:
		scale=lerp(scale,baseScale,delta*10)
		if (type==ENTITY_TYPE.PLAYER and Input.get_action_strength("attack")>0) or  ((type == ENTITY_TYPE.MINION or (type == ENTITY_TYPE.BUILDING and bulletModel != null)) and inRangeEnemies.size() > 0):
			attackPhase=ENTITY_ATTACK_PHASE.LAUNCHED
			play_attack_animation()
		else:
			if currentTarget!=null and not currentTarget.dead:
				attackPhase=ENTITY_ATTACK_PHASE.LAUNCHED
				play_attack_animation()
	else:
		attackTimer+=delta*attackSpeed
	if attackPhase==ENTITY_ATTACK_PHASE.LAUNCHED:
		scale=lerp(scale,baseScale*1.2,delta*10)
		if attackTimer>damagePoint:
			attackTimer-=damagePoint
			attackPhase=ENTITY_ATTACK_PHASE.RECOVERY
			attack()
			playPool(soundSwish,position)
	if attackPhase==ENTITY_ATTACK_PHASE.RECOVERY:
		scale=lerp(scale,baseScale*0.8,delta*5)
		if attackTimer>recovery:
			attackTimer=0
			attackPhase=ENTITY_ATTACK_PHASE.NONE
	if factoryTime>0:
		factoryLoop(delta)

func _physics_process(delta: float) -> void:
	if type==ENTITY_TYPE.BUILDING:
		play_idle_animation()
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
		play_idle_animation()
		if attackPhase == ENTITY_ATTACK_PHASE.NONE:
			if currentTarget:
				# Move toward the target
				# TODO stop when target is at range
				# TODO change target if not reached for a while
				targetVelocity = (currentTarget.global_position - global_position).normalized()
			else:
				# TODO when close to the opposite border, go down instead
				if team:
					targetVelocity=Vector2(-1,0)
				else:
					targetVelocity=Vector2(1,0)
	
	currentVelocity=lerp(currentVelocity,targetVelocity,delta*10)
	velocity=currentVelocity*movementSpeed
	
	if type==ENTITY_TYPE.PROJECTILE:
		play_idle_animation()
		velocity=targetVelocity*movementSpeed
	
	move_and_slide()
		
	if type==ENTITY_TYPE.PLAYER:
		camera.global_position=lerp(camera.global_position,global_position,delta*10)
	if attackPhase==ENTITY_ATTACK_PHASE.NONE:
		if velocity.length_squared() > 100:
			play_walk_animation(velocity)
		else:
			currentVelocity=lerp(currentVelocity,targetVelocity,delta*10)
			play_idle_animation()

func play_walk_animation(direction):
	sprite.play(animation.move)
	if attackPhase==ENTITY_ATTACK_PHASE.NONE:
		if direction.x < 0:
			sprite.flip_h = true
		if direction.x > 0:
			sprite.flip_h = false

func play_idle_animation():
	sprite.play(animation.idle)

func play_attack_animation():
	sprite.play(animation.attack)

func play_death_animation():
	sprite.play(animation.death)
# Detection area signals
func _on_detection_area_body_entered(body):
	print("body entered",body.name)
	if not body.dead and body.team != team:
		detectedEnemies.append(body)
		print("Enemy detected:", body.name)
		if not currentTarget:
			currentTarget = body

func _on_detection_area_body_exited(body):
	if body in detectedEnemies:
		detectedEnemies.erase(body)
		print("Enemy left:", body.name)
		if currentTarget == body:
			currentTarget=Game.groupGetClosest(self,detectedEnemies)

# Attack area signals
func _on_attack_area_body_entered(body):
	if body.team != team:
		inRangeEnemies.append(body)
		currentTarget = body
		canAttack = true
		print("Target in attack range:", body.name)
		if type == ENTITY_TYPE.PROJECTILE:
			attack()

func _on_attack_area_body_exited(body):
	if currentTarget == body:
		inRangeEnemies.erase(body)
		if inRangeEnemies.size() > 0:
			currentTarget = inRangeEnemies[0]
		elif detectedEnemies.size() > 0:
			currentTarget = detectedEnemies[0]
		else:
			currentTarget = null
		print("Target left attack range:", body.name)
	if body.type == ENTITY_TYPE.PROJECTILE && body.creator == self:
		body.death()

func _on_sprite_animation_finished() -> void:
	if dead:
# En gros on dit au jeu qu'on va le depop mais il ne va pas disparaîte extactement tout de suite
		queue_free()
	else:
		if sprite.get_animation()==animation.attack:
			play_idle_animation()
