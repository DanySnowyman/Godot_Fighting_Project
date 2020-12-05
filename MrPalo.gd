extends Area2D


var char_name = "MrPalo"
var player
var Px

enum is_ {STANDING, CROUCHING, DASHING, PRE_JUMP, JUMPING, ATTACKING, AIR_ATTACKING, BLOCKING,
	HIT_STUNNED, AIR_STUNNED, FALLING, GROUND_IMPACT, KNOCKED_DOWN, WAKING_UP}
var state
var facing_right = true
var waiting_for_flip = false
var last_position = Vector2()
var pre_jump = false
var startup_frames = false
var dash_r_ready = false
var dash_l_ready = false
var sp_input_count = 0

var can_dash_cancel = false

onready var tween = get_node("Tween")

var WALK_FORWARD_SPEED = 200
var WALK_BACKWARD_SPEED = 150
const JUMP_HEIGHT = 80
var JUMP_F_LENGHT = 120
var JUMP_B_LENGHT = 100
const JUMP_ASC_TIME = 0.4
const JUMP_DES_TIME = 0.4
var DASH_F_DIST = 80
var DASH_B_DIST = 60
const DASH_F_TIME = 0.4
const DASH_B_TIME = 0.4
var AIRBORNE_HIT_LENGHT = 100
var GROUND_IMPACT_LENGHT = 20

var can_guard = false
var is_blocking = false

func _ready():
	if player == 1:
		self.position = Vector2(120, 195)
		Px = "P1"
		facing_right = true
		$State.set_as_toplevel(true)
		$State.set_global_position(Vector2(20, 20))
	else:
		self.position = Vector2(264, 195)
		Px = "P2"
		facing_right = false
		$State.set_as_toplevel(true)
		$State.ALIGN_RIGHT
		$State.set_global_position(Vector2(300, 20))
		
	state = is_.STANDING
	$AnimationPlayer.play("Stand")


func facing_direction():
	if waiting_for_flip == true and (state == is_.STANDING or state == is_.CROUCHING):
		waiting_for_flip = false
		facing_right = not facing_right
		WALK_FORWARD_SPEED = -WALK_FORWARD_SPEED
		WALK_BACKWARD_SPEED = -WALK_BACKWARD_SPEED
		JUMP_F_LENGHT = -JUMP_F_LENGHT
		JUMP_B_LENGHT = -JUMP_B_LENGHT
		DASH_F_DIST = -DASH_F_DIST
		DASH_B_DIST = -DASH_B_DIST
		AIRBORNE_HIT_LENGHT = -AIRBORNE_HIT_LENGHT
		GROUND_IMPACT_LENGHT = -GROUND_IMPACT_LENGHT
		self.scale.x *= -1

func player_control(delta):
	# Negate opposite directions ------------------------------------------
	if state == is_.STANDING:
		if Input.is_action_pressed("%s_LEFT" % Px) and Input.is_action_pressed("%s_RIGHT" % Px):
			stand()
		else:
	# Walk right -----------------------------------------------------------
			if Input.is_action_pressed("%s_RIGHT" % Px):
				if facing_right == true:
					walk_forward(delta)
				else:
					if can_guard == true:
						block()
					else: walk_backward(delta)
			if Input.is_action_just_released("%s_RIGHT" % Px):
				stand()
	# Walk left -------------------------------------------------------------
			if Input.is_action_pressed("%s_LEFT" % Px):
				if facing_right == false:
					walk_forward(delta)
				else:
					if can_guard == false:
						walk_backward(delta)
					else: block()
			if Input.is_action_just_released("%s_LEFT" % Px):
				stand()
	# Crouch -----------------------------------------------------------------
	if state == is_.STANDING:
		if Input.is_action_pressed("%s_DOWN" % Px):
			crouch()
	if state == is_.CROUCHING:
		if Input.is_action_just_released("%s_DOWN" % Px):
			$AnimationPlayer.play_backwards("Crouch")
			yield($AnimationPlayer, "animation_finished")
			stand()
	# Jump -------------------------------------------------------------------
	if state == is_.STANDING:
		if Input.is_action_pressed("%s_UP" % Px):
			state = is_.PRE_JUMP
			yield(get_tree().create_timer(0.05), "timeout")
			if state == is_.PRE_JUMP:
				if Input.is_action_pressed("%s_RIGHT" % Px):
					if facing_right == true:
						jump_forward()
					else: jump_backward()
				elif Input.is_action_pressed("%s_LEFT" % Px):
					if facing_right == true:
						jump_backward()
					else: jump_forward()
				else:
					jump_vertical()
	# Dash forward -----------------------------------------------------------
	if Input.is_action_just_pressed("%s_RIGHT" % Px) and dash_r_ready == false:
		dash_r_ready = true
		dash_l_ready = false
		yield(get_tree().create_timer(0.2), "timeout")
		dash_r_ready = false
	if state == is_.STANDING:
		if Input.is_action_just_pressed("%s_RIGHT" % Px) and dash_r_ready == true:
			if facing_right == true:
				dash_forward()
			else: dash_backward()
	# Dash backward -----------------------------------------------------------
	if Input.is_action_just_pressed("%s_LEFT" % Px) and dash_l_ready == false:
		dash_l_ready = true
		dash_r_ready = false
		yield(get_tree().create_timer(0.2), "timeout")
		dash_l_ready = false
	if state == is_.STANDING:
		if Input.is_action_just_pressed("%s_LEFT" % Px) and dash_l_ready == true:
			if facing_right == true:
				dash_backward()
			else: dash_forward()
	# Normal MP ---------------------------------------------------------------
	if state == is_.STANDING:
		if Input.is_action_just_pressed("%s_MP" % Px):
			startup_frames = true
			state = is_.ATTACKING
			standing_MP()
	# Jumping HK --------------------------------------------------------------
	if state == is_.JUMPING:
		if Input.is_action_just_pressed("%s_HK" % Px):
			startup_frames = true
			state = is_.AIR_ATTACKING
			jumping_HK()

func trigger_special_1():
	if Input.is_action_just_pressed("%s_DOWN" % Px):
		sp_input_count = 1
		print("ONE!")
		
	if sp_input_count == 1:
		if Input.is_action_pressed("%s_RIGHT" % Px) and Input.is_action_pressed("%s_DOWN" % Px):
			$SpecialTimer.start()
			sp_input_count = 2
			print("TWO!")
			
	if sp_input_count == 2:
		if Input.is_action_pressed("%s_RIGHT" % Px) and Input.is_action_just_released("%s_DOWN" % Px):
			sp_input_count = 3
			print("THREE!")
			
	if sp_input_count == 3:
		if Input.is_action_pressed("%s_HP" % Px):
			sp_input_count = 0
			print("HADOOOOOOKEEEEN!!!")

func manual_hitting():
	if Input.is_action_just_pressed("TEST_HIGH_HIT"):
		on_hit()
	elif Input.is_action_just_pressed("TEST_KNOCKDOWN") and \
		(state == is_.STANDING or state == is_.CROUCHING or state == is_.PRE_JUMP):
		state = is_.KNOCKED_DOWN
		on_hit()

func manual_flipping():
	if Input.is_action_just_pressed("TEST_FLIP"):
		waiting_for_flip = true
		is_blocking = false

func stand():
	state = is_.STANDING
	is_blocking = false
	$AnimationPlayer.play("Stand")

func walk_forward(delta):
	$AnimationPlayer.play("Walk forward")
	self.position.x += WALK_FORWARD_SPEED * delta

func walk_backward(delta):
	$AnimationPlayer.play("Walk backward")
	self.position.x -= WALK_BACKWARD_SPEED * delta

func crouch():
	state = is_.CROUCHING
	$AnimationPlayer.play("Crouch")
	yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.stop()

func jump_vertical():
	$AnimationPlayer.play("Pre jump")
	yield($AnimationPlayer, "animation_finished")
	#Arco ascendente --------------------------------
	if state == is_.PRE_JUMP:
		$AnimationPlayer.play("Jump vertical")
		tween.interpolate_property(self, "position:y",
			self.position.y, (self.position.y - JUMP_HEIGHT),
			JUMP_ASC_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = is_.JUMPING
		yield(tween, "tween_completed")
		#Arco descendente -------------------------------
		if state != is_.AIR_STUNNED:
			tween.interpolate_property(self, "position:y",
				self.position.y, (self.position.y + JUMP_HEIGHT),
				JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			yield(tween, "tween_completed")
			if state != is_.AIR_STUNNED:
				disable_hit_boxes()
				state = is_.STANDING
				pre_jump = false
				$AnimationPlayer.play("Stand")

func jump_forward():
	$AnimationPlayer.play("Pre jump")
	yield($AnimationPlayer, "animation_finished")
	#Arco ascendente --------------------------------
	if state == is_.PRE_JUMP:
		$AnimationPlayer.play("Jump forward")
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x + JUMP_F_LENGHT / 2,
			JUMP_ASC_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - JUMP_HEIGHT,
			JUMP_ASC_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = is_.JUMPING
		yield(tween, "tween_all_completed")
		#Arco descendente -------------------------------
		if state != is_.AIR_STUNNED:
			tween.interpolate_property(self, "position:x",
				self.position.x, self.position.x + JUMP_F_LENGHT / 2,
				JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "position:y",
				self.position.y, self.position.y + JUMP_HEIGHT,
				JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			yield(tween, "tween_all_completed")
			if state != is_.AIR_STUNNED:
				disable_hit_boxes()
				state = is_.STANDING
				pre_jump = false
				$AnimationPlayer.play("Stand")

func jump_backward():
	$AnimationPlayer.play("Pre jump")
	yield($AnimationPlayer, "animation_finished")
	#Arco ascendente --------------------------------
	if state == is_.PRE_JUMP:
		$AnimationPlayer.play("Jump backward")
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - JUMP_B_LENGHT / 2,
			JUMP_ASC_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		state = is_.JUMPING
		yield(tween, "tween_all_completed")
		#Arco descendente -------------------------------
		if state != is_.AIR_STUNNED:
			tween.interpolate_property(self, "position:x",
				self.position.x, self.position.x - JUMP_B_LENGHT / 2,
				JUMP_DES_TIME, Tween.TRANS_LINEAR, Tween.EASE_IN)
			tween.interpolate_property(self, "position:y",
				self.position.y, self.position.y + JUMP_HEIGHT,
				JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			yield(tween, "tween_all_completed")
			if state != is_.AIR_STUNNED:
				disable_hit_boxes()
				state = is_.STANDING
				pre_jump = false
				$AnimationPlayer.play("Stand")

func dash_forward():
	$AnimationPlayer.play("Dash forward")
	tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x + DASH_F_DIST, DASH_F_TIME,
		Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
	state = is_.DASHING
	yield(tween, "tween_completed")
	if state != is_.AIR_STUNNED:
		stand()

func dash_backward():
	$AnimationPlayer.play("Dash backward")
	tween.interpolate_property(self, "position:x", self.position.x,
		self.position.x - DASH_B_DIST, DASH_B_TIME,
		Tween.TRANS_QUINT, Tween.EASE_OUT)
	tween.start()
	state = is_.DASHING
	yield(tween, "tween_completed")
	if state != is_.AIR_STUNNED:
		stand()

func standing_MP():
	$AnimationPlayer.play("Attack standing MP")
	yield($AnimationPlayer, "animation_finished")
	stand()
	$ProximityBox/ProxBox1.disabled = true

func jumping_HK():
	$AnimationPlayer.play("Attack jumping HK")
	yield($AnimationPlayer, "animation_finished")
	$ProximityBox/ProxBox1.disabled = true

func fall():
	if state == is_.FALLING:
		if self.position.y == 195:
			tween.remove_all()
			ground_impact()
			pre_jump = false

func ground_impact():
	if state == is_.FALLING:
		state = is_.GROUND_IMPACT
		$AnimationPlayer.play("Ground impact")
		tween.interpolate_property(self, "position:x", self.position.x,
			self.position.x - GROUND_IMPACT_LENGHT, 0.5,
			Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield($AnimationPlayer, "animation_finished")
		wake_up()

func wake_up():
	if state == is_.GROUND_IMPACT or state == is_.KNOCKED_DOWN:
		state = is_.WAKING_UP
		$AnimationPlayer.play("Wake up")
		yield($AnimationPlayer, "animation_finished")
		stand()

func block():
	if is_blocking == false:
		is_blocking = true
#		$AnimationPlayer.play("Block high")
#		yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.stop()
		$Sprite.frame = 98

func on_hit():
	if is_blocking == true:
		$AnimationPlayer.play("Block high")
		yield($AnimationPlayer, "animation_finished")
		stand()
	elif state == is_.STANDING or state == is_.PRE_JUMP or state == is_.ATTACKING:
		state = is_.HIT_STUNNED
		disable_hit_boxes()
		$AnimationPlayer.play("Hit stun high hard")
		yield($AnimationPlayer, "animation_finished")
		state = is_.STANDING
		pre_jump = false
		stand()
	elif state == is_.JUMPING or state == is_.DASHING or state == is_.AIR_ATTACKING:
		state = is_.AIR_STUNNED
		disable_hit_boxes()
		$AnimationPlayer.play("Hit stun air")
		#Arco ascendente --------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - AIRBORNE_HIT_LENGHT / 2,
			0.5, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - 50,
			0.5, Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_all_completed")
		#Arco descendente -------------------------------
		tween.interpolate_property(self, "position:x",
			self.position.x, self.position.x - AIRBORNE_HIT_LENGHT / 2,
			0.5, Tween.TRANS_LINEAR, Tween.EASE_IN)
		tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y + 500,
			0.5, Tween.TRANS_QUINT, Tween.EASE_IN)
		tween.start()
		yield(tween, "tween_all_completed")
		state = is_.FALLING
	elif state == is_.KNOCKED_DOWN:
		$AnimationPlayer.play("Knockdown")
		yield($AnimationPlayer, "animation_finished")
		wake_up()

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

func disable_hit_boxes():
	$HitBoxes/HitBox1.disabled = true
	$ProximityBox/ProxBox1.disabled = true

func _process(delta):
	var motion = Vector2() #Posiblemente esto de motion no haga falta
	
	player_control(delta)
	facing_direction()
	trigger_special_1()
	manual_hitting()
	manual_flipping()
	fall()
	boxes_auto_visibility()
	
	motion = position - last_position
	last_position = position
	
	self.position.y = clamp(self.position.y, -100, 195)
	
	$State.text = is_.keys()[state]

func _on_proximity_box_entered(area):
	if area.has_method("proximity_box"):
		can_guard = true

func _on_proximity_box_exited(area):
	if area.has_method("proximity_box"):
		can_guard = false
		is_blocking = false

func _on_SpecialTimer_timeout():
	sp_input_count = 0
