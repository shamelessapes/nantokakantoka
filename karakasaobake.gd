extends CharacterBody2D

@onready var tween = create_tween()  # ボス登場の動き用Tween
@onready var bullet_scene = preload("res://tscn/tekidan_1.tscn")  # 弾シーンを読み込む
@onready var bullet_timer = $bullettimer  # 弾を定期的に撃つタイマー（今は未使用）
@onready var hp_bar = get_tree().get_root().get_node("bosstest/UI/enemyHP")
@onready var shot_sound_player := $shotsound  # AudioStreamPlayerノード

var hp := 500  # ボスの最大HP
var is_dead := false  # 死亡フラグ

func _ready():
	# ボス登場アニメ（スーッと降りる）
	$Animation.play("default")
	tween.tween_property(self, "position", Vector2(position.x, 200), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_arrival)


func _on_arrival():
	print("ボス登場完了！")
	bullet_timer.stop()  # 今はパターンで弾を撃つから止めておく
	start_pattern_1()  # 通常攻撃1の開始

# ========================
# ▼ 通常攻撃1のパターン処理 ▼
# ========================
func start_pattern_1():
	await move_to(Vector2(350, 200))  # 左へ移動
	shoot_bullet()  # 円弾発射
	await wait(2.0)  # 少し待つ

	await move_to(Vector2(900, 200))  # 右へ移動
	shoot_bullet()
	await wait(2.0)

	await move_to(Vector2(634, 200))  # 中央へ移動
	shoot_bullet()
	await wait(2.0)

	# HPが残っていたらもう一度繰り返す（あとで制御を入れる予定）
	if not is_dead:
		start_pattern_1()

# ========================
# ▼ 弾発射処理 ▼
# ========================
func shoot_bullet():
	shot_sound_player.play()
	var bullet_count = 10  # 発射する弾の数
	var speed = 200.0  # 弾のスピード

	for i in range(bullet_count):
		# 弾の発射角度を均等に計算
		var angle = TAU * i / bullet_count  # 角度を均等に分ける
		var direction = Vector2(cos(angle), sin(angle))  # 角度から方向を計算

		# 弾を生成して発射方向を設定
		var bullet = bullet_scene.instantiate()
		bullet.position = global_position  # ボス位置から発射

		# 弾の方向を velocity にセット
		if bullet.has_method("set_velocity"):
			bullet.set_velocity(direction * speed)  # 計算した方向とスピードで発射

		get_tree().current_scene.add_child(bullet)  # シーンに追加して発射

# ========================
# ▼ Tweenを使った移動処理 ▼
# ========================
func move_to(target_pos: Vector2) -> void:
	var t = create_tween()
	t.tween_property(self, "position", target_pos, 0.5)
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished

# ========================
# ▼ 一時停止（待機処理） ▼
# ========================
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

# ========================
# ▼ ダメージ処理 ▼
# ========================
func take_damage(damage: int) -> void:
	if is_dead:
		return
	hp -= damage
	hp_bar.value = hp  # HPバーの値を更新！
	if hp <= 0:
		die()

# ========================
# ▼ 死亡処理 ▼
# ========================
func die():
	is_dead = true
	print("ボス撃破！")
	queue_free()  # とりあえず消える（あとで爆発＆次の演出へ）
