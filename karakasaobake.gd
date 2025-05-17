extends CharacterBody2D

@onready var tween = create_tween()  # ボス登場の動き用Tween
@onready var bullet_scene = preload("res://tscn/tekidan_1.tscn")  # 弾シーンを読み込む
@onready var bullet_timer = $bullettimer  # 弾を定期的に撃つタイマー（今は未使用）
@onready var hp_bar = get_tree().get_root().get_node("bosstest/UI/enemyHP")
@onready var shot_sound_player := $shotsound  # AudioStreamPlayerノード

var hp := 500  # ボスの最大HP
var is_dead := false  # 死亡フラグ
var phase_ended := false
var is_pattern_running := false

func _ready():
	# ボス登場アニメ（スーッと降りる）
	$Animation.play("default")
	tween.tween_property(self, "position", Vector2(position.x, 200), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(_on_arrival)
	




func _on_arrival():
	print("ボス登場完了！")
	bullet_timer.stop()  # 今はパターンで弾を撃つから止めておく
	

# ========================
# ▼ 通常攻撃1のパターン処理 ▼
# ========================
func start_pattern_1():
	if phase_ended:
		return  # すでにフェーズ終了なら何もしない
	is_pattern_running = true 
	print("start_phase: hp =", hp)
	Global.play_effect_and_sound(global_position)
	await get_tree().create_timer(2.0).timeout
	await move_to(Vector2(350, 200))  # 左へ移動
	shoot_bullet1()  # 円弾発射
	await wait(2.0)  # 少し待つ

	await move_to(Vector2(900, 200))  # 右へ移動
	shoot_bullet1()
	await wait(2.0)

	await move_to(Vector2(634, 200))  # 中央へ移動
	shoot_bullet1()
	await wait(2.0)



# ========================
# ▼ あめあめふれふれのパターン処理 ▼
# ========================
func start_spell_1():
	if phase_ended:
		print("phase_endedフラグ立ってる！")
		return

	is_pattern_running = true
	print("スペル1『あめあめふれふれ』開始！")

	for i in range(30):  # 30回、0.3秒おきに弾を降らせる
		var bullet = bullet_scene.instantiate()
		var x = randi_range(100, 1100)
		bullet.position = Vector2(x, -50)
		if bullet.has_method("set_velocity"):
			bullet.set_velocity(Vector2(0, 300))
		get_tree().current_scene.add_child(bullet)
		await wait(0.3)

	is_pattern_running = false

	if not phase_ended:
		await end_phase()





# ========================
# ▼ 弾発射処理 ▼
# ========================
func shoot_bullet1():
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
	print("take_damage called! hp=", hp)
	hp -= damage
	hp_bar.value = hp

	if hp <= 0 and not phase_ended:
		phase_ended = true
		start_phase_end_sequence()

func start_phase_end_sequence() -> void:
	# 非同期処理は別関数に切り出す
	_call_deferred("_async_phase_end_sequence")

func _async_phase_end_sequence() -> void:
	await move_to(Vector2(634, 200))
	await end_phase()



# ========================
#　▼　フェーズ処理　▼
# ========================
func start_phase(phase_data: Dictionary):
	phase_ended = false
	hp = phase_data.hp
	hp_bar.max_value = hp
	hp_bar.value = hp

	# スペルカード演出と背景変更
	if phase_data.type == "spell":
		await get_node("/root/bosstest").show_spell_cutin(phase_data.name)
		get_node("/root/bosstest").change_background(true)
	else:
		get_node("/root/bosstest").change_background(false)

	# 攻撃パターン開始
	match phase_data.pattern:
		"pattern_1":
			await start_pattern_1()
		"skill_1":
			await start_spell_1()
		#"pattern_2":
			#await start_pattern_2()
		#"skill_2":
			#await start_spell_2()
			

func end_phase() -> void:
	if phase_ended:
		return
		print("すでにフェーズ終了しているのでreturn")
	phase_ended = true
	print("フェーズ終了")

	if hp <= 0:
		die()
	else:
		await get_node("/root/bosstest").start_next_phase()



# ========================
# ▼ 死亡処理 ▼
# ========================
func die():
	is_dead = true
	bullet_timer.stop()  # タイマー停止
	set_process(false)   # _processや_physics_processを止めるなら（任意）

	print("ボス撃破！")
	queue_free()  # 最後に消える（演出後にしたければ後ろに移動）


# ========================
# ▼ プレイヤーとの接触 ▼
# ========================
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.take_damage()
