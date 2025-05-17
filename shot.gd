extends Area2D

@export var speed := 500
@export var damage := 2
@onready var raycast = $RayCast2D

func _physics_process(delta):
	position.y -= speed * delta
	raycast.target_position = Vector2(0, -speed * delta)
	raycast.force_raycast_update()
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("enemy"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage)
			queue_free()
	if position.y < -1000:
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("enemy") and area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()
