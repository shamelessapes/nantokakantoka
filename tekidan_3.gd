extends Area2D #tekidan_3

@export var speed = 300
var velocity = Vector2.ZERO

func set_velocity(v: Vector2) -> void:
	velocity = v  # 外部から設定された方向で velocity を更新

func _ready():
	add_to_group("bullet")
	if position.y < -100:
		queue_free()

func _physics_process(delta: float) -> void:
	position += velocity * delta  # 位置更新

	

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.take_damage()
		queue_free()
