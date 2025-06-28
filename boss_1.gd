extends CharacterBody2D
#------------------事前準備------------------
@onready var bullet1_scene = preload("res://tscn/tekidan_1.tscn")
@onready var bullet2_scene = preload("res://tscn/tekidan_2.tscn")
@onready var hp_bar = $UI/enemyHP
@onready var invincible_timer = $invincible_timer  # Timerノードへの参照
@onready var shot_sound_player := $shotsound  # AudioStreamPlayerノード
@onready var shotsound2_play := $shotsound2
@onready var move_timer = $MoveTimer  # シーンにあるTimerノードを参照
@onready var rain_timer = $rain_timer
@onready var phase_timer = $Timer
@onready var time_bar = $UI/timelimit
@onready var ui: SkillNameUI = get_node("../CanvasLayer")


var current_phase = 0
var current_hp = 1
var invincible = true
var damage_cooldown := 0.1  # ダメージ無効時間（秒）
var last_damage_time := -1.0
var is_pattern_running = false
var can_shoot = true
var pattern_task = null
var time_remaining = 0
var dialogue_connected := false  # 一度だけ接続するためのフラグ
var started_phase_index := -1
var resumed_skill_1 = false
signal battle_ended  # 戦闘終了のシグナル


var move_steps = [
	Vector2(350, 200),
	Vector2(900, 200),
	Vector2(634, 200),
]
var step_index = 0

#ーーーーーーーーーーーフェーズ管理ーーーーーーーーーーー
var phases = [
	{ "type": "normal", "hp": 100, "duration": 30, "pattern": "pattern_1" },
	{ "type": "skill", "hp": 100, "duration": 30, "pattern": "skill_1", "name": "あめあめふれふれ" },
	{ "type": "normal", "hp": 100, "duration": 30, "pattern": "pattern_2" },
	{ "type": "skill", "hp": 150, "duration": 30, "pattern": "skill_2", "name": "日照り雨" },
]

func start_phase(phase_index: int):
	resumed_skill_1 = false  # 各フェーズ開始時にリセット
	if phase_index == started_phase_index:
		print("⚠️ 同じフェーズが二重に呼ばれたのでキャンセル")
		return
	started_phase_index = phase_index
	var phase : Dictionary = phases[phase_index]

	# 親の演出だけ呼び出す（攻撃パターンはここでは呼ばない）
	var controller = get_parent()
	if controller and controller.has_method("start_phase_effects"):
		await controller.start_phase_effects(phase)

	if is_pattern_running:
		is_pattern_running = false
		if pattern_task != null:
			await pattern_task  # 前のパターンが完全に止まるの待つ
	pattern_task = null
	
	current_phase = phase_index  
	current_hp = phases[current_phase]["hp"]
	update_hp_bar()
	update_timelimit_bar(phase_index)
	is_pattern_running = false 
	
	time_remaining = phase["duration"]
	phase_timer.wait_time = 1.0  # 1秒ごとに減らす
	phase_timer.start()
	
	var pattern_name = phases[phase_index]["pattern"]
	match pattern_name:
		"pattern_1":
			await start_pattern_1()
			print("フェーズ１スタート")
		"skill_1":
			await start_skill_1()
			print("フェーズ2スタート")
		"pattern_2":
			start_pattern_2()
			print("フェーズ3スタート")
		"skill_2":
			start_skill_2()
			print("フェーズ4スタート")



func _on_Timer_timeout():
	# 1秒ごとにタイマー更新
	time_remaining -= 1
	time_bar.value = time_remaining
	
	if time_remaining <= 0:
		print("時間切れ！フェーズ強制終了！")
		phase_timer.stop()
		next_phase()
	
	

#ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー

func _ready():
	visible = false
	$Animation.play("default")
	$UI/timelimit.visible = false
	$UI/enemyHP.visible = false
	be_invincible(3.0)
	move_timer.connect("timeout", Callable(self, "_on_move_timer_timeout"))
	rain_timer.connect("timeout", Callable(self, "_on_rain_timer_timeout"))
	phase_timer.connect("timeout", Callable(self, "_on_Timer_timeout"))

	
func start_entrance_animation():
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(position.x, 200), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)  # 上からスーッと降りる演出
	tween.finished.connect(_on_drop_finished)
	await tween.finished  # Tweenが終わるのを待つ
	await get_tree().create_timer(3.0).timeout  # 3秒待つ
	
func _on_drop_finished():
	# 3秒の待機（コルーチン使えないのでTimerで）
	var wait_timer = Timer.new()
	wait_timer.wait_time = 0.1
	wait_timer.one_shot = true
	add_child(wait_timer)
	wait_timer.start()
	wait_timer.timeout.connect(_on_wait_finished)

func _on_wait_finished():
	var dm = get_node("../dialoguemanager")
	if not dialogue_connected:
		dm.dialogue_finished.connect(_on_dialogue_finished)
		dialogue_connected = true
	
func _on_dialogue_finished():
	print("関数が呼ばれた")
	$UI/timelimit.visible = true
	$UI/enemyHP.visible = true
	start_phase(current_phase)
	be_invincible(2.0)
	#一時停止解除後とフェーズ開始時に無敵になる不具合アリ
	
func update_hp_bar():
	$UI/enemyHP.max_value = phases[current_phase]["hp"]  # フェーズごとの最大HP
	$UI/enemyHP.value = current_hp 
	
# ProgressBar設定
func update_timelimit_bar(phase_index: int):
	var phase = phases[phase_index]
	time_bar.max_value = phase["duration"]
	time_bar.value = phase["duration"]
	
func be_invincible(time: float) -> void:
	invincible = true
	invincible_timer.wait_time = time  # タイマーの待ち時間をセット
	invincible_timer.start()  # タイマー開始
func _on_invincible_timer_timeout() -> void:
	invincible = false  # 無敵解除
	print("無敵終了！")
	
	
func _process(delta):
	if last_damage_time >= 0:
		last_damage_time -= delta
		if !get_tree().paused and !is_pattern_running:
			# skill_1のときだけ再開（ただし一度だけ）
			if phases[current_phase]["pattern"] == "skill_1" and !resumed_skill_1:
				print("ポーズ解除されたからスキル再開！")
				resumed_skill_1 = true
				start_skill_1()
		

func take_damage(amount: int):
	if invincible:
		#print("無敵中なのでダメージ無効")
		return
	if last_damage_time > 0:
		#print("ダメージクールタイム中なので無視")
		return
	if current_hp <= 0:
		return  # すでに死んでる or フェーズ移行中なら何もしない

	current_hp = max(current_hp - amount, 0)
	update_hp_bar()
	#print("ダメージ受けた！現在HP:", current_hp)

	last_damage_time = damage_cooldown

	if current_hp == 0:
		phase_timer.stop()
		next_phase()
# ========================
# ▼ フェーズ移行時
# ========================
func next_phase():
	print("フェーズ移動します")
	Global.add_time_bonus_score(time_remaining)
	is_pattern_running = false 
	can_shoot = false
	rain_timer.stop()
	await get_tree().create_timer(1.0).timeout  # 少し待つ（これでループ終了を待つ）
	await move_to(Vector2(634, 200))
	current_phase += 1
	var controller = get_parent()
	if controller and controller.has_method("end_skill_phase"):
		await controller.end_skill_phase()  # スキル背景フェードアウト呼び出し
	if current_phase >= phases.size():
		die()  # 全フェーズ終了（ゲームオーバーや勝利処理）
	else:
		current_hp = phases[current_phase]["hp"]
		update_hp_bar()
		update_timelimit_bar(current_phase)
		start_phase(current_phase)  # 攻撃パターン切り替えなど
		be_invincible(4.0)  # フェーズ切り替え時に無敵
		
		
# ========================
# ▼ 通常攻撃1のパターン処理 
# ========================
func move_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	await tween.finished

func start_pattern_1():
	var my_phase = current_phase  # ★自分がスタートしたときのフェーズを記録

	is_pattern_running = true 
	print("フェーズ１開始: hp =", current_hp)

	while is_pattern_running and current_hp > 0:
		# ★フェーズが変わってたら即終了！
		if current_phase != my_phase:
			print("フェーズ変わったので中断")
			break

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
		
		print("ループ中... HP:", current_hp)
		
	is_pattern_running = false
	print("パターン終了！HPが0 or フェーズ移行！")
	
# ========================
# ▼ あめあめふれふれのパターン処理 
# ========================
func start_skill_1() -> void:
	if is_pattern_running:
		return  # すでに動いてたら何もしない

	is_pattern_running = true
	phase_timer.start()
	print("フェーズ２を始めるよ")

	while current_hp > 0 and time_remaining > 0:
		if get_tree().paused:
			print("ポーズ中だから弾撃ち停止！")
			break

		shoot_rain_bullet()
		await get_tree().create_timer(0.2).timeout

	is_pattern_running = false
	rain_timer.stop()
	print("skill_1パターン終了")

	
# ========================
# ▼ 通常攻撃2のパターン処理 
# ========================
func start_pattern_2():
	var my_phase = current_phase
	is_pattern_running = true
	can_shoot = true
	phase_timer.start()
	print("フェーズ3開始: hp =", current_hp)

	while is_pattern_running and current_hp > 0:
		if current_phase != my_phase:
			print("フェーズ変わったので中断")
			break

		Global.play_effect_and_sound(global_position)
		await get_tree().create_timer(2.0).timeout
		await move_to(Vector2(350, 200))
		await shoot_bullets(2)  
		await get_tree().create_timer(2.0).timeout

		await move_to(Vector2(900, 200))
		await shoot_bullets(2)  
		await get_tree().create_timer(1.0).timeout

		await move_to(Vector2(634, 200))
		await shoot_bullets(2)  
		await get_tree().create_timer(1.0).timeout

		print("ループ中... HP:", current_hp)

	is_pattern_running = false
	print("パターン終了！HPが0 or フェーズ移行！")
	
# ========================
# ▼ 日照り雨のパターン処理 
# ========================
func start_skill_2() -> void:
	if is_pattern_running:
		return  # 多重実行防止！

	is_pattern_running = true
	can_shoot = true
	phase_timer.start()
	print("フェーズ4開始: hp =", current_hp)

	call_deferred("rain_bullet_loop")
	await circle_bullet_loop()

	is_pattern_running = false
	rain_timer.stop()
	print("skill_2パターン終了")


func rain_bullet_loop() -> void:
	while current_hp > 0:
		if get_tree().paused:
			await wait_until_unpaused()
		shoot_rain_bullet()
		await get_tree().create_timer(0.3).timeout


func circle_bullet_loop() -> void:
	while current_hp > 0:
		if get_tree().paused:
			await wait_until_unpaused()
		await shoot_bullets(2)
		await get_tree().create_timer(2.0).timeout


# ポーズ解除まで待機する共通関数
func wait_until_unpaused() -> void:
	while get_tree().paused:
		await get_tree().process_frame

# ========================
# ▼ 弾発射処理 ▼
# ========================
func shoot_bullet1(angle_offset := 0.0):
	if not can_shoot:
		return  # 弾撃つの禁止されてたら何もしない
	shot_sound_player.play()
	var bullet_count = 10
	var speed = 200.0
	
	for i in range(bullet_count):
		var angle = TAU * i / bullet_count + angle_offset
		var direction = Vector2(cos(angle), sin(angle)).normalized()
		
		var bullet = bullet1_scene.instantiate()
		bullet.position = global_position + direction * 10  # ちょい前に出す

		if bullet.has_method("set_velocity"):
			bullet.set_velocity(direction * speed)

		get_parent().add_child(bullet)  # より安全な追加方法
		
func shoot_rain_bullet():
	shotsound2_play.play()
	var bullet = bullet2_scene.instantiate()
	var random_x = randf() * (1000 - 280) + 280  # 280～1000までのランダムX座標
	bullet.position = Vector2(random_x, 0)  # 画面の上端

	var direction = Vector2(0, 1)  # 真下に落ちる
	var speed = 300
	bullet.set_velocity(direction * speed)
	get_parent().add_child(bullet) 

func shoot_bullets(count: int) -> void:
	for i in range(count):
		var angle_offset = 0.0
		if i == 1:
			angle_offset = deg_to_rad(15)  # 2発目だけ15度ずらす例
		shoot_bullet1(angle_offset)
		await get_tree().create_timer(0.3).timeout

# ========================
# ▼ 死亡 ▼
# ========================
func die():
	print("ボス撃破")
	ui.hide_skill_name()
	Global.shake_screen(10.0, 0.5)  # 強さ8、0.3秒間
	Global.add_score(10000)
	Global.play_boss_dead_effect(Vector2(640, 200))  # 画面中央あたり
	emit_signal("battle_ended")
	queue_free()  # ボスを消す（アニメーションや演出があるならそこに飛ばす）
