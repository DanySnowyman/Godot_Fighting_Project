extends KinematicBody2D


var char_name = "MrPalo"
var player = 1


var state: String
var last_position = Vector2()
var pre_jump = false
var startup_frames = false

var dash_f_ready = false
var dash_b_ready = false

var can_dash_cancel = false

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
		self.position = Vector2(120, 195)
	else: self.position = Vector2(164, 195)
	
	state = "STANDING"
	$AnimationPlayer.play("Stand")
	$State.set_as_toplevel(true)
	$State.set_global_position(Vector2(20, 20))
	
func player_control(delta):
	# Negate opposite directions ---------------------------------------------
	if state == "STANDING":
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
	if state == "STANDING":
		if Input.is_action_pressed("ui_down"):
			state = "CROUCHING"
			crouch()
	if state == "CROUCHING":
		if Input.is_action_just_released("ui_down"):
			state = "STANDING"
			$AnimationPlayer.play_backwards("Crouch")
			$AnimationPlayer.play("Stand")
	# Jump -------------------------------------------------------------------
	if state == "STANDING":
		if Input.is_action_pressed("ui_up"):
			state = "PRE_JUMP"
			yield(get_tree().create_timer(0.05), "timeout")
			if state == "PRE_JUMP":
				if Input.is_action_pressed("ui_right"):
					jump_forward()
				elif Input.is_action_pressed("ui_left"):
					jump_backward()
				else:
					jump_vertical()
	# Dash forward -----------------------------------------------------------
	if Input.is_action_just_pressed("ui_right") and dash_f_ready == false:
		dash_f_ready = true
		dash_b_ready = false
		yield(get_tree().create_timer(0.2), "timeout")
		dash_f_ready = false
	if state == "STANDING":
		if Input.is_action_just_pressed("ui_right") and dash_f_ready == true:
			dash_forward()
	# Dash backward -----------------------------------------------------------
	if Input.is_action_just_pressed("ui_left") and dash_b_ready == false:
		dash_b_ready = true
		dash_f_ready = false
		yield(get_tree().create_timer(0.2), "timeout")
		dash_b_ready = false
	if state == "STANDING":
		if Input.is_action_just_pressed("ui_left") and dash_b_ready == true:
			dash_backward()
	# Normal MP ---------------------------------------------------------------
	if state == "STANDING":
		if Input.is_action_just_pressed("Medium Punch"):
			startup_frames = true
			state = "ATTACKING"
			standing_MP()
	# Jumping HK --------------------------------------------------------------
	if state == "JUMPING":
		if Input.is_action_just_pressed("Heavy Kick"):
			startup_frames = true
			state = "ATTACKING"
			jumping_HK()
			
func manual_hitting():
	if Input.is_action_just_pressed("Test hit high"):
		on_hit()

func stand():
	state = "STANDING"
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
	$AnimationPlayer.play("Pre jump")
	yield($AnimationPlayer, "animation_finished")
	#Arco ascendente --------------------------------
	if state == "PRE_JUMP":
		$AnimationPlayer.play("Jump vertical")
		tween.interpolate_property(self, "position:y",
			self.position.y, (self.position.y - JUMP_HEIGHT),
			JUMP_ASC_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = "JUMPING"
		yield(tween, "tween_completed")
		#Arco descendente -------------------------------
		if state != "AIR_STUNNED":
			tween.interpolate_property(self, "position:y",
				self.position.y, (self.position.y + JUMP_HEIGHT),
				JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			yield(tween, "tween_completed")
			if state != "AIR_STUNNED":
				state = "STANDING"
				pre_jump = false
				$AnimationPlayer.play("Stand")

func jump_forward():
	$AnimationPlayer.play("Pre jump")
	yield($AnimationPlayer, "animation_finished")
	#Arco ascendente --------------------------------
	if state == "PRE_JUMP":
		$AnimationPlayer.play("Jump forward")
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + JUMP_LENGHT / 2,
			JUMP_ASC_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - JUMP_HEIGHT,
			JUMP_ASC_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = "JUMPING"
		yield(tween, "tween_all_completed")
		#Arco descendente -------------------------------
		if state != "AIR_STUNNED":
			tween.interpolate_property(self, "position:x",
				self.position.x, self.position.x + JUMP_LENGHT / 2,
				JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "position:y",
				self.position.y, self.position.y + JUMP_HEIGHT,
				JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			yield(tween, "tween_all_completed")
			if state != "AIR_STUNNED":
				state = "STANDING"
				pre_jump = false
				$AnimationPlayer.play("Stand")

func jump_backward():
	$AnimationPlayer.play("Pre jump")
	yield($AnimationPlayer, "animation_finished")
	#Arco ascendente --------------------------------
	if state == "PRE_JUMP":
		$AnimationPlayer.play("Jump backward")
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - JUMP_LENGHT / 2,
			JUMP_ASC_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = "JUMPING"
		yield(tween, "tween_all_completed")
		#Arco descendente -------------------------------
		if state != "AIR_STUNNED":
			tween.interpolate_property(self, "position:x",
				self.position.x, self.position.x - JUMP_LENGHT / 2,
				JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "position:y",
				self.position.y, self.position.y + JUMP_HEIGHT,
				JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			yield(tween, "tween_all_completed")
			if state != "AIR_STUNNED":
				state = "STANDING"
				pre_jump = false
				$AnimationPlayer.play("Stand")

func dash_forward():
	$AnimationPlayer.play("Dash forward")
	tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x + DASH_F_DIST, DASH_F_TIME,
		Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
	state = "DASHING"
	yield(tween, "tween_completed")
	if state != "AIR_STUNNED":
		state = "STANDING"
		$AnimationPlayer.play("Stand")

func dash_backward():
	$AnimationPlayer.play("Dash backward")
	tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x - DASH_B_DIST, DASH_B_TIME,
		Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	state = "DASHING"
	yield(tween, "tween_completed")
	if state != "AIR_STUNNED":
		state = "STANDING"
		$AnimationPlayer.play("Stand")

func standing_MP():
	$AnimationPlayer.play("Attack standing MP")
	yield($AnimationPlayer, "animation_finished")
	state = "STANDING"
	$AnimationPlayer.play("Stand")
	$ProximityBox/ProxBox1.disabled = true

func jumping_HK():
	$AnimationPlayer.play("Attack jumping HK")
	yield($AnimationPlayer, "animation_finished")
	$ProximityBox/ProxBox1.disabled = true

func fall():
	if state == "FALLING":
		if self.position.y == 195:
			tween.remove_all()
			ground_impact()
			pre_jump = false
			
func ground_impact():
	if state == "FALLING":
		state = "GROUND_IMPACT"
		$AnimationPlayer.play("Ground impact")
		tween.interpolate_property(self, "position:x", self.position.x,
				self.position.x - 20, 0.5,
				Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield($AnimationPlayer, "animation_finished")
		wake_up()

func wake_up():
	if state == "GROUND_IMPACT":
		state = "WAKING_UP"
		$AnimationPlayer.play("Wake up")
		yield($AnimationPlayer, "animation_finished")
		stand()

func on_hit():
#	tween.remove_all()
	if state == "STANDING" or state == "PRE_JUMP":
		state = "HIT_STUNNED"
		$AnimationPlayer.play("Hit stun high hard")
		yield($AnimationPlayer, "animation_finished")
		state = "STANDING"
		pre_jump = false
		$AnimationPlayer.play("Stand")
	elif state == "JUMPING" or state == "DASHING":
		state = "AIR_STUNNED"
		$AnimationPlayer.play("Hit stun air")
		#Arco ascendente --------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - 50,
			0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - 50,
			0.5, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_all_completed")
		#Arco descendente -------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - 50,
			0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y + 500,
			0.5, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
		state = "FALLING"
	else: print("simultaneo!")

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

func disable_hurt_boxes():
	$HurtBoxes/HurtBox1.disabled = true
	$HurtBoxes/HurtBox2.disabled = true
	$HurtBoxes/HurtBox3.disabled = true
	$HurtBoxes/HurtBox4.disabled = true
	
func _process(delta):
	var motion = Vector2()
	
	player_control(delta)
	manual_hitting()
	fall()
	boxes_auto_visibility()
	
	motion = position - last_position
	last_position = position
	
	self.position.y = clamp(self.position.y, -100, 195)
	
	$State.text = str(state)
