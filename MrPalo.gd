extends KinematicBody2D


var char_name = "MrPalo"
var player = 1

var last_position = Vector2()

var is_standing = true
var is_moving_right = false
var is_moving_left = false
var is_crouched = false
var is_airborne = false
var startup_frames = false

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

func player_control(delta):
	if is_standing == true:
		if Input.is_action_pressed("ui_left") and Input.is_action_pressed("ui_right"):
			stand()
		else:
	# Walk forward -----------------------------------------------------------
			if Input.is_action_pressed("ui_right"):
				walk_forward(delta)
			if Input.is_action_just_released("ui_right"):
				$AnimationPlayer.play("Stand")
	# Walk backwards ---------------------------------------------------------
			if Input.is_action_pressed("ui_left"):
				walk_backwards(delta)
			if Input.is_action_just_released("ui_left"):
				$AnimationPlayer.play("Stand")
	# Crouch -----------------------------------------------------------------
	if is_standing == true:
		if Input.is_action_pressed("ui_down"):
			is_crouched = true
			is_standing = false
			crouch()
	if is_crouched == true:
		if Input.is_action_just_released("ui_down"):
			is_crouched = false
			is_standing = true
			$AnimationPlayer.play_backwards("Crouch")
			$AnimationPlayer.play("Stand")
	# Jump -------------------------------------------------------------------
	if is_standing == true:
		if Input.is_action_pressed("ui_up"):
			is_standing = false
			yield(get_tree().create_timer(0.05), "timeout")
			if Input.is_action_pressed("ui_right"):
				jump_forward()
			elif Input.is_action_pressed("ui_left"):
				jump_backward()
			else: jump_vertical()
	# Dash forward ------------------------------------------------------------
	if Input.is_action_just_pressed("ui_right") and dash_f_ready == false:
		dash_f_ready = true
		dash_b_ready = false
		yield(get_tree().create_timer(0.2), "timeout")
		dash_f_ready = false
	if is_standing == true:
		if Input.is_action_just_pressed("ui_right") and dash_f_ready == true:
			is_standing = false
			dash_forward()
	# Dash backward -----------------------------------------------------------
	if Input.is_action_just_pressed("ui_left") and dash_b_ready == false:
		dash_b_ready = true
		dash_f_ready = false
		yield(get_tree().create_timer(0.2), "timeout")
		dash_b_ready = false
	if is_standing == true:
		if Input.is_action_just_pressed("ui_left") and dash_b_ready == true:
			is_standing = false
			dash_backward()
	# Normal MP ---------------------------------------------------------------
	if is_standing == true:
		if Input.is_action_just_pressed("ui_accept"):
			startup_frames = true
			is_standing = false
			normal_LP()

func stand():
	$AnimationPlayer.play("Stand")

func walk_forward(delta):
	$AnimationPlayer.play("Walk forward")
	self.position.x += 200 * delta

func walk_backwards(delta):
	$AnimationPlayer.play("Walk backwards")
	self.position.x -= 100 * delta

func crouch():
	$AnimationPlayer.play("Crouch")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.stop()

func jump_vertical():
	is_airborne = true
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
	is_airborne = false
	is_standing = true
	$AnimationPlayer.play("Stand")

func jump_forward():
	is_airborne = true
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
	is_airborne = false
	is_standing = true
	$AnimationPlayer.play("Stand")

func jump_backward():
	is_airborne = true
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
	is_airborne = false
	is_standing = true
	$AnimationPlayer.play("Stand")

func dash_forward():
	$AnimationPlayer.play("Dash forward")
	tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x + DASH_F_DIST, DASH_F_TIME,
		Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	is_standing = true
	$AnimationPlayer.play("Stand")

func dash_backward():
	$AnimationPlayer.play("Dash backward")
	tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x - DASH_B_DIST, DASH_B_TIME,
		Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_completed")
	is_standing = true
	$AnimationPlayer.play("Stand")
	
func normal_LP():
	$AnimationPlayer.play("Normal MP")
	yield($AnimationPlayer, "animation_finished")
	is_standing = true
	$AnimationPlayer.play("Stand")

func _process(delta):
	var motion = Vector2()
	
	player_control(delta)
	
	motion = position - last_position
	last_position = position
