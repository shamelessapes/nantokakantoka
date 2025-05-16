extends Node2D

func _ready():
	$AnimatedSprite2D.play()
	$AudioStreamPlayer2D.play()
	await get_tree().create_timer(1.8).timeout
	queue_free()
