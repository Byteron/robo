extends KinematicBody2D

# MOVEMENT CONSTANTS
const GRAVITY = 10
const UP = Vector2(0,-1)

# CHARACTER MOVEMENT CONSTANTS
#const SPEED_MIN = 10
const ACCELERATION = 15
const DECELERATION = 30
const JUMPCOST = 10
const TIMER_MAX = 400

# CHARACTER STATES
onready var state = { 
	move = $StatesMovement, 
	attack = $StatesAttack
}

# CHARACTER STATS
var HEALTH_MAX = 10
var SPEED_MAX = 60
var ENERGY_MAX = 60
var JUMPFORCE = 160
var REGENERATION = 100

var health = null
var energy = null

# INPUT
var move_left
var move_right
var move_up
var move_down
var jump

var jumping = false

# MOVEMENT
var direction = { 
	input = Vector2(),
	move = Vector2(), 
	look = Vector2()
}
var speed = Vector2()
var motion = Vector2()
var jump_time = null
var timer = null

func _ready():
	set_process(true)
	set_physics_process(true)
	
	# RayCast2D.add_exception("node")
	state.move.change(state.move.IDLE)
	state.attack.change(state.attack.READY)
	
	health = HEALTH_MAX
	energy = ENERGY_MAX
	timer = TIMER_MAX

func _input(event):
	if event.is_action_released("jump"):
		jumping = false
func _process(delta):
	print(state.move.get_current_string())
	update_ui()

func _physics_process(delta):


	if is_on_ceiling(): 
		speed.y = 0
		
#	if speed.y < 0:
#		jumping = true
#	elif speed.y > 0:
#		jumping = false
#	elif on_floor():
#		jumping = false
		
	speed += Vector2(0, GRAVITY)
	
	# INPUT
	move_left = Input.is_action_pressed("move_left")
	move_right = Input.is_action_pressed("move_right")
	move_down = Input.is_action_pressed("move_down")
	move_up = Input.is_action_pressed("move_up")
	if not jumping and energy > JUMPCOST:
		jump = Input.is_action_pressed("jump")
	else:
		jump = null

	if move_left and not move_right:
		direction.input.x = -1
	elif move_right and not move_left:
		direction.input.x = 1
	else: direction.input.x = 0
	
	if move_up and not move_down:
		direction.input.y = -1
	elif move_down and not move_up:
		direction.input.y = 1
	else:
		direction.input.y = 0
		
		# HANDLE STATES
	match state.move.current:
		
		# I D L E
		state.move.IDLE:
			regenerate_energy(delta)
				
			if move_left and not on_wall_look() or move_right and not on_wall_look():
				state.move.change(state.move.WALK)
			elif jump:
				state.move.change(state.move.JUMP)
			elif move_up and energy > 0 and on_wall_look():
				state.move.change(state.move.CLIMB)
			pass
		
		# W A L K
		state.move.WALK:
			regenerate_energy(delta)

			if direction.input.x == 1 and not on_wall_look(): 
				speed.x += ACCELERATION
			elif direction.input.x == -1 and not on_wall_look():
				speed.x -= ACCELERATION
			else: 
				speed.x = int(speed.x * 0.6)
			
			if not motion and on_floor():
				state.move.change(state.move.IDLE)
			elif jump and on_floor():
				state.move.change(state.move.JUMP)
			elif move_up and energy > 0 and on_wall_look():
				state.move.change(state.move.CLIMB)
			elif not on_floor():
				state.move.change(state.move.FALL)

			speed.x = clamp(speed.x, -SPEED_MAX, SPEED_MAX)
			motion.x = speed.x
		
#		# D A S H
#		state.move.DASH:
#			energy -= 500 * delta
#
#			speed.x = 350
#
#			if not motion and on_floor() or energy < 0:
#				state.move.change(state.move.IDLE)
#
#			speed.x = clamp(speed.x, 0, 350)
#			motion.x = speed.x * direction.input.x
#			pass
			
		# J U M P
		state.move.JUMP:
			
			if direction.input.x == 1 and not on_wall_look(): 
				speed.x += ACCELERATION / 5
			elif direction.input.x == -1 and not on_wall_look():
				speed.x -= ACCELERATION / 5
			
			if jump and on_floor():
				speed.y = -JUMPFORCE
				energy -= JUMPCOST
				jumping = true
				print("floor jump")
			
			if jump and on_wall() and not on_floor():
				speed.y = -JUMPFORCE
				if on_wall_look():
					speed.x = -SPEED_MAX * direction.look.x
				else:
					speed.x = SPEED_MAX * direction.look.x 
				energy -= JUMPCOST
				jumping = true
				print("wall jump")
			
			speed.x = clamp(speed.x, -SPEED_MAX, SPEED_MAX)
			motion.x = speed.x
			
			if speed.y > 0:
				state.move.change(state.move.FALL)
			elif speed.y > 0 and not on_wall_look(): # or on_wall() and not on_wall_look():
				state.move.change(state.move.WALL)
			elif on_floor() and speed.y == 0:
				state.move.change(state.move.IDLE)
		
		# C L I M B
		state.move.CLIMB:
				
				if move_up:
					speed.y = -SPEED_MAX / 3
					energy -= 15 * delta
				
				if on_wall() and not on_wall_look():
					state.move.change(state.move.WALL)
				if not move_up or energy <= 0 or not on_wall():
					state.move.change(state.move.FALL)
				if on_floor():
					state.move.change(state.move.IDLE)
		# F A L L
		state.move.FALL:
			
			if direction.input.x == 1 and not on_wall_look(): 
				speed.x += ACCELERATION
			elif direction.input.x == -1 and not on_wall_look():
				speed.x -= ACCELERATION
			
			if not motion.x and on_floor():
				state.move.change(state.move.IDLE)
			if motion.x and on_floor():
				state.move.change(state.move.WALK)
			if on_wall_input() and energy > 0:
				state.move.change(state.move.WALL)
			if on_wall() and jump:
				state.move.change(state.move.JUMP)

			speed.x = clamp(speed.x, -SPEED_MAX, SPEED_MAX)
			motion.x = speed.x

		# W A L L
		state.move.WALL:
			
			speed.y = GRAVITY
			energy -= 10 * delta

			if direction.input.x and not on_wall_look():
				timer -= delta * 1000
				timer = clamp(timer, 0, TIMER_MAX)
				if timer == 0:
					speed.x += ACCELERATION
			else:
				speed.x -= DECELERATION
			
			if energy < 1 or not on_wall():
				state.move.change(state.move.FALL)
				timer = TIMER_MAX
			elif jump:
				state.move.change(state.move.JUMP)
				timer = TIMER_MAX
			elif move_up and energy > 0 and on_wall_look():
				state.move.change(state.move.CLIMB)
				timer = TIMER_MAX
			elif motion.x and on_floor():
				state.move.change(state.move.WALK)
			elif not motion.x and on_floor():
				state.move.change(state.move.IDLE)
				
			speed.x = clamp(speed.x, 0, SPEED_MAX)
			motion.x = speed.x * direction.input.x
			
	if motion.y < 0: 
		direction.move.y = -1
	elif motion.y > 0: 
		direction.move.y = 1
	else: direction.move.y = 0
	
	if motion.x > 0:
		direction.move.x = 1
		$Sprite.set_flip_h(false)
	elif motion.x < 0:
		direction.move.x = -1
		$Sprite.set_flip_h(true)
	else:
		direction.move.x = 0
	
	if direction.input.x: 
		direction.look.x = direction.input.x

#	if not motion.x or direction.input.x == - direction.move.x:
#		if direction.input.x == - direction.move.x:
#			speed.x = 0

#	if direction.input.x or not motion.x:
#		direction.move.x = direction.input.x
	
	if state.move.current == state.move.DASH:
		speed.y = 0
	
	motion.y = speed.y
	motion = move_and_slide(motion, UP)
	speed.y = motion.y

	energy = clamp(energy, 0, ENERGY_MAX)
	
#	jump = null

func on_floor():
	return $detect_floor_left.is_colliding() or $detect_floor_right.is_colliding()
		
#		if $detect_floor_left.is_colliding() or $detect_floor_right.is_colliding():
#		var collider = RayCast2D.get_collider()
#		if collider

func on_wall():
	return $detect_wall_left.is_colliding() or $detect_wall_right.is_colliding()

func on_wall_look():
	if direction.look.x == 1 and $detect_wall_right.is_colliding():
		return true
	elif direction.look.x == -1 and $detect_wall_left.is_colliding():
		return true
	else:
		return false

func on_wall_input():
	if direction.input.x == 1 and $detect_wall_right.is_colliding():
		return true
	elif direction.input.x == -1 and $detect_wall_left.is_colliding():
		return true
	else:
		return false

func regenerate_energy(delta):
	if energy < ENERGY_MAX:
				energy += REGENERATION * delta

func on_attack_animation_finished():
	state.attack.change(state.attack.READY)

func update_ui():
	$UI/Labels/Health.set_text(str("Health: ", health))
	$UI/Labels/Energy.set_text(str("Energy: ", int(energy)))
	
	$Debug/Labels/Timer.set_text(str("Timer: ", timer))
	$Debug/Labels/Motion.set_text(str("Motion: ", motion))
	$Debug/Labels/State.set_text(str("State: ", state.move.get_current_string(), " (", state.move.get_previous_string(), ")"))
	$Debug/Labels/Attack.set_text(str("Attack: ", state.attack.get_current_string(), " (", state.attack.get_previous_string(), ")"))
	$Debug/Labels/OnFloor.set_text(str("Floor: ", on_floor()))
	$Debug/Labels/OnWall.set_text(str("Wall: ", on_wall()))
	$Debug/Labels/Jumping.set_text(str("Jumping: ", jumping))
	
	
	$Debug/Labels/Input.set_text(str("Input: ", direction.input))
	$Debug/Labels/Move.set_text(str("Move: ", direction.move))
	$Debug/Labels/Look.set_text(str("Look: ", direction.look))
