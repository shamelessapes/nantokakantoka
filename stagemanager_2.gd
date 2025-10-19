extends Node2D

# ====== エクスポート（敵シーンや演出シーンはあとで追加）======
@export var phase1_scene: PackedScene
@export var phase2_scene: PackedScene
@export var phase3_scene: PackedScene
@export var phase4_scene: PackedScene
@export var phase5_scene: PackedScene
@export var phase6_scene: PackedScene
@export var phase7_scene: PackedScene
@export var phase8_scene: PackedScene

# ====== 基本設定 ======
@export var min_x: float = 280.0
@export var max_x: float = 910.0
@export var spawn_y: float = 0.0

@onready var animation_player: AnimationPlayer = get_parent().get_node("CanvasLayer/AnimationPlayer")

var transitioning_phase := false  # フェーズ移行中フラグ
var boss_started := false  # 最初はボス未開始
var boss: Node = null                           # ボス参照
signal stage_cleared

# ====== フェーズ時間 ======
const PHASE1_TIME := 10.88
const PHASE15_TIME := 5.0 
const PHASE2_TIME := 38.0
const PHASE3_TIME := 41.5
const PHASE4_TIME := 10.88
const PHASE5_TIME := 26.0
const PHASE6_TIME := 48.0

# ====== 管理用変数 ======
var elapsed_time := 0.0
var current_phase := 0
var phase_timer := 0.0
var spawn_enabled := false
var stage_started := false

# --- フェーズ1用 ---
const PHASE1_INTERVAL := 0.86
const PHASE1_MAX_WAVES := 7
var phase1_wave := 0
var phase1_timer := 0.0

# --- フェーズ２用 ---
const PHASE2_INTERVAL := 1.72
const PHASE2_WAVES := 11
var phase2_wave := 0
var phase2_timer := 0.0
var phase2_left_side := true  # true=左、false=右
@export var enemy_bullet_2: PackedScene 

# --- フェーズ3用 ---
const PHASE3_INTERVAL := 1.72
const PHASE3_MAX_WAVES := 14
var phase3_wave := 0
var phase3_timer_main := 0.0
var phase3_timer_extra := 0.0

# --- フェーズ5用 ---
const PHASE5_INTERVAL := 6.88
const PHASE5_WAVES := 2
var phase5_max_waves := PHASE5_WAVES
const PHASE5_BULLET_INTERVAL := 1.72
const PHASE5_LEFT_LIMIT := 310
const PHASE5_RIGHT_LIMIT := 970
var phase5_wave := 0
var phase5_timer := 0.0
var phase5_enemies := [] # 追跡用
var phase5_bullet_timers := {} # 敵ごとの弾タイマー
var phase5_spin_dir := {} # 敵ごとの弾回転方向（渦巻用）
@export var phase5_bullet_scene: PackedScene 
var enemy = phase5_scene

# --- フェーズ６用 ---
const PHASE6_WAVES := 3

func _ready() -> void:
	await Global.fade_in(Color.BLACK)
	boss = get_node_or_null(".../boss_2")      # 階層は実際のパスに合わせて
	if boss:
		boss.call("set_boss_battle_gate", false)  # ★ステージ開始直後は必ずOFF（保険）

func start_stage() -> void:
	if stage_started:
		return  # 二重起動防止
	stage_started = true
	_start_phase(7) # 直接フェーズ1から開始

func _process(delta: float) -> void:
	
	if transitioning_phase:
		return # フェーズ移行中は何もしない
	if not stage_started:
		return # ステージが開始されるまで完全に停止
	
	elapsed_time += delta
	phase_timer -= delta
	
	# フェーズ0の時は何もしない（_next_phaseを呼ばない）
	if current_phase == 0:
		return
	
	# --- 通常フェーズ進行 ---
	phase_timer -= delta
	if phase_timer <= 0.0:
		transitioning_phase = true
		_next_phase()
		return
	
	match current_phase:
		1:
			phase1_timer -= delta
			if phase1_wave == 0:
				phase1_wave = 1
				_spawn_phase1_wave(1)
				phase1_timer = PHASE1_INTERVAL
			elif phase1_wave < PHASE1_MAX_WAVES and phase1_timer <= 0.0:
				phase1_wave += 1
				_spawn_phase1_wave(phase1_wave)
				phase1_timer = PHASE1_INTERVAL
				
		15: # ★ 1.5フェーズ
			pass
		2:
			# フェーズ2の処理
			phase2_timer -= delta
			if phase2_wave < PHASE2_WAVES and phase2_timer <= 0.0:
				phase2_wave += 1
				_spawn_phase2_enemy(phase2_left_side)
				phase2_left_side = not phase2_left_side  # 交互切替
				phase2_timer = PHASE2_INTERVAL
		3:
			# フェーズ3の処理
			if current_phase == 3:
			# メイン（フェーズ2の敵）
				phase3_timer_main -= delta
			if phase3_wave < PHASE3_MAX_WAVES and phase3_timer_main <= 0.0:
				phase3_wave += 1
				_spawn_phase2_enemy(phase2_left_side)  # ←フェーズ3用の左右フラグ
				phase2_left_side = not phase2_left_side
				phase3_timer_main = PHASE3_INTERVAL

			# 追加敵（別の場所に1体出す）
			phase3_timer_extra -= delta
			if phase3_timer_extra <= 0.0:
				_spawn_phase3_extra_enemy()
				phase3_timer_extra = PHASE3_INTERVAL

		4:
			phase1_timer -= delta
			if phase1_wave == 0:
				phase1_wave = 1
				_spawn_phase1_wave(1)
				phase1_timer = PHASE1_INTERVAL
			elif phase1_wave < PHASE1_MAX_WAVES and phase1_timer <= 0.0:
				phase1_wave += 1
				_spawn_phase1_wave(phase1_wave)
				phase1_timer = PHASE1_INTERVAL
		5:
			phase5_timer -= delta
			if phase5_wave < PHASE5_WAVES and phase5_timer <= 0.0:
				phase5_wave += 1
				_spawn_phase5_enemy(phase5_wave)
				phase5_timer = PHASE5_INTERVAL
		
			# --- 敵の移動・弾制御 ---
			for enemy in phase5_enemies:
				if not is_instance_valid(enemy):
					continue
				if enemy.position.x <= PHASE5_LEFT_LIMIT:
					enemy.move_to(Vector2(1, 0.2))
				elif enemy.position.x >= PHASE5_RIGHT_LIMIT:
					enemy.move_to(Vector2(-1, 0.2))
				
			if current_phase == 3:
				# 敵がまだいなければ何もしない
				if phase5_bullet_timers.is_empty():
					return
		
			# 敵ごとの弾タイマー処理
			for enemy in phase5_bullet_timers.keys():
				# ① 敵が削除されてたら辞書からも消す
				if not is_instance_valid(enemy):
					phase5_bullet_timers.erase(enemy)
					phase5_spin_dir.erase(enemy)
					continue
		# ② 登録されてない場合はスキップ（安全策）
				if not phase5_bullet_timers.has(enemy):
					continue
				# ③ タイマーを減算
				phase5_bullet_timers[enemy] -= delta
				# ④ 発射タイミングになったら弾発射
				if phase5_bullet_timers[enemy] <= 0.0:
					_fire_phase5_bullets(enemy, phase5_spin_dir.get(enemy, 1))
					phase5_bullet_timers[enemy] = PHASE5_BULLET_INTERVAL
			
		6:
			phase5_timer -= delta
			if phase5_wave < phase5_max_waves and phase5_timer <= 0.0:
				phase5_wave += 1
				var enemy = _spawn_phase5_enemy(phase5_wave)  # 敵を受け取るように変更
				enemy.hp = 7  # フェーズ6だけHPを変更
				phase5_timer = PHASE5_INTERVAL

		
			# --- 敵の移動・弾制御 ---
			for enemy in phase5_enemies:
				if not is_instance_valid(enemy):
					continue
				if enemy.position.x <= PHASE5_LEFT_LIMIT:
					enemy.move_to(Vector2(1, 0.2))
				elif enemy.position.x >= PHASE5_RIGHT_LIMIT:
					enemy.move_to(Vector2(-1, 0.2))
				
			if current_phase == 3:
				# 敵がまだいなければ何もしない
				if phase5_bullet_timers.is_empty():
					return
		
			# 敵ごとの弾タイマー処理
			for enemy in phase5_bullet_timers.keys():
				# ① 敵が削除されてたら辞書からも消す
				if not is_instance_valid(enemy):
					phase5_bullet_timers.erase(enemy)
					phase5_spin_dir.erase(enemy)
					continue
		# ② 登録されてない場合はスキップ（安全策）
				if not phase5_bullet_timers.has(enemy):
					continue
				# ③ タイマーを減算
				phase5_bullet_timers[enemy] -= delta
				# ④ 発射タイミングになったら弾発射
				if phase5_bullet_timers[enemy] <= 0.0:
					_fire_phase5_bullets(enemy, phase5_spin_dir.get(enemy, 1))
					phase5_bullet_timers[enemy] = PHASE5_BULLET_INTERVAL
			# フェーズ3の流用
			if current_phase == 6:
			# メイン（フェーズ2の敵）
				phase3_timer_main -= delta
			if phase3_wave < PHASE3_MAX_WAVES and phase3_timer_main <= 0.0:
				phase3_wave += 1
				_spawn_phase2_enemy(phase2_left_side)  # ←フェーズ3用の左右フラグ
				phase2_left_side = not phase2_left_side
				phase3_timer_main = PHASE3_INTERVAL
				# --- フェーズ2型の敵もスポーン（ここ修正） ---
			phase3_timer_main -= delta
			var max_waves = PHASE3_MAX_WAVES   # ←デフォルト15
			if current_phase == 6:
				max_waves = 36               # ←フェーズ6だけ36に変更

			if phase3_wave < max_waves and phase3_timer_main <= 0.0:
				phase3_wave += 1
				_spawn_phase2_enemy(phase2_left_side)
				phase2_left_side = not phase2_left_side
				phase3_timer_main = PHASE3_INTERVAL

# ====== フェーズ開始処理 ======
func _start_phase(phase: int) -> void:
	current_phase = phase
	match phase:
		1: 
			phase_timer = PHASE1_TIME
			phase1_wave = 0
			phase1_timer = 0.0
		15:
			phase_timer = PHASE15_TIME 
			animation_player.play("stage1")
		2: phase_timer = PHASE2_TIME
		3: 
			phase_timer = PHASE3_TIME
			phase3_wave = 0
			phase3_timer_main = 0.0
			phase3_timer_extra = 0.0
			phase2_left_side = true  # 左右リセット
		4: 
			phase_timer = PHASE1_TIME
			phase1_wave = 0
			phase1_timer = 0.0
		5: 
			phase_timer = PHASE5_TIME
			phase5_wave = 0
			phase5_timer = 0.0
			phase5_enemies.clear()
			phase5_bullet_timers.clear()
			phase5_spin_dir.clear()
		6:
			phase_timer = PHASE6_TIME
			phase2_left_side = true
			phase5_wave = 0
			phase5_timer = 0.0
			phase5_enemies.clear()
			phase5_bullet_timers.clear()
			phase5_spin_dir.clear()
			phase5_max_waves = 100


# ====== フェーズ進行 ======
func _next_phase() -> void:
	print("次のフェーズへ: ", current_phase)
	
		# === ここでフェーズ2と3と6の退場処理を挟む ===
	if current_phase in [2, 3, 6]:
		_phase_clear_enemies()
	match current_phase:
		1:
			_start_phase(15)   # ★ フェーズ1の次はフェーズ1.5へ
			transitioning_phase = false
		15:
			_start_phase(2)    # ★ 1.5が終わったらフェーズ2へ
			transitioning_phase = false
		7:
			if not boss_started:
				boss_started = true
				call_deferred("_go_to_boss_scene")
				
		_:
			# それ以外は通常通り+1
			_start_phase(current_phase + 1)
			phase_timer = get_phase_time(current_phase) # 新しいフェーズタイマーをセット
			transitioning_phase = false
			
func get_phase_time(phase: int) -> float:
	match phase:
		1: return PHASE1_TIME
		15: return PHASE15_TIME
		2: return PHASE2_TIME
		3: return PHASE3_TIME
		4: return PHASE4_TIME
		5: return PHASE5_TIME
		6: return PHASE6_TIME
		_: return 10.0



# ====== 敵スポーン関数======
func _spawn_enemy(scene: PackedScene) -> void:
	if scene == null:
		return
	var enemy := scene.instantiate()
	enemy.position = Vector2(randf_range(min_x, max_x), spawn_y)
	get_parent().add_child(enemy)

# ====== ボス戦へ遷移 ======
func _go_to_boss_scene():
	await get_tree().create_timer(2.5).timeout
	emit_signal("stage_cleared")
	queue_free()

	
	
# ---- about phase1 ----	
func _spawn_phase1_wave(count: int) -> void:
	if phase1_scene == null:
		return
	var step: float = (max_x - min_x) / float(count - 1) if count > 1 else 0.0
	for i in range(count):
		var x: float = min_x + float(i) * step
		var enemy: Area2D = phase1_scene.instantiate()
		enemy.hp = 1
		enemy.position = Vector2(x, 0) # y=0から落ちてくる
		get_parent().add_child(enemy)

		# Tween設定
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)

		# 1. y=0 → y=300（加速）
		tween.set_ease(Tween.EASE_IN)
		tween.tween_property(enemy, "position", Vector2(x, 300), 300.0 / 300.0)

		# 2. y=300 → y=1000（落下は等速 or 緩やか）
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(enemy, "position", Vector2(x, 1200), (1200.0 - 300.0) / 300.0)

		# 3. y=1000到達後に消滅
		tween.tween_callback(Callable(enemy, "queue_free"))


# ---- about phase2 ----
func _spawn_phase2_enemy(is_left: bool) -> void:
	if phase2_scene == null:
		return

	# ★ 通常はPHASE2_WAVESを使用し、フェーズ6なら別の数に変更
	var waves = PHASE2_WAVES
	if current_phase == 6:
		waves = 36 

	# ↓ wavesを使ってスポーン処理を書く（例では1体ずつなのでそのまま）
	var enemy: Area2D = phase2_scene.instantiate()
	enemy.be_invincible(1.0) 
	enemy.set_meta("is_left", is_left)  # スポーン時に記録
	enemy.add_to_group("phase_enemy")


	# 出現位置
	var start_x: float = 250.0 if is_left else 930.0
	enemy.position = Vector2(start_x, 100.0)
	get_parent().add_child(enemy)
 

	# 0.7秒かけて x±200 に横移動（Tween使用）
	var offset_x: float = 200.0 if is_left else -200.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(enemy, "position", Vector2(start_x + offset_x, 100.0), 0.7)

	# 移動完了後に弾を撃つ & ゆっくり下降
	tween.tween_callback(func():
		if is_instance_valid(enemy):
			_phase2_fire_bullets(enemy)  # 弾発射
			# ↓ 下降Tweenもここで作る（enemyが有効なうちに）
			var fall_tween := create_tween()
			fall_tween.tween_property(enemy, "position", Vector2(enemy.position.x, 1200.0), (1200.0 - 200.0) / 100.0)
			fall_tween.tween_callback(Callable(enemy, "queue_free"))
		)
	
func _phase2_fire_bullets(enemy: Area2D) -> void:
	if not is_instance_valid(enemy):
		return

	var fire_pos := enemy.position + Vector2(0, 20)  # 敵の真下から発射

	# --- デフォルトは6発、フェーズ6なら4発 ---
	var bullet_count = 6
	if current_phase == 6:
		bullet_count = 4

	var spread_angle := 80.0  # 放射の角度（-40°～+40°）
	var start_angle := 90.0 - spread_angle / 2.0  # 左端の角度

	for i in range(bullet_count):
		var bullet: Area2D = enemy_bullet_2.instantiate()
		bullet.position = fire_pos
		SoundManager.play_se_by_path("res://se/se_beam05.mp3", -20)

		# 弾の角度を計算（float型を明示）
		var angle_deg: float = start_angle + (spread_angle / (bullet_count - 1)) * i
		bullet.rotation = deg_to_rad(angle_deg - 90.0)


		# 弾の速度ベクトルを設定
		var speed := 200.0
		var dir := Vector2(cos(deg_to_rad(angle_deg)), sin(deg_to_rad(angle_deg)))
		bullet.set("velocity", dir * speed)

		get_parent().add_child(bullet)

func _phase_clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("phase_enemy"):
		if not is_instance_valid(enemy):
			continue
		var is_left: bool = enemy.get_meta("is_left", true)
		var target_x = 0.0 if is_left else 1300.0

		var tween := create_tween()
		tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(enemy, "position", Vector2(target_x, enemy.position.y), 1.0)
		tween.tween_callback(Callable(enemy, "queue_free"))


# ---- about phase3 ----
func _spawn_phase3_extra_enemy():
	if phase3_scene == null:
		return
	var enemy: Area2D = phase3_scene.instantiate()
	enemy.hp = 1
	enemy.be_invincible(2.0)  
	enemy.position = Vector2(600, 0)  # 中央付近から出現
	get_parent().add_child(enemy)

# --- about phase5 ----
func _spawn_phase5_enemy(wave: int) -> Area2D:
	if phase5_scene == null:
		return null

	var enemy: Area2D = phase5_scene.instantiate()
	enemy.position = Vector2(320, 0)
	enemy.be_invincible(3.5)
	get_parent().add_child(enemy)

	enemy.move_to(Vector2(1, 0.2))

	phase5_enemies.append(enemy)
	phase5_bullet_timers[enemy] = 1.0
	phase5_spin_dir[enemy] = 1 if wave % 2 == 1 else -1

	return enemy  # ここで生成した敵を返す




func _fire_phase5_bullets(enemy: Area2D, spin_dir: int) -> void:
		# --- デフォルト弾数は8 ---
	var bullet_count = 8
	# --- フェーズ6だけ5発に変更 ---
	if current_phase == 6:
		bullet_count = 5
	for i in range(bullet_count):
		var bullet: Area2D = phase5_bullet_scene.instantiate()
		bullet.global_position = enemy.global_position
		# 角度を弾数に応じて均等に配置する
		bullet.set("direction", Vector2.RIGHT.rotated(i * (TAU / bullet_count)))
		bullet.set("spin_dir", spin_dir)
		bullet.set("speed", 200.0)
		get_parent().add_child(bullet)
