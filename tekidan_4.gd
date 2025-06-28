extends Area2D # tekidan_4
class_name Tekidan4

@export var speed: float = 300                       # 弾のスピード
@export var direction: Vector2 = Vector2.ZERO        # 外部から与えられる進行方向



var velocity: Vector2 = Vector2.ZERO                 # 実際の移動速度

func set_velocity(v: Vector2) -> void:
	velocity = v

func _ready():
	add_to_group("bullet")
	
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed     # direction から velocity を計算
	
	if position.y < -100:
		queue_free()

func _physics_process(delta: float) -> void:
	position += velocity * delta  # 移動処理

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.take_damage()
		queue_free()
