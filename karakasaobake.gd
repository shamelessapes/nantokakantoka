extends CharacterBody2D

@onready var tween = create_tween()  # ボス登場の動き用Tween
@onready var bullet_scene = preload("res://tscn/tekidan_1.tscn")  # 弾シーンを読み込む
@onready var bullet_timer = $bullettimer  # 弾を定期的に撃つタイマー

var hp := 1000  # 敵の最大HP
var is_dead := false  # 死亡フラグ

func _ready():  # ボス登場アニメと移動処理
	$Area2D/Animation.play("default")  # 登場アニメ再生
	tween.tween_property(self, "position", Vector2(position.x, 200), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)  # 上からスーッと降りる演出
	tween.finished.connect(_on_arrival)  # 降り終わったら_bullet_timer開始へ

func _on_arrival():  # 登場完了時の処理
	print("ボス登場完了！")
	bullet_timer.start()  # 弾発射タイマー開始

func _on_bullettimer_timeout() -> void:  # タイマーごとに呼ばれる
	shoot_bullet()  # 弾を撃つ！

func shoot_bullet():  # 弾幕発射処理（円形に弾をばらまく）
	var bullet_count = 10 # 発射する弾の数
	var radius = 0  # 弾の出現位置オフセット距離（ちょっとだけ離して出す）
	var speed = 200.0  # 弾のスピード

	for i in range(bullet_count):
		var angle = TAU * i / bullet_count  # 角度を均等に割る（TAU=2π）
		var direction = Vector2(cos(angle), sin(angle))  # 発射方向のベクトル

		var bullet = bullet_scene.instantiate()
		bullet.position = global_position   # ボス中心から少し離して出す

		# 弾に速度を渡す（set_velocityがあれば）
		if bullet.has_method("set_velocity"):
			bullet.set_velocity(direction * speed)

		get_tree().current_scene.add_child(bullet)  # シーンに追加して飛ばす

func take_damage(damage: int) -> void:
	if is_dead:
		return  # すでに死んでたら無視
	hp -= damage
	print("ボスのHP:", hp)
	if hp <= 0:
		die()

func die():
	is_dead = true
	print("ボス撃破！")
	queue_free()  # とりあえず消える
