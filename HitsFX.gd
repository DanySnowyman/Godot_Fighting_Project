extends Node2D

func _ready():
	self.visible = false

func call_animation(animation):
	self.visible = true
	$AnimationPlayer.play(animation)
	yield($AnimationPlayer, "animation_finished")
	self.visible = false
