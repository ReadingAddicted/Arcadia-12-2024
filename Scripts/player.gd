extends CharacterBody2D

# Assets
@onready var soundSwish:Array[AudioStream]=[preload("res://Sounds/wingedmacewoosh1.wav"),
						 preload("res://Sounds/wingedmacewoosh2.wav"),
						 preload("res://Sounds/wingedmacewoosh3.wav")]

const SPEED = 200
var targetVelocity=Vector2.ZERO
var currentVelocity=Vector2.ZERO
@onready var game:Node2D=get_parent()
@onready var camera:Camera2D=game.get_node("Camera")
@onready var baseScale=scale
@onready var sprite=$Sprite

func play(sound,where=Vector2(0,0)):
	game.play(sound,where)

func playPool(soundA:Array[AudioStream],where=Vector2(0,0)):
	game.playPool(soundA,where)

const PLAYER_DAMAGE_POINT_BASE=0.5
var damagePoint:float=PLAYER_DAMAGE_POINT_BASE # Time needed between the attack order and the attack landing

const PLAYER_RECOVERY_BASE=0.5
var recovery:float=PLAYER_RECOVERY_BASE # Idle time between the attack landing and being able to use another action

const PLAYER_DAMAGE_BASE=10
var damage:float=PLAYER_DAMAGE_BASE # Actual damage

const PLAYER_ATTACK_COOLDOWN_BASE=2
var attackCooldown=PLAYER_ATTACK_COOLDOWN_BASE

var attackSpeed:float=1 # Multiplicator of attack cooldown, damage point and recovery

const PLAYER_ATTACK_PHASE={
	NONE=0,
	LAUNCHED=1,
	RECOVERY=2
}

var attackPhase=PLAYER_ATTACK_PHASE.NONE
var attackTimer:float=0 # The actual incrementing timer

func resetToDefault():
	damagePoint=PLAYER_DAMAGE_POINT_BASE
	recovery=PLAYER_RECOVERY_BASE
	damage=PLAYER_DAMAGE_BASE
	attackCooldown=PLAYER_ATTACK_COOLDOWN_BASE

func attack():
	print("BONK")
	pass # TODO

func _ready():
	resetToDefault()
	print("ready")

func _process(delta: float) -> void:
	# Damage rythm
	if attackPhase==PLAYER_ATTACK_PHASE.NONE:
		scale=lerp(scale,baseScale,delta*10)
		if Input.get_action_strength("attack")>0:
			attackPhase=PLAYER_ATTACK_PHASE.LAUNCHED
	else:
		attackTimer+=delta*attackSpeed
	if attackPhase==PLAYER_ATTACK_PHASE.LAUNCHED:
		scale=lerp(scale,baseScale*1.2,delta*10)
		if attackTimer>damagePoint:
			attackTimer-=damagePoint
			attackPhase=PLAYER_ATTACK_PHASE.RECOVERY
			attack() # TODO
			playPool(soundSwish,position)
	if attackPhase==PLAYER_ATTACK_PHASE.RECOVERY:
		scale=lerp(scale,baseScale*0.8,delta*5)
		if attackTimer>recovery:
			attackTimer=0
			attackPhase=PLAYER_ATTACK_PHASE.NONE

func _physics_process(delta: float) -> void:
	targetVelocity=Input.get_vector("move_left","move_right","move_up","move_down")
	if attackPhase==PLAYER_ATTACK_PHASE.LAUNCHED:
		targetVelocity/=3
		if sprite.flip_h:
			targetVelocity.x+=0.1
		else:
			targetVelocity.x-=0.1
	if attackPhase==PLAYER_ATTACK_PHASE.RECOVERY:
		targetVelocity/=4
		if sprite.flip_h:
			targetVelocity.x-=0.1
		else:
			targetVelocity.x+=0.1
	currentVelocity=lerp(currentVelocity,targetVelocity,delta*10)
	velocity=currentVelocity*SPEED
	move_and_slide()
	camera.global_position=lerp(camera.global_position,global_position,delta*10)
	if velocity.length_squared() > 100:
		play_walk_animation(velocity)
	else:
		currentVelocity=lerp(currentVelocity,targetVelocity,delta*10)
		play_idle_animation()

func play_walk_animation(direction):
	sprite.play("move")
	if attackPhase==PLAYER_ATTACK_PHASE.NONE:
		if direction.x < 0:
			sprite.flip_h = true
		if direction.x > 0:
			sprite.flip_h = false

func play_idle_animation():
	sprite.play("idle")
