extends CharacterBody2D
#------------------事前準備------------------
@onready var bullet1_scene = preload("res://tscn/tekidan_1.tscn")
@onready var bullet2_scene = preload("res://tscn/tekidan_2.tscn")
@onready var hp_bar = $UI/enemyHP
@onready var invincible_timer = $invincible_timer  # Timerノードへの参照
@onready var shot_sound_player := $shotsound  # AudioStreamPlayerノード
@onready var move_timer = $MoveTimer  # シーンにあるTimerノードを参照

var current_phase = 0
var current_hp = 1
var invincible = true
var damage_cooldown := 0.1  # ダメージ無効時間（秒）
var last_damage_time := -1.0


var move_steps = [
	Vector2(350, 200),
	Vector2(900, 200),
	Vector2(634, 200),
]
var step_index = 0

#ーーーーーーーーーーーフェーズ管理ーーーーーーーーーーー
var phases = [
	{ "type": "normal", "hp": 100, "duration": 30, "pattern": "pattern_1" },
	{ "type": "skill", "hp": 500, "duration": 30, "pattern": "skill_1", "name": "あめあめふれふれ" },
	{ "type": "normal", "hp": 250, "duration": 30, "pattern": "pattern_2" },
	{ "type": "skill", "hp": 500, "duration": 30, "pattern": "skill_2", "name": "日照り雨" },
]
func start_phase(phase_index: int):
	var pattern_name = phases[phase_index]["pattern"]
	match pattern_name:
		"pattern_1":
			start_pattern_1(phase_index)
			print("フェーズ１スタート")
		#"skill_1":
			#start_skill_1()
			#print("フェーズ2スタート")
		#"pattern_2":
			#start_pattern_2()
			#print("フェーズ3スタート")
		#"skill_2":
			#start_skill_2()
			#print("フェーズ4スタート")
#ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー

func _ready():
	$Animation.play("default")
	current_hp = phases[current_phase]["hp"]
	update_hp_bar()
	be_invincible(3.0)
	move_timer.connect("timeout", Callable(self, "_on_move_timer_timeout"))
	
#ーーーーーーーーーボス登場演出ーーーーーーーーーー
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(position.x, 200), 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)  # 上からスーッと降りる演出
	tween.finished.connect(func(): start_phase(current_phase))
	
func update_hp_bar():
	$UI/enemyHP.max_value = phases[current_phase]["hp"]  # フェーズごとの最大HP
	$UI/enemyHP.value = current_hp 
	
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

func take_damage(amount: int):
	if invincible:
		print("無敵中なのでダメージ無効")
		return
	if last_damage_time > 0:
		print("ダメージクールタイム中なので無視")
		return
	
	current_hp -= amount
	update_hp_bar()
	print("ダメージ受けた！現在HP:", current_hp)

	last_damage_time = damage_cooldown  # 無敵時間セット

	if current_hp <= 0:
		next_phase()


func next_phase():
	current_phase += 1
	if current_phase >= phases.size():
		die()  # 全フェーズ終了（ゲームオーバーや勝利処理）
	else:
		current_hp = phases[current_phase]["hp"]
		update_hp_bar()
		start_phase(current_phase)  # 攻撃パターン切り替えなど
		be_invincible(2.0)  # フェーズ切り替え時に無敵
		
func start_pattern_1(phase_index: int):
	var phase = phases[phase_index]
	print("フェーズ開始！", phase["pattern"])
	start_move()
func start_move():
	step_index = 0
	move_timer.wait_time = 2.0
	move_timer.start()

func _on_move_timer_timeout():
	if step_index < move_steps.size():
		move_to(move_steps[step_index])
		# shoot() 呼びたいならここでOK
		step_index += 1
		move_timer.wait_time = 2.0
		move_timer.start()
	else:
		print("動き完了！")
func move_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)




func die():
	queue_free()  # ボスを消す（アニメーションや演出があるならそこに飛ばす）
