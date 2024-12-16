extends CharacterBody2D

const SPEED = 200
var targetVelocity=Vector2.ZERO
var currentVelocity=Vector2.ZERO
@onready var camera:Camera2D=get_parent().get_node("Camera")

func _ready():
	print("ready")

func _physics_process(delta: float) -> void:
	targetVelocity=Input.get_vector("move_left","move_right","move_up","move_down")
	currentVelocity=lerp(currentVelocity,targetVelocity,delta*10)
	velocity=currentVelocity*SPEED
	move_and_slide()
	camera.global_position=lerp(camera.global_position,global_position,delta*10)
	if velocity.length() > 0:
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
