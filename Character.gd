extends CharacterBody2D


const SPEED = 500.0

const DASH_SPEED = 1200.0
const DASH_TIME = 0.15

const JUMP_VELOCITY = -700.0


const LEFT = -1
const RIGHT = 1

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

class Character:
	var on_ground = false
	var moving_left = false
	var moving_right = false
	var can_dash = true
	var dashing_left = 0
	var dashing_right = 0

var character = Character.new()

# Buttons
# (u)p
# (d)own
# (l)eft
# (r)ight
# (x)
# (y)
# (a)
# (b)
# (0) no input
const INPUT_BUFFER_LENGTH = 100
var input_buffer = []

class FrameInput:
	var anti
	var keys
	var max_next
	
	func _init(keys, max_next, anti=false):
		self.anti = anti
		self.keys = keys
		self.max_next = max_next

class Move:
	var name
	var inputs
	var function
	
	func _init(name, inputs, function):
		self.name = name
		self.inputs = inputs
		self.function = function

var moves = [
	Move.new("Jump", [FrameInput.new(["u"],0)], Callable(self, "c_jump")),
	Move.new("Left", [FrameInput.new(["l"],0)], Callable(self, "c_left")),
	Move.new("Right", [FrameInput.new(["r"],0,)], Callable(self, "c_right")),
	
	Move.new("Dash Left", [FrameInput.new(["l"],0), FrameInput.new(["l"],3,true), FrameInput.new(["l"],0)], Callable(self, "c_dash_left")),
	Move.new("Dash Right", [FrameInput.new(["r"],0), FrameInput.new(["r"],3,true), FrameInput.new(["r"],0)], Callable(self, "c_dash_right"))
]

func c_dash_left():
	character.dashing_left = DASH_TIME
	character.can_dash = false
	
func c_dash_right():
	character.dashing_right = DASH_TIME
	character.can_dash = false

func c_left():
	character.moving_left = true

func c_right():
	character.moving_right = true

func c_jump():
	if character.on_ground:
		velocity.y = JUMP_VELOCITY

func update_character(delta):
	character.on_ground = is_on_floor()
	if character.on_ground:
		character.can_dash = true
	character.moving_left = false
	character.moving_right = false
	character.dashing_left = max(0, character.dashing_left - delta)
	character.dashing_right = max(0, character.dashing_right - delta)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func check_for_move():
	if input_buffer.size() == 0:
		return
	
	# For every possible move
	for move in moves:
		var input_index = 0
		var matching = true
		var next_time = 0
		var n = len(move.inputs) - 1
		# Go backwards through the inputs
		while n >= 0:
			# Do we match the current input for the move
			if move.inputs[n].anti:
				for key in move.inputs[n].keys:
					# Break on in for anti
					if key in input_buffer[input_index]:
						matching = false
						break
			else:
				for key in move.inputs[n].keys:
					# Break on not in for non anti
					if key not in input_buffer[input_index]:
						matching = false
						break
			
			# If we do not match
			if !matching:
				# And we have no buffer time left for input
				if next_time == 0:
					# Exit out of the 
					break
				else:
					# Case when we still have buffer time left, so we 
					# still do have the possibility of matching
					matching = true
					next_time -= 1
			else:
				# Only move to next move if we matched
				n -= 1
				
				# Just matched an input, so update the next_time for
				# the following input in all cases except for the last input
				if n != 0:
					next_time = move.inputs[n].max_next
				
			
			input_index += 1
			
		# If we make it through all the inputs, and we are still matching,
		# run the function
		if matching:
			move.function.call()
			print(move.name)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var current_input = []
	if Input.is_action_pressed("up"):
		current_input.append("u")
	if Input.is_action_pressed("left"):
		current_input.append("l")
	if Input.is_action_pressed("right"):
		current_input.append("r")
	
	if current_input.size() == 0:
		current_input = ["0"]
		
	input_buffer.push_front(current_input)
	
	if input_buffer.size() >= INPUT_BUFFER_LENGTH:
		input_buffer.pop_back()


func _physics_process(delta):
	update_character(delta)
	
	
	# Add the gravity.
	#if character_on_ground:
	#if character.dashing_left == 0 and character.dashing_right == 0:
	if velocity.y > 0:
		velocity.y += 2 * gravity * delta
	else:
		velocity.y += gravity * delta


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	#if direction:
	#	velocity.x = direction * SPEED
	#else:
	#	

	check_for_move()

	if character.dashing_left > 0:
		velocity.x = LEFT * DASH_SPEED
	elif character.dashing_right > 0:
		velocity.x = RIGHT * DASH_SPEED
	elif character.moving_left and (character.dashing_right == 0 and character.dashing_left == 0):
		velocity.x = LEFT * SPEED
	elif character.moving_right and (character.dashing_right == 0 and character.dashing_left == 0):
		velocity.x = RIGHT * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
