extends CharacterBody2D

const SPEED = 100
var targetVelocity = Vector2.ZERO
var currentVelocity = Vector2.ZERO
@onready var game:Node2D = get_parent()
@onready var baseScale = scale

var team: bool = true

var target = null

# Attack and damage properties
const MINION_DAMAGE_POINT_BASE = 0.5
var damagePoint:float = MINION_DAMAGE_POINT_BASE
const MINION_RECOVERY_BASE = 0.5
var recovery:float = MINION_RECOVERY_BASE
const MINION_DAMAGE_BASE = 10
var damage:float = MINION_DAMAGE_BASE
const MINION_ATTACK_COOLDOWN_BASE = 2
var attackCooldown = MINION_ATTACK_COOLDOWN_BASE
var attackSpeed:float = 1

const MINION_ATTACK_PHASE = {
	NONE= 0,
	LAUNCHED= 1,
	RECOVERY= 2
}

var attackPhase = MINION_ATTACK_PHASE.NONE
var attackTimer:float = 0
var currentTarget:Node2D = null

# Detection and attack areas
@onready var detectionArea = $DetectionArea2D
@onready var attackArea = $AttackArea2D
var detectedEnemies = []
var inRangeEnemies = []
var canAttack = false

func resetToDefault():
	damagePoint = MINION_DAMAGE_POINT_BASE
	recovery = MINION_RECOVERY_BASE
	damage = MINION_DAMAGE_BASE
	attackCooldown = MINION_ATTACK_COOLDOWN_BASE

func attack():
	if currentTarget:
		print("BONK", currentTarget.name)
		# Apply damage logic here

func _ready():
	resetToDefault()
	print("minion ready")

func _process(delta: float) -> void:
	if canAttack && attackPhase == MINION_ATTACK_PHASE.NONE:
		attackPhase = MINION_ATTACK_PHASE.LAUNCHED
	
	# Attack phase logic
	if attackPhase == MINION_ATTACK_PHASE.NONE:
		scale = lerp(scale, baseScale, delta * 10)
	else:
		attackTimer += delta * attackSpeed

	if attackPhase == MINION_ATTACK_PHASE.LAUNCHED:
		scale = lerp(scale, baseScale * 1.2, delta * 10)
		if attackTimer > damagePoint:
			attackTimer -= damagePoint
			attackPhase = MINION_ATTACK_PHASE.RECOVERY
			attack()

	if attackPhase == MINION_ATTACK_PHASE.RECOVERY:
		scale = lerp(scale, baseScale * 0.8, delta * 5)
		if attackTimer > recovery:
			attackTimer = 0
			attackPhase = MINION_ATTACK_PHASE.NONE

func _physics_process(delta: float) -> void:
	if attackPhase == MINION_ATTACK_PHASE.NONE:
		if currentTarget:
			# Move toward the target
			targetVelocity = (currentTarget.global_position - global_position).normalized()
		else:
			targetVelocity = Vector2.ZERO

	currentVelocity = lerp(currentVelocity, targetVelocity, delta * 10)
	velocity = currentVelocity * SPEED
	move_and_slide()

	if velocity.length_squared() > 100:
		play_walk_animation(velocity)

func play_walk_animation(direction):
	$Sprite.flip_h = direction.x < 0

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
