extends CharacterBody2D

# Player's movement speed
const SPEED = 55*60

# Player States
enum Direction{ up, right, down, left, }
enum AnimationType { idle, walk, sprint, swing, fall }
@export var movement := Direction.down
@export var animation_type := AnimationType.idle

# True if this is the multiplayer authority
var AUTHORITY := false

# Customm movement logic for 4 (NOT `8`) directional movement
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
func process_ui_key(direction: Direction) -> void:
	var key_name: String = "ui_"+Direction.keys()[direction]
	if Input.is_action_just_pressed(key_name):
		pressed_direction(direction)
	elif Input.is_action_just_released(key_name):
		released_direction(direction)

func process_input() -> void:
	process_ui_key(Direction.up)
	process_ui_key(Direction.right)
	process_ui_key(Direction.down)
	process_ui_key(Direction.left)
	if Input.is_key_pressed(KEY_SHIFT):
		if animation_type == AnimationType.walk:
			animation_type = AnimationType.sprint

func _ready() -> void:
	_prev.resize(4)
	#assert(_prev.size() == 0)
	$AnimatedSprite2D.speed_scale = 2.0 if animation_type == AnimationType.sprint else 1.4
	$AnimatedSprite2D.play("down_idle")

# The Plater animation Function
func play_animation() -> void:
	var anim = $AnimatedSprite2D
	anim.flip_h = (movement == Direction.left)
	anim.speed_scale = 1.4
	if animation_type == AnimationType.fall:
		anim.play("fall")
		return
	
	var anim_name:String
	match movement:
		Direction.up:
			anim_name = "up_"
		Direction.down:
			anim_name = "down_"
		Direction.left, Direction.right:
			anim_name = "side_"
	match animation_type:
		AnimationType.idle:
			anim.play(anim_name+"idle")
		AnimationType.swing:
			anim.play(anim_name+"swing")
		AnimationType.sprint:
			anim.speed_scale = 2
			anim.play(anim_name+"walk")
		AnimationType.walk:
			anim.play(anim_name+"walk")

# Play animation on frame update, not physics update
func _process(delta: float) -> void:
	play_animation()

# Process input and move
func _physics_process(delta: float) -> void:
	if AUTHORITY:
		process_input()
		velocity.x = SPEED if movement == Direction.right else -SPEED if movement == Direction.left else 0
		velocity.y = SPEED if movement == Direction.down else -SPEED if movement == Direction.up else 0
		if not (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_right") or\
	 	Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left")):
			animation_type = AnimationType.idle

	if animation_type == AnimationType.idle:
		velocity *= 0
	elif animation_type == AnimationType.sprint:
		velocity *= 2*delta
	else:
		velocity *= delta
	move_and_slide()
	#move_and_collide(velocity * delta * delta)

#enable camra for our player
func _enter_tree():
	set_multiplayer_authority(name.to_int())
	AUTHORITY = is_multiplayer_authority()
	$Camera2D.enabled = AUTHORITY
