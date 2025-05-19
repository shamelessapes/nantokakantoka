extends Node2D
@onready var se = $AudioStreamPlayer2D

func _ready():
	se.play()
	$GPUParticles2D.emitting = true
	await get_tree().create_timer(1.8).timeout
	queue_free()
