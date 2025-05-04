extends Area2D

@export var speed := 400
@export var rotate_speed := 4.0
@export var damage := 1
@onready var homing_collision := $homingcollision
@onready var sprite := $Sprite2D  # スプライトの角度調整用

var shoot_timer := 0.0  # 発射タイマー

func find_nearest_enemy() -> Area2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest = null
	var min_dist = INF
	for enemy in enemies:
		if enemy and enemy.is_inside_tree():
			var dist = global_position.distance_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = enemy
	return nearest

func check_collision():
	if homing_collision:
		for area in homing_collision.get_overlapping_areas():
			if area.is_in_group("enemy"):
				if area.has_method("take_damage"):
					area.take_damage(damage)
				queue_free()

func check_out_of_bounds():
	if position.y < -100 or position.y > 1200 or position.x < 300 or position.x > 1000:
		queue_free()

func _physics_process(delta):
	# 発射タイマーの更新
	shoot_timer -= delta

	# 敵がいる場合、追尾する
	var target = find_nearest_enemy()

	if target:
		var direction = (target.global_position - global_position).normalized()
		var angle_diff = direction.angle() - rotation
		angle_diff = clamp(angle_diff, -rotate_speed * delta, rotate_speed * delta)
		rotation += angle_diff
	# 敵がいない場合は直進
	else:
		rotation += 0  # 変更なし（そのまま直進）

	# 直進のために位置更新
	position += Vector2.UP.rotated(rotation) * speed * delta
	sprite.rotation = -rotation  # スプライトの向きを調整（見た目を合わせる）

	check_collision()  # 衝突判定
	check_out_of_bounds()  # 画面外チェック
