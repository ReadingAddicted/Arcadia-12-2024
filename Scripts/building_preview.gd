extends Node2D

@onready var game: Node2D = get_parent()
@onready var Sprite: AnimatedSprite2D = $Sprite
@onready var Background: Sprite2D = $Sprite/Background
@onready var hitBox: CollisionShape2D = $TakenArea/Hitbox
@onready var IsValid: CanvasModulate = $Sprite/Background/IsValid
var hitbox_size = Vector2(0,0)
var buildingPossible = false

func findByClass(node: Node, className : String, result : Array) -> void:
	for child in node.get_children():
		result.push_back(child)

func check_validity() -> void:
	buildingPossible = true
	#TODO
	if buildingPossible:
		IsValid.color = Color(0, 1, 0, 0.5)
	else:
		IsValid.color = Color(1, 0, 0, 0.5)

func set_hitbox_size(width: int, height: int) -> void:
	hitbox_size = Vector2(width, height)
	var rect_shape: RectangleShape2D = hitBox.shape
	rect_shape.extents = Vector2(width * 32, height * 32)

func set_sprite_animation(animation_name: String) -> void:
	Sprite.play(animation_name)
