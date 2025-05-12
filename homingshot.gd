extends Area2D

@export var speed := 400
@export var rotate_speed := 4.0
@export var damage := 1
@onready var homing_collision := $homingcollision
@onready var sprite := $Sprite2D  # スプライトの角度調整用

var shoot_timer := 0.0  # 発射タイマー

func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest_enemy: Node2D = null
	var min_distance = INF
	for enemy in enemies:
		if not enemy is Node2D:
			continue  # CharacterBody2DもArea2DもNode2Dの子クラスだからこれでOK！
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	return nearest_enemy

func check_collision():
	if homing_collision:
		# Area2D（弾や当たり判定）との衝突判定
		for area in homing_collision.get_overlapping_areas():
			if area.is_in_group("enemy") and area.has_method("take_damage"):
				area.take_damage(damage)
				queue_free()
				return  # 1回だけ処理したら終了（複数に当たらないように）
		# PhysicsBody2D（CharacterBody2D や RigidBody2D など）との衝突判定
		for body in homing_collision.get_overlapping_bodies():
			if body.is_in_group("enemy") and body.has_method("take_damage"):
				body.take_damage(damage)
				queue_free()
				return


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
