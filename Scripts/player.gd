extends CharacterBody2D


const SPEED = 50


func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = direction * SPEED
	move_and_slide()
	
	if direction.length() > 0:
		play_walk_animation(direction)
	else:
		play_idle_animation()

func play_walk_animation(direction):
	$AnimatedSprite2D.play("move")
	if direction.x < 0:
		$AnimatedSprite2D.flip_h = true
	if direction.x > 0:
		$AnimatedSprite2D.flip_h = false

func play_idle_animation():
	$AnimatedSprite2D.play("idle")
