extends CharacterBody2D

const SPEED = 55*60

# Player States
enum Direction{ up, right, down, left, }
enum AnimationType { idle, walk, sprint, swing, fall }
@export var movement := Direction.down
@export var animation_type := AnimationType.idle

# Customm movement logic
var _prev := PackedByteArray()
func pressed_direction(direction: Direction) -> void:
	_prev.append(direction)
	movement = direction
	animation_type = AnimationType.walk;
func released_direction(direction: Direction) -> void:
	var pos := _prev.find(direction)
	if pos != -1:
		_prev.remove_at(pos)
	if _prev.is_empty():
		animation_type = AnimationType.idle
		return
	else:
		movement = _prev[-1] as Direction
	return

# The Plater animation Function
func play_animation() -> void:
	var anim = $AnimatedSprite2D
	var local_anim_type := animation_type
	anim.flip_h = true if movement == Direction.left else false
	if local_anim_type == AnimationType.sprint:
		local_anim_type = AnimationType.walk
		anim.speed_scale = 2
	else:
		anim.speed_scale = 1.4

	if local_anim_type == AnimationType.fall:
		anim.play("fall")
	else:
		var type = AnimationType.keys()[local_anim_type]
		match  movement:
			Direction.up:
				anim.play("up_"+type)
			Direction.right:
				anim.play("side_"+type)
			Direction.down:
				anim.play("down_"+type)
			Direction.left:
				anim.play("side_"+type)

func process_input() -> void:
	if Input.is_action_just_pressed("ui_up"):
		pressed_direction(Direction.up)
	elif Input.is_action_just_released("ui_up"):
		released_direction(Direction.up)
	
	if Input.is_action_just_pressed("ui_right"):
		pressed_direction(Direction.right)
	elif Input.is_action_just_released("ui_right"):
		released_direction(Direction.right)
	
	if Input.is_action_just_pressed("ui_down"):
		pressed_direction(Direction.down)
	elif Input.is_action_just_released("ui_down"):
		released_direction(Direction.down)
	
	if Input.is_action_just_pressed("ui_left"):
		pressed_direction(Direction.left)
	elif Input.is_action_just_released("ui_left"):
		released_direction(Direction.left)
	
	if Input.is_key_pressed(KEY_SHIFT):
		if animation_type == AnimationType.walk:
			animation_type = AnimationType.sprint

func _ready() -> void:
	_prev.resize(4)
	var anim = $AnimatedSprite2D
	anim.speed_scale = 2.0 if animation_type == AnimationType.sprint else 1.4
	anim.play("down_idle")

func _process(delta: float) -> void:
	play_animation()

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		process_input()
	#(Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_right") or\
	#Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left"))
	if animation_type == AnimationType.walk:
		velocity.x = SPEED if movement == Direction.right else -SPEED if movement == Direction.left else 0
		velocity.y = SPEED if movement == Direction.down else -SPEED if movement == Direction.up else 0
	elif animation_type == AnimationType.sprint:
		velocity.x = 2*SPEED if movement == Direction.right else -2*SPEED if movement == Direction.left else 0
		velocity.y = 2*SPEED if movement == Direction.down else -2*SPEED if movement == Direction.up else 0
	else:
		velocity.x = 0
		velocity.y = 0
		_prev.resize(0)
		animation_type = AnimationType.idle;
	velocity *= delta
	move_and_slide()
	#move_and_collide(velocity * delta * delta)

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	$Camera2D.enabled = is_multiplayer_authority()
