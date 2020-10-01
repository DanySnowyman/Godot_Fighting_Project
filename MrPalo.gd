extends KinematicBody2D


var char_name = "MrPalo"
var player = 1

var last_position = Vector2()

var on_floor = true
var is_jumping = false
var jump_vertical = false
var jump_forward = false
var jump_backward = false
var dash_f_ready = false
var dash_b_ready = false

onready var tween = get_node("Tween")

const JUMP_HEIGHT = 80
const JUMP_LENGHT = 120
const JUMP_ASC_TIME = 0.4
const JUMP_DES_TIME = 0.4
const DASH_F_DIST = 80
const DASH_B_DIST = 60
const DASH_F_TIME = 0.4
const DASH_B_TIME = 0.4

func _ready():
	if player == 1:
		self.position = Vector2(120, 140)
	else: self.position = Vector2(164, 140)
	
	$AnimationPlayer.play("Stand")

func walk_forward(delta):
	if Input.is_action_pressed("ui_right") and on_floor == true:
		$AnimationPlayer.play("Walk forward")
		self.position.x += 200 * delta
		
	if Input.is_action_just_released("ui_right") and on_floor == true:
		$AnimationPlayer.play("Stand")

func walk_backwards(delta):
	if Input.is_action_pressed("ui_left") and on_floor == true:
		$AnimationPlayer.play("Walk backwards")
		self.position.x -= 100 * delta
		
	if Input.is_action_just_released("ui_left") and on_floor == true:
		$AnimationPlayer.play("Stand")

func jump_selector():
	if on_floor == true and is_jumping == false:
		if Input.is_action_pressed("ui_up"):
			on_floor = false
			is_jumping = true
			yield(get_tree().create_timer(0.05), "timeout")
			if Input.is_action_pressed("ui_right"):
				jump_forward = true
			elif Input.is_action_pressed("ui_left"):
				jump_backward = true
			else: jump_vertical = true

func jump_vertical():
	if jump_vertical == true:
		jump_vertical = false
		$AnimationPlayer.play("Jump vertical")
		yield(get_tree().create_timer(0.1), "timeout")
		#Arco ascendente --------------------------------
		tween.interpolate_property(self, "position:y",
			self.position.y, (self.position.y - JUMP_HEIGHT),
			JUMP_ASC_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_completed")
		#Arco descendente -------------------------------
		tween.interpolate_property(self, "position:y",
			self.position.y, (self.position.y + JUMP_HEIGHT),
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_completed")
		is_jumping = false
		on_floor = true
		$AnimationPlayer.play("Stand")

func jump_forward():
	if jump_forward == true:
		jump_forward = false
		$AnimationPlayer.play("Jump forward")
		yield(get_tree().create_timer(0.1), "timeout")
		#Arco ascendente --------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + JUMP_LENGHT / 2,
			JUMP_ASC_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_completed")
#		#Arco descendente -------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + JUMP_LENGHT / 2,
			JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y + JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_completed")
		yield($AnimationPlayer, "animation_finished")
		is_jumping = false
		on_floor = true
		$AnimationPlayer.play("Stand")

func jump_backward():
	if jump_backward == true:
		jump_backward = false
		$AnimationPlayer.play("Jump backward")
		yield(get_tree().create_timer(0.1), "timeout")
		#Arco ascendente --------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - JUMP_LENGHT / 2,
			JUMP_ASC_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_completed")
#		#Arco descendente -------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - JUMP_LENGHT / 2,
			JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y + JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_completed")
		yield($AnimationPlayer, "animation_finished")
		is_jumping = false
		on_floor = true
		$AnimationPlayer.play("Stand")

func dash_forward():
	if Input.is_action_just_pressed("ui_right") and dash_f_ready == false:
		dash_f_ready = true
		dash_b_ready = false
		yield(get_tree().create_timer(0.4), "timeout")
		dash_f_ready = false
		
	if on_floor == true and is_jumping == false:
		if Input.is_action_just_pressed("ui_right") and dash_f_ready == true:
			on_floor = false
			$AnimationPlayer.play("Dash forward")
			tween.interpolate_property(self, "position:x", self.position.x,
				self.position.x + DASH_F_DIST, DASH_F_TIME,
				Tween.TRANS_QUART, Tween.EASE_OUT)
			tween.start()
			yield(tween, "tween_completed")
			dash_f_ready = false
			on_floor = true
			$AnimationPlayer.play("Stand")
			
func dash_backward():
	if Input.is_action_just_pressed("ui_left") and dash_b_ready == false:
		dash_b_ready = true
		dash_f_ready = false
		yield(get_tree().create_timer(0.4), "timeout")
		dash_b_ready = false
		
	if on_floor == true and is_jumping == false:
		if Input.is_action_just_pressed("ui_left") and dash_b_ready == true:
			on_floor = false
			$AnimationPlayer.play("Dash backward")
			tween.interpolate_property(self, "position:x", self.position.x,
				self.position.x - DASH_B_DIST, DASH_B_TIME,
				Tween.TRANS_QUINT, Tween.EASE_OUT)
			tween.start()
			yield(tween, "tween_completed")
			dash_b_ready = false
			on_floor = true
			$AnimationPlayer.play("Stand")


func _process(delta):
	var motion = Vector2()
	
	walk_forward(delta)
	walk_backwards(delta)
	jump_selector()
	jump_vertical()
	jump_forward()
	jump_backward()
	dash_forward()
	dash_backward()
	
	motion = position - last_position
	last_position = position
	
