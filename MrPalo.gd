extends KinematicBody2D


var char_name = "MrPalo"
var player = 1

var last_position = Vector2()

var on_floor = true
var is_jumping = false

onready var tween = get_node("Tween")

const JUMP_HEIGHT = 80
const JUMP_LENGHT = 120
const JUMP_ASC_TIME = 0.4
const JUMP_DES_TIME = 0.4

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
		
func jump_vertical():
	if on_floor == true and is_jumping == false:
		if Input.is_action_pressed("ui_up"):
			is_jumping = true
			yield(get_tree().create_timer(0.05), "timeout")
			on_floor = false
			$AnimationPlayer.play("Jump vertical")
			yield(get_tree().create_timer(0.1), "timeout")
			tween.interpolate_property(self, "position:y",
				self.position.y, (self.position.y - JUMP_HEIGHT),
				JUMP_ASC_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
			tween.start()
			yield(tween, "tween_completed")
			tween.interpolate_property(self, "position:y",
				self.position.y, (self.position.y + JUMP_HEIGHT),
				JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_IN)
			tween.start()
			yield(tween, "tween_completed")
			yield($AnimationPlayer, "animation_finished")
			on_floor = true
			is_jumping = false
			$AnimationPlayer.play("Stand")
		
func jump_forward():
	if on_floor == true:
		if Input.is_action_pressed("ui_right") and\
		Input.is_action_pressed("ui_up"):
			is_jumping = true
			on_floor = false
			print("Forwardjump!")
			#Arco ascendente --------------------------------
			$AnimationPlayer.play("Jump forward")
			yield(get_tree().create_timer(0.1), "timeout")
			tween.interpolate_property(self, "position:x",
				self.position.x, self.position.x + JUMP_LENGHT / 2,
				JUMP_ASC_TIME, Tween.TRANS_LINEAR, Tween.EASE_OUT)
			tween.interpolate_property(self, "position:y",
			self.position.y, self.position.y - JUMP_HEIGHT,
			JUMP_DES_TIME, Tween.TRANS_QUINT, Tween.EASE_OUT)
			yield(tween, "tween_completed")
			#Arco descendente -------------------------------
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

func _process(delta):
	var motion = Vector2()
	
	walk_forward(delta)
	walk_backwards(delta)
	jump_vertical()
	jump_forward()
	
	motion = position - last_position
	last_position = position
	
	print(is_jumping)
	
	
