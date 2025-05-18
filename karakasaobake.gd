extends CharacterBody2D

@onready var tween = create_tween()
@onready var bullet_scene = preload("res://tscn/tekidan_1.tscn")
@onready var bullet_timer = $bullettimer  # 必ずTimerノードをシーン上に設置しておく
@onready var hp_bar = $UI/enemyHP
@onready var shot_sound_player := $shotsound  # AudioStreamPlayerノード
@onready var rain_timer := $rain_timer  # 新たにTimerノード(rain_timer)を追加しておく

var hp = 500
var is_dead = false
var phase_ended = false
var is_pattern_running = false

var phase_time_left = 0.0
var phase_timer_active = false

var spell2_finished_count = 0

# あめあめふれふれ用
var rain_shot_count = 0
var rain_shot_max = 30

func _ready():
	bullet_timer.stop()
	rain_timer.wait_time = 0.3
	rain_timer.one_shot = false
	rain_timer.connect("timeout", Callable(self, "_on_rain_timer_timeout"))

func _on_arrival():
	print("ボス登場完了！")
	bullet_timer.stop()

func _process(delta):
	if phase_timer_active and not phase_ended:
		phase_time_left -= delta
		$UI/timelimit.value = max(phase_time_left, 0)
		if phase_time_left <= 0:
			phase_timer_active = false
			if not phase_ended:
				await start_phase_end_sequence()

# ========================
# ▼ 通常攻撃1のパターン処理 TIMERベースにするならbullet_timer使用も可能
# ========================
func start_pattern_1():
	is_pattern_running = true 
	print("start_phase: hp =", hp)
	Global.play_effect_and_sound(global_position)
	await get_tree().create_timer(2.0).timeout
	await move_to(Vector2(350, 200))
	shoot_bullet1()
	await get_tree().create_timer(2.0).timeout
	await move_to(Vector2(900, 200))
	shoot_bullet1()
	await get_tree().create_timer(2.0).timeout
	await move_to(Vector2(634, 200))
	shoot_bullet1()
	await get_tree().create_timer(2.0).timeout
	is_pattern_running = false

# ========================
# ▼ 通常攻撃2のパターン処理
# ========================
func start_pattern_2():
	is_pattern_running = true
	print("start_pattern_2: hp =", hp)
	Global.play_effect_and_sound(global_position)
	await get_tree().create_timer(2.0).timeout
	await move_to(Vector2(350, 200))
	shoot_bullet1()
	await get_tree().create_timer(2.0).timeout
	await move_to(Vector2(900, 200))
	shoot_bullet1()
	await get_tree().create_timer(2.0).timeout
	await move_to(Vector2(634, 200))
	shoot_bullet1()
	await get_tree().create_timer(2.0).timeout
	is_pattern_running = false

# ========================
# ▼ あめあめふれふれのパターン処理 [TIMERベース]
# ========================
func start_spell_1():
	is_pattern_running = true
	print("スペル1『あめあめふれふれ』開始！")
	rain_shot_count = 0
	rain_timer.start()

func _on_rain_timer_timeout():
	# 弾を1発降らせる
	var bullet = bullet_scene.instantiate()
	var x = randi_range(100, 1100)
	bullet.position = Vector2(x, -50)
	if bullet.has_method("set_velocity"):
		bullet.set_velocity(Vector2(0, 300))
	get_tree().current_scene.add_child(bullet)
	rain_shot_count += 1
	if rain_shot_count >= rain_shot_max:
		rain_timer.stop()
		is_pattern_running = false
		if not phase_ended:
			await end_phase()
# ========================
# ▼ 必殺技2「日照り雨」 ▼
# ========================
func start_spell_2():
	is_pattern_running = true
	print("スペル2『日照り雨』開始！（通常攻撃２＋あめあめふれふれの合わせ技）")
	
	spell2_finished_count = 0
	do_ameamehurehure(self._on_subtask_finished_spell2)
	do_pattern2_mix(self._on_subtask_finished_spell2)

func _on_subtask_finished_spell2():
	spell2_finished_count += 1
	if spell2_finished_count == 2:
		is_pattern_running = false
		if not phase_ended:
			await end_phase()

# コールバック式で終了を通知
func do_ameamehurehure(callback):
	await get_tree().create_timer(0.0).timeout # 確実な非同期化
	for i in range(30):
		var bullet = bullet_scene.instantiate()
		var x = randi_range(100, 1100)
		bullet.position = Vector2(x, -50)
		if bullet.has_method("set_velocity"):
			bullet.set_velocity(Vector2(0, 300))
		get_tree().current_scene.add_child(bullet)
		await wait(0.3)
	callback.call()

func do_pattern2_mix(callback):
	await get_tree().create_timer(0.0).timeout # 確実な非同期化
	for pos in [Vector2(350, 200), Vector2(900, 200), Vector2(634, 200)]:
		await move_to(pos)
		shoot_bullet1()
		await wait(2.0)
	callback.call()

# ========================
# ▼ 弾発射処理 ▼
# ========================
func shoot_bullet1():
	shot_sound_player.play()
	var bullet_count = 10  # 発射する弾の数
	var speed = 200.0  # 弾のスピード

	for i in range(bullet_count):
		var angle = TAU * i / bullet_count  # 角度を均等に分ける
		var direction = Vector2(cos(angle), sin(angle))  # 角度から方向を計算

		var bullet = bullet_scene.instantiate()
		bullet.position = global_position  # ボス位置から発射

		if bullet.has_method("set_velocity"):
			bullet.set_velocity(direction * speed)

		get_tree().current_scene.add_child(bullet)

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
# ▼ ダメージ処理（改善版） ▼
# ========================
func take_damage(damage: int) -> void:
	print("take_damage called: phase_ended=%s, is_dead=%s, hp=%d" % [phase_ended, is_dead, hp])
	if is_dead or phase_ended:
		return
	hp -= damage
	hp_bar.value = hp
	if hp <= 0 and not phase_ended:
		await start_phase_end_sequence()
	
func start_phase_end_sequence() -> void:
	if phase_ended:
		print("start_phase_end_sequence: すでに終了しているのでreturn")
		return
	phase_ended = true
	print(">>> start_phase_end_sequence 開始")
	await move_to(Vector2(634, 200))
	print(">>> start_phase_end_sequence: move_to終了、end_phase呼び出しへ")
	await end_phase()
	print(">>> start_phase_end_sequence: end_phase終了")

# ========================
# ▼ フェーズ処理（改善版） ▼
# ========================
func start_phase(phase_data: Dictionary):
	print("start_phase called: phase_ended(before)=", phase_ended)
	phase_ended = false  # フェーズ開始時にリセット
	hp = phase_data.hp
	hp_bar.max_value = hp
	hp_bar.value = hp
	# 攻撃パターン開始直前
	print("start_phase: phase_ended(before pattern)=", phase_ended)


	# タイムリミットバー設定
	phase_time_left = float(phase_data.duration)
	$UI/timelimit.max_value = phase_time_left
	$UI/timelimit.value = phase_time_left
	phase_timer_active = true

	# スペルカード演出と背景変更
	if phase_data.type == "spell":
		await get_node("/root/bosstest").show_spell_cutin(phase_data.name)
		get_node("/root/bosstest").change_background(true)
	else:
		get_node("/root/bosstest").change_background(false)

	# 弾全消去（フェーズ開始時に確実に安全な状態にする）
	if "erase_all_bullets_with_effect" in get_node("/root/bosstest"):
		get_node("/root/bosstest").erase_all_bullets_with_effect()

	# 攻撃パターン開始
	match phase_data.pattern:
		"pattern_1":
			await start_pattern_1()
		"skill_1":
			await start_spell_1()
		"pattern_2":
			await start_pattern_2()
		"skill_2":
			await start_spell_2()
	print("start_phase: phase_ended(after pattern)=", phase_ended)
	
func end_phase() -> void:
	if not phase_ended:
		print("end_phase: phase_endedがfalseだったのでtrueへ")
		phase_ended = true
	else:
		print("すでにフェーズ終了しているのでreturn")
		return
	phase_timer_active = false
	print("フェーズ終了")

	var boss_test = get_node("/root/bosstest")
	if hp <= 0:
		if boss_test.current_phase_index + 1 >= boss_test.phases.size():
			print("ボス死亡、die()呼び出し")
			die()
		else:
			print("HP0だが、フェーズ残ってるのでstart_next_phase()へ")
			await boss_test.start_next_phase()
	else:
		print("時間切れや特殊条件でのフェーズ終了、次のフェーズへ")
		await boss_test.start_next_phase()


# ========================
# ▼ 死亡処理 ▼
# ========================
func die():
	print("[die] ボス撃破！queue_freeします")
	is_dead = true
	bullet_timer.stop()
	set_process(false)
	queue_free()

# ========================
# ▼ プレイヤーとの接触 ▼
# ========================
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.take_damage()
