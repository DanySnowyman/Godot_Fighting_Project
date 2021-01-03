extends Area2D


var char_name = "MrPalo"
var player = 1
var rival
var Px

enum is_ {STANDING, CROUCHING, DASHING, PRE_JUMP, JUMPING, ATTACKING_ST, ATTACKING_CR,
		ATTACKING_SP, AIR_ATTACKING, BLOCKING_H, BLOCKING_L, BLOCK_STUNNED_H, BLOCK_STUNNED_L,
		HIT_STUNNED_ST, HIT_STUNNED_CR, AIR_STUNNED, FALLING, GROUND_IMPACT, KNOCKED_DOWN, WAKING_UP}

var state = is_.STANDING
var facing_right = true
var must_face_right
var can_guard = false
var just_hitted = false
var waiting_for_flip = false
var already_crouched = false
var last_position = Vector2()
var pre_jump = false
var startup_frames = false
var dash_r_ready = false
var dash_l_ready = false
var can_dash_cancel = false
var sp_input_count = 0

var hit_damg
var hit_stun
var hit_strg # Light, Medium, Heavy, Sweep
var hit_area # High, Low or Mid (Si debe bloquearse alto, bajo o ambos valen)
var hit_type
var hit_trig # Head, Torso or Legs (Animación de respuesta en el rival)
var hit_chip
var hit_lock
var hit_jugg

var WALK_FORWARD_SPEED = 200
var WALK_BACKWARD_SPEED = 150
var JUMP_F_LENGHT = 120
var JUMP_B_LENGHT = 100
var DASH_F_DIST = 80
var DASH_B_DIST = 60
var AIRBORNE_HIT_LENGHT = 100
var GROUND_IMPACT_LENGHT = 20

const JUMP_HEIGHT = 80
const JUMP_ASC_TIME = 0.4
const JUMP_DES_TIME = 0.4
const DASH_F_TIME = 0.4
const DASH_B_TIME = 0.4

onready var tween = get_node("Tween")

signal hitted(hit_out_damage, hit_out_stun, hit_out_strenght, hit_out_area, hit_out_trigger,
				hit_out_chip, hit_out_lock, hit_out_juggle)

func _ready():
	if player == 1:
		self.position = Vector2(120, 195)
		Px = "P1"
		$State.set_as_toplevel(true)
		$State.set_global_position(Vector2(20, 20))
		self.set_collision_layer(0)
		self.set_collision_mask(9216)
		$HitBoxes.set_collision_layer(4)
#		$HitBoxes.set_collision_mask(2048)
		$HurtBoxes.set_collision_layer(2)
		$HurtBoxes.set_collision_mask(4096)
		$ProximityBox.set_collision_layer(8)
		add_to_group("Player_1")
	else:
		self.position = Vector2(264, 195)
		Px = "P2"
		$State.set_as_toplevel(true)
		$State.set_global_position(Vector2(300, 20))
		set_collision_layer(1024)
		set_collision_mask(9)
		$HitBoxes.set_collision_layer(4096)
#		$HitBoxes.set_collision_mask(2)
		$HurtBoxes.set_collision_layer(2048)
		$HurtBoxes.set_collision_mask(4)
		$ProximityBox.set_collision_layer(8192)
		add_to_group("Player_2")
	
	state = is_.STANDING
	$AnimationPlayer.play("Stand")
	$ProximityBox/ProxBox1.disabled = true
	$HitBoxes/HitBox1.disabled = true

func connect_to_signals():
	if player == 1:
		rival = get_parent().get_node("Player2")
	else: 	rival = get_parent().get_node("Player1")
	
	rival.connect("hitted", self, "strike_in_data")
		
func change_facing_direction():
	if facing_right != must_face_right:
		waiting_for_flip = true

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
	# Walk right & standing block --------------------------------------------
			if Input.is_action_pressed("%s_RIGHT" % Px):
				if facing_right == true:
					walk_forward(delta)
				else:
					if can_guard == true:
						block_high()
					else: walk_backward(delta)
			if Input.is_action_just_released("%s_RIGHT" % Px):
				stand()
	# Walk left & standing block -------------------------------------------
			if Input.is_action_pressed("%s_LEFT" % Px):
				if facing_right == false:
					walk_forward(delta)
				else:
					if can_guard == false:
						walk_backward(delta)
					else: block_high()
			if Input.is_action_just_released("%s_LEFT" % Px):
				stand()
	# Crouching block --------------------------------------------------------
	if state == is_.STANDING or state == is_.CROUCHING:
		if Input.is_action_pressed("%s_LEFT" % Px) and Input.is_action_pressed("%s_DOWN" % Px):
			if can_guard == true and facing_right == true:
				block_low()
		if Input.is_action_pressed("%s_RIGHT" % Px) and Input.is_action_pressed("%s_DOWN" % Px):
			if can_guard == true and facing_right == false:
				block_low()
	# Exit from blocking -----------------------------------------------------
	if state == is_.BLOCKING_H:
		if facing_right == true:
			if Input.is_action_just_released("%s_LEFT" % Px):
				stand()
			elif Input.is_action_just_pressed("%s_DOWN" % Px):
				$Sprite.frame = 83
				state = is_.BLOCKING_L
		else:
			if Input.is_action_just_released("%s_RIGHT" % Px):
				stand()
			elif Input.is_action_just_pressed("%s_DOWN" % Px):
				$Sprite.frame = 83
				state = is_.BLOCKING_L
	if state == is_.BLOCKING_L:
		if facing_right == true:
			if Input.is_action_pressed("%s_LEFT" % Px) and\
						Input.is_action_just_released("%s_DOWN" % Px):
					$Sprite.frame = 81
					state = is_.BLOCKING_H
			elif Input.is_action_just_released("%s_DOWN" % Px):
				stand()
			if Input.is_action_just_released("%s_LEFT" % Px):
				$Sprite.frame = 65
				state = is_.CROUCHING
		else:
			if Input.is_action_pressed("%s_RIGHT" % Px) and\
						Input.is_action_just_released("%s_DOWN" % Px):
					$Sprite.frame = 81
					state = is_.BLOCKING_H
			elif Input.is_action_just_released("%s_DOWN" % Px):
				stand()
			if Input.is_action_just_released("%s_RIGHT" % Px):
				$Sprite.frame = 65
				state = is_.CROUCHING
	# Crouch -----------------------------------------------------------------
	if state == is_.STANDING:
		if Input.is_action_pressed("%s_DOWN" % Px):
			crouch()
	if state == is_.CROUCHING:
		if Input.is_action_pressed("%s_DOWN" % Px) == false:
			stand()
		else: crouch()

	# Jump -------------------------------------------------------------------
	if state == is_.STANDING or state == is_.BLOCKING_H:
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
	if state == is_.STANDING or state == is_.BLOCKING_H:
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
	if state == is_.STANDING or state == is_.BLOCKING_H:
		if Input.is_action_just_pressed("%s_LEFT" % Px) and dash_l_ready == true:
			if facing_right == true:
				dash_backward()
			else: dash_forward()
	# Standing Normals --------------------------------------------------------
	if state == is_.STANDING or state == is_.BLOCKING_H:
		if Input.is_action_just_pressed("%s_LP" % Px):
			standing_normal("LP")
		if Input.is_action_just_pressed("%s_MP" % Px):
			standing_normal("MP")
		if Input.is_action_just_pressed("%s_HP" % Px):
			standing_normal("HP")
		if Input.is_action_just_pressed("%s_LK" % Px):
			standing_normal("LK")
		if Input.is_action_just_pressed("%s_MK" % Px):
			standing_normal("MK")
		if Input.is_action_just_pressed("%s_HK" % Px):
			standing_normal("HK")
	# Crouching Normals ---------------------------------------------------------
	if state == is_.CROUCHING or state == is_.BLOCKING_L:
		if Input.is_action_just_pressed("%s_LP" % Px):
			crouching_normal("LP")
		if Input.is_action_just_pressed("%s_MP" % Px):
			crouching_normal("MP")
		if Input.is_action_just_pressed("%s_HP" % Px):
			crouching_normal("HP")
		if Input.is_action_just_pressed("%s_LK" % Px):
			crouching_normal("LK")
		if Input.is_action_just_pressed("%s_MK" % Px):
			crouching_normal("MK")
		if Input.is_action_just_pressed("%s_HK" % Px):
			crouching_normal("HK")
	# Jumping Normals -----------------------------------------------------------
	if state == is_.JUMPING:
		if Input.is_action_just_pressed("%s_LP" % Px):
			jumping_normal("LP")
		if Input.is_action_just_pressed("%s_MP" % Px):
			jumping_normal("MP")
		if Input.is_action_just_pressed("%s_HP" % Px):
			jumping_normal("HP")
		if Input.is_action_just_pressed("%s_LK" % Px):
			jumping_normal("LK")
		if Input.is_action_just_pressed("%s_MK" % Px):
			jumping_normal("MK")
		if Input.is_action_just_pressed("%s_HK" % Px):
			jumping_normal("HK")

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
#		if state == is_.ATTACKING_ST:
		if Input.is_action_pressed("%s_HP" % Px):
			sp_input_count = 0
			state = is_.ATTACKING_SP
			$AnimationPlayer.play("Special 1")
			yield($AnimationPlayer, "animation_finished")
			stand()

func stand():
	state = is_.STANDING
	if already_crouched == true:
		already_crouched = false
		$AnimationPlayer.play_backwards("Crouch")
		yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("Stand")

func crouch():
	state = is_.CROUCHING
	if already_crouched == false:
		already_crouched = true
		$AnimationPlayer.play("Crouch")
		yield($AnimationPlayer, "animation_finished")
	$AnimationPlayer.play("Crouch already")
	
func walk_forward(delta):
	$AnimationPlayer.play("Walk forward")
	self.position.x += WALK_FORWARD_SPEED * delta

func walk_backward(delta):
	$AnimationPlayer.play("Walk backward")
	self.position.x -= WALK_BACKWARD_SPEED * delta

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

func standing_normal(button_pressed):
	startup_frames = true # Para el sistema de counters
	state = is_.ATTACKING_ST
	if button_pressed == "LP":
		strike_data(100, 90, "Light", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack standing LP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "MP":
		strike_data(150, 140, "Medium", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack standing MP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "HP":
		strike_data(200, 190, "Heavy", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack standing HP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "LK":
		strike_data(110, 100, "Light", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack standing LK")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "MK":
		strike_data(170, 150, "Medium", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack standing MK")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "HK":
		strike_data(220, 210, "Heavy", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack standing HK")
		yield($AnimationPlayer, "animation_finished")
	stand()

func crouching_normal(button_pressed):
	startup_frames = true # Para el sistema de counters
	state = is_.ATTACKING_CR
	already_crouched = true
	if button_pressed == "LP":
		strike_data(100, 90, "Light", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack crouching LP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "MP":
		strike_data(150, 140, "Medium", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack crouching MP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "HP":
		strike_data(200, 190, "Heavy", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack crouching HP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "LK":
		strike_data(110, 100, "Light", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack crouching LK")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "MK":
		strike_data(170, 150, "Medium", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack crouching MK")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "HK":
		strike_data(220, 210, "Sweep", "Mid", "Normal", false, false, false)
		$AnimationPlayer.play("Attack crouching HK")
		yield($AnimationPlayer, "animation_finished")
	crouch()
	
func jumping_normal(button_pressed):
	startup_frames = true # Para el sistema de counters
	state = is_.AIR_ATTACKING
	if button_pressed == "LP":
		$AnimationPlayer.play("Attack jumping LP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "MP":
		$AnimationPlayer.play("Attack jumping MP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "HP":
		$AnimationPlayer.play("Attack jumping HP")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "LK":
		$AnimationPlayer.play("Attack jumping LK")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "MK":
		$AnimationPlayer.play("Attack jumping MK")
		yield($AnimationPlayer, "animation_finished")
	if button_pressed == "HK":
		$AnimationPlayer.play("Attack jumping HK")
		yield($AnimationPlayer, "animation_finished")

func strike_data(damg, stun, strg, area, type, chip, lock, jugg):
	hit_damg = damg
	hit_stun = stun
	hit_strg = strg
	hit_area = area
	hit_type = type
	hit_chip = chip
	hit_lock = lock
	hit_jugg = jugg
	
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

func block_high():
	state = is_.BLOCKING_H
	$AnimationPlayer.play("Block high")
		
func block_low():
	state = is_.BLOCKING_L
	$AnimationPlayer.play("Block low")

func on_hit():
	print("%s on_hit func" % Px)
	if state == is_.BLOCKING_H:
		if rival.hit_area == "High" or rival.hit_area == "Mid":
			blocked_hit()
			
	elif state == is_.BLOCKING_L:
		if rival.hit_area == "Mid" or rival.hit_area == "Low":
			blocked_hit()

	elif state == is_.JUMPING or state == is_.DASHING or state == is_.AIR_ATTACKING:
		air_received_hit()

	else:
		received_hit()
		
func blocked_hit():
	print("%s blocked_hit func" % Px)
	if state == is_.BLOCKING_H:
		state = is_.BLOCK_STUNNED_H
		if rival.hit_trig == "Head" or "Torso":
			if rival.hit_strg == "Light":
				$AnimationPlayer.play("Block stun high light")
				knockback(10, 0.167)
			elif rival.hit_strg == "Medium":
				$AnimationPlayer.play("Block stun high medium")
				knockback(20, 0.267)
			else:
				$AnimationPlayer.play("Block stun high heavy")
				knockback(100, 0.4)
		elif rival.hit_trig == "Legs":
			if rival.hit_strg == "Light":
				$AnimationPlayer.play("Block stun low light")
				knockback(10, 0.167)
			elif rival.hit_strg == "Medium":
				$AnimationPlayer.play("Block stun low medium")
				knockback(20, 0.267)
			else:
				$AnimationPlayer.play("Block stun low heavy")
				knockback(30, 0.4)
	elif state == is_.BLOCKING_L:
		state = is_.BLOCK_STUNNED_L
		if rival.hit_strg == "Light":
			$AnimationPlayer.play("Block stun crouching light")
			knockback(10, 0.167)
		elif rival.hit_strg == "Medium":
			$AnimationPlayer.play("Block stun crouching medium")
			knockback(20, 0.267)
		else:
			$AnimationPlayer.play("Block stun crouching heavy")
			knockback(30, 0.4)
	yield($Tween, "tween_completed")
	stand()

func received_hit():
	print("%s received_hit func" % Px)
	if state == is_.CROUCHING or state == is_.ATTACKING_CR:
		state = is_.HIT_STUNNED_CR
		already_crouched = true
		if rival.hit_strg == "Light":
			$AnimationPlayer.play("Hit stun crouching light")
			knockback(20, 0.2)
		elif rival.hit_strg == "Medium":
			$AnimationPlayer.play("Hit stun crouching medium")
			knockback(30, 0.3)
		elif rival.hit_strg == "Heavy":
			$AnimationPlayer.play("Hit stun crouching heavy")
			knockback(40, 0.433)
		elif rival.hit_strg == "Sweep":
			knocked_down()
		yield($Tween, "tween_completed")
		crouch()
		
	if state == is_.STANDING:
		state = is_.HIT_STUNNED_ST
		if hit_trig == "Head" or "Torso":
			if rival.hit_strg == "Light":
				$AnimationPlayer.play("Hit stun high light")
				knockback(20, 0.2)
			elif rival.hit_strg == "Medium":
				$AnimationPlayer.play("Hit stun high medium")
				knockback(30, 0.3)
			elif rival.hit_strg == "Heavy":
				$AnimationPlayer.play("Hit stun high heavy")
				knockback(40, 0.433)
			elif rival.hit_strg == "Sweep":
				knocked_down()
		elif hit_trig == "Legs":
			if rival.hit_strg == "Light":
				$AnimationPlayer.play("Hit stun low light")
				knockback(20, 0.2)
			elif rival.hit_strg == "Medium":
				$AnimationPlayer.play("Hit stun low medium")
				knockback(30, 0.3)
			elif rival.hit_strg == "Heavy":
				$AnimationPlayer.play("Hit stun low heavy")
				knockback(40, 0.433)
			elif rival.hit_strg == "Sweep":
				knocked_down()
			yield($Tween, "tween_completed")
			stand()
				

func air_received_hit():
	print("%s air_received_hit func" % Px)
	state = is_.AIR_STUNNED
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
	if state == is_.KNOCKED_DOWN:
		$AnimationPlayer.play("Knockdown")
		yield($AnimationPlayer, "animation_finished")
		wake_up()

func knocked_down():
		state = is_.KNOCKED_DOWN
		$AnimationPlayer.play("Knockdown")
		knockback(30, 0.3)
		yield($AnimationPlayer, "animation_finished")
		wake_up()
		
func knockback(distance, time):
	if facing_right == false:
		distance = -distance
	if rival.hit_lock == false: 
		tween.interpolate_property(self, "position:x", self.position.x,
			self.position.x - distance, time,
			Tween.TRANS_QUINT, Tween.EASE_OUT)
		tween.start()
		yield(tween, "tween_completed")
		stand()


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
	change_facing_direction()
	facing_direction()
	trigger_special_1()
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
		if state == is_.BLOCKING_H:
			stand()
		if state == is_.BLOCKING_L:
			state = is_.CROUCHING
			$Sprite.frame = 65

func _on_hit_connects(area):
	if area.has_method("hurt_box"):
		$HitBoxes/HitBox1.disabled

func _on_SpecialTimer_timeout():
	sp_input_count = 0
	
func _on_HitSpacerTimer_timeout():
	just_hitted = false
	
func _on_HurtBoxes_area_shape_entered(area_id, area, area_shape, self_shape):
	if just_hitted == false:
		just_hitted = true
		$HitSpacerTimer.start(0.1)
		if self_shape == 0:
			print("cabeza!")
			rival.hit_trig == "Head"
		elif self_shape == 1 or self_shape == 3:
			print("torso!")
			rival.hit_trig == "Torso"
		elif self_shape == 2:
			print("piernas!")
			rival.hit_trig == "Legs"
		on_hit()
