extends Area2D

var speed = 0
var hitted = false
var hit_area_pos:= Vector2()
var hit_area_size:= Vector2()
var hit_area_rect:= Rect2()

var hit_damg = 50 # Daño producido
var hit_stun = 50 # Aturdimiento producido
var hit_push = 30
var hit_strg # Light, Medium, Heavy, Launch, Sweep
var hit_area = "Mid" # High, Low or Mid (Si debe bloquearse alto, bajo o ambos valen)
var hit_type = "Special" # Normal < Special < Powered < Ultimate
var hit_jugg = true # Si es "true" puede golpearnos en estado "AIR_STUNNED"

func _ready():
	$AnimationPlayer.play("Normal")
	
func fireball_data(player_owner, facing_right, strenght):
	if player_owner == 1:
		self.set_collision_layer(32)
		self.set_collision_mask(32768)
		$ProximityBox.set_collision_layer(8)
	else:
		self.set_collision_layer(32768)
		self.set_collision_mask(32)
		$ProximityBox.set_collision_layer(8192)
	
	if strenght == "Heavy":
		speed = 200
	elif strenght == "Medium":
		speed = 170
	elif strenght == "Light":
		speed = 80
	if facing_right == false:
		speed = -speed
		scale.x = -scale.x
		
func _process(delta):
	if hitted == false:
		position.x += speed * delta
	else: pass

func get_hitbox_rect():
	var hit_area_center = $HitBox.position
	var hit_area_extents = $HitBox.shape.extents

	hit_area_pos = to_global(hit_area_center) - hit_area_extents
	hit_area_size = hit_area_extents * 2
		
	hit_area_rect = Rect2(hit_area_pos, hit_area_size)

func disable_projectile():
	hitted = true
	$HitBox.set_deferred("disabled", true)
	$ProximityBox/ProxBox1.set_deferred("disabled", true)
	$AnimationPlayer.play("Impact")
	yield($AnimationPlayer, "animation_finished")
	self.visible = false
	yield(get_tree().create_timer(2, true), "timeout")
	queue_free()
	
func _on_FireBall_area_entered(area):
	if area.has_method("disable_projectile"):
		disable_projectile()
	else: pass
	
func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
