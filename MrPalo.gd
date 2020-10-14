extends KinematicBody2D


var char_name = "MrPalo"
var player = 1

var last_position = Vector2()


var current_state: String = "" #Standing, Crouching, Jumping
var is_standing = true
var is_crouched = false
var is_airborne = false
var is_falling = false
var is_air_stunned = false
var startup_frames = false

var dash_f_ready = false
var dash_b_ready = false

var can_dash_cancel = false

onready var tween = get_node("Tween")
onready var tween_h = get_node("Tween_h")

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
		self.position = Vector2(120, 195)
	else: self.position = Vector2(164, 195)
	
	current_state = "Standing"
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
	# TESTING ONLY ------------------------------------------------------------
	if Input.is_action_just_pressed("Test hit high"):
		on_hit()

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
	if is_air_stunned == false:
		tween.interpolate_property(self, "position:y",
			self.position.y, (self.position.y + JUMP_HEIGHT),
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_completed")
		if is_air_stunned == false:
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
		JUMP_ASC_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	yield(tween, "tween_all_completed")
	#Arco descendente -------------------------------
	if is_air_stunned == false:
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + JUMP_LENGHT / 2,
			JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y + JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
		if is_air_stunned == false:
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
	yield(tween, "tween_all_completed")
	#Arco descendente -------------------------------
	if is_air_stunned == false:
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - JUMP_LENGHT / 2,
			JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y + JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
		if is_air_stunned == false:
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
	$ProximityBox/ProxBox1.disabled = true
	$ProximityBox/ProxBox1.position = Vector2(0, 0)
	$ProximityBox/ProxBox1.shape.extents = Vector2(0, 0)

func on_hit():
	if is_standing == true:
		is_standing = false
		$AnimationPlayer.play("Hit stun high hard")
		yield($AnimationPlayer, "animation_finished")
		is_standing = true
		$AnimationPlayer.play("Stand")
	elif is_airborne == true:
		is_air_stunned = true
		tween.stop_all()
		$AnimationPlayer.play("Hit stun air")
		#Arco ascendente --------------------------------
		tween_h.interpolate_property(self, "position:x",
			self.position.x, self.position.x - 50,
			0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween_h.interpolate_property(self, "position:y",
			self.position.y, self.position.y - 50,
			0.5, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween_h.start()
		yield(tween_h, "tween_completed")
		#Arco descendente -------------------------------
		tween_h.interpolate_property(self, "position:x",
			self.position.x, self.position.x - 50,
			0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween_h.interpolate_property(self, "position:y",
			self.position.y, self.position.y + 250,
			0.6, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween_h.start()
		is_falling = true
		yield(tween_h, "tween_completed")
		yield($AnimationPlayer, "animation_finished")

func fall(delta):
	if is_falling == true:
		if self.position.y == 195:
			is_falling = false
			tween.stop_all()
			is_air_stunned = false
			is_standing = true
			is_airborne = false
			$AnimationPlayer.play("Stand")
			print("stop falling")

func boxes_auto_visibility():
	if $HitBoxes/HitBox1.disabled == true:
		$HitBoxes/HitBox1.visible = false
	else: $HitBoxes/HitBox1.visible = true
	
	if $HurtBoxes/HurtBox1.disabled == true:
		$HurtBoxes/HurtBox1.visible = false
	else: $HurtBoxes/HurtBox1.visible = true
	
	if $HurtBoxes/HurtBox2.disabled == true:
		$HurtBoxes/HurtBox2.visible = false
	else: $HurtBoxes/HurtBox2.visible = true
	
	if $HurtBoxes/HurtBox3.disabled == true:
		$HurtBoxes/HurtBox3.visible = false
	else: $HurtBoxes/HurtBox3.visible = true
	
	if $HurtBoxes/HurtBox4.disabled == true:
		$HurtBoxes/HurtBox4.visible = false
	else: $HurtBoxes/HurtBox4.visible = true
	
	if $ProximityBox/ProxBox1.disabled == true:
		$ProximityBox/ProxBox1.visible = false
	else: $ProximityBox/ProxBox1.visible = true 

func _process(delta):
	var motion = Vector2()
	
	player_control(delta)
	fall(delta)
	boxes_auto_visibility()
	
	motion = position - last_position
	last_position = position
	
	self.position.y = clamp(self.position.y, -100, 195)
