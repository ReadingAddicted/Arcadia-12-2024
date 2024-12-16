extends CharacterBody2D

# Assets
@onready var soundSwish=[preload("res://Sounds/wingedmacewoosh1.wav"),
						 preload("res://Sounds/wingedmacewoosh2.wav"),
						 preload("res://Sounds/wingedmacewoosh3.wav")]

const SPEED = 200
var targetVelocity=Vector2.ZERO
var currentVelocity=Vector2.ZERO
@onready var game:Node2D=get_parent()
@onready var camera:Camera2D=game.get_node("Camera")

func play(sound,where=Vector2(0,0)):
	game.play(sound,where)

func playPool(soundA,where=Vector2(0,0)):
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
	if attackPhase==PLAYER_ATTACK_PHASE.NONE and Input.get_action_strength("attack")>0:
		attackPhase=PLAYER_ATTACK_PHASE.LAUNCHED
		playPool(soundSwish,position)
		print(position)
	# Damage rythm
	if attackPhase!=PLAYER_ATTACK_PHASE.NONE:
		attackTimer+=delta*attackSpeed
	if attackPhase==PLAYER_ATTACK_PHASE.LAUNCHED:
		if attackTimer>damagePoint:
			attackTimer-=damagePoint
			attackPhase=PLAYER_ATTACK_PHASE.RECOVERY
			attack() # TODO
	if attackPhase==PLAYER_ATTACK_PHASE.RECOVERY:
		if attackTimer>recovery:
			attackTimer=0
			attackPhase=PLAYER_ATTACK_PHASE.NONE

func _physics_process(delta: float) -> void:
	if attackPhase==PLAYER_ATTACK_PHASE.NONE:
		targetVelocity=Input.get_vector("move_left","move_right","move_up","move_down")
	else:
		targetVelocity=Vector2.ZERO
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
	$AnimatedSprite2D.play("move")
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = true
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = false

func play_idle_animation():
	$AnimatedSprite2D.play("idle")
