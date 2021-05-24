extends Node2D

func _ready():
	self.visible = false

func call_animation(facing_right, animation):
	if facing_right == true:
		self.scale.x = -1
	else: self.scale.x = 1
	self.visible = true
	$AnimationPlayer.play(animation)
	yield($AnimationPlayer, "animation_finished")
	queue_free()
