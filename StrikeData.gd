extends Node

var P1_hit_damg # Daño del golpe
var P1_hit_stun # Stun del golpe
var P1_hit_strg # Light, Medium or Heavy
var P1_hit_area # High, Low or Mid (Si debe bloquearse alto, bajo o ambos valen)
var P1_hit_type # Normal < Special < Powered < Final
var P1_hit_trig # Head, Upper or Lower (Animación de respuesta en el rival)
var P1_hit_chip # Si es cierto, produce algo de daño incluso cubriéndonos
var P1_hit_lock # Si es cierto, no produce empuje hacia atrás
var P1_hit_jugg # Si es cierto, nos golpea en estado AIR_STUNNED

var P2_hit_damg # Daño del golpe
var P2_hit_stun # Stun del golpe
var P2_hit_strg # Light, Medium or Heavy
var P2_hit_area # High, Low or Mid (Si debe bloquearse alto, bajo o ambos valen)
var P2_hit_type # Normal < Special < Powered < Final
var P2_hit_trig # Head, Upper or Lower (Animación de respuesta en el rival)
var P2_hit_chip # Si es cierto, produce algo de daño incluso cubriéndonos
var P2_hit_lock # Si es cierto, no produce empuje hacia atrás
var P2_hit_jugg # Si es cierto, nos golpea en estado AIR_STUNNED

func _ready():
	pass
