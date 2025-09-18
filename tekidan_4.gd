extends Area2D # tekidan_4
class_name Tekidan4

@export var speed: float = 300                       # 弾のスピード
@export var direction: Vector2 = Vector2.ZERO        # 外部から与えられる進行方向
var accel_per_sec: float = 0.0           # 毎秒加速（ドングリ用）

func setup(dir: Vector2, spd: float, accel: float = 0.0) -> void:
	# 外部（ボスなど）からの初期化入口を共通化
	direction = dir.normalized()        # 方向を正規化
	speed = spd                         # 初速設定
	accel_per_sec = accel               # 加速度（必要な弾だけ有効）
	velocity = direction * speed        # 実速度を更新
	rotation = direction.angle()        # 見た目の向き（必要なら）


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
