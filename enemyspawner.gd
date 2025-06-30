extends Node2D

@export var phase1_scene: PackedScene
@export var phase2_scene: PackedScene
@export var phase3_scene: PackedScene

@export var min_x: float = 280.0
@export var max_x: float = 910.0
@export var spawn_y: float = 0.0

@onready var animation_player: AnimationPlayer = get_parent().get_node("CanvasLayer/AnimationPlayer")

const PHASE2_START_TIME := 15.0
const PHASE3_START_TIME := 40.0
const PHASE4_START_TIME := 60.0
const PHASE4_END_TIME := 75.0

var elapsed_time := 0.0
var current_phase := 1
var spawn_enabled := false
const SPAWN_DELAY := 3.0

var waiting_for_phase2 := false
var phase2_wait_timer := 0.0
const ANIMATION_WAIT_TIME := 5.0

# フェーズごとのタイマー
var timer_phase1 := 0.0
var timer_phase2 := 0.0
var timer_phase3 := 0.0
var phase4_row_timer := 0.0
var phase4_active := false

# 一列に出す敵の設定
const PHASE4_ROW_INTERVAL := 3.0
const PHASE4_ENEMY_COUNT := 9
const PHASE4_IMMUNITY_TIME := 0.5
const PHASE4_ROW_PAUSE_Y := 100.0
const PHASE4_FINAL_Y := 300.0
const PHASE4_MOVE_DURATION := 1.0
const PHASE4_DESCEND_DELAY := 0.2  # 右から順に降ろす遅延

func _ready() -> void:
	await Global.fade_in(Color.BLACK)


func _process(delta: float) -> void:
	elapsed_time += delta

	if not spawn_enabled:
		if elapsed_time >= SPAWN_DELAY:
			spawn_enabled = true
			elapsed_time = 0.0
		return

	# フェーズ1 → 2 のアニメ演出
	if current_phase == 1 and elapsed_time >= PHASE2_START_TIME and not waiting_for_phase2:
		waiting_for_phase2 = true
		phase2_wait_timer = ANIMATION_WAIT_TIME
		animation_player.play("stage1")
		return

	if waiting_for_phase2:
		phase2_wait_timer -= delta
		if phase2_wait_timer <= 0.0:
			waiting_for_phase2 = false
			current_phase = 2
			timer_phase2 = 0.0
		else:
			return

	if current_phase == 2 and elapsed_time >= PHASE3_START_TIME:
		current_phase = 3
		timer_phase2 = INF
		timer_phase3 = 0.0

	if current_phase == 3 and elapsed_time >= PHASE4_START_TIME:
		current_phase = 4
		timer_phase3 = INF
		phase4_active = true
		phase4_row_timer = 0.0

	if current_phase == 4:
		if elapsed_time >= PHASE4_END_TIME:
			phase4_active = false
			current_phase = 5
			await get_tree().create_timer(3.0).timeout  # 3秒待機
					# 遷移を deferred 呼び出し
			call_deferred("_go_to_boss_scene")
		elif phase4_active:
			phase4_row_timer -= delta
			if phase4_row_timer <= 0.0:
				_spawn_phase4_row()
				phase4_row_timer = PHASE4_ROW_INTERVAL
				

	# フェーズ1の通常出現
	if current_phase == 1:
		timer_phase1 -= delta
		if timer_phase1 <= 0.0:
			_spawn_enemy(phase1_scene)
			timer_phase1 = 1.5

	# フェーズ2
	if current_phase == 2:
		timer_phase2 -= delta
		if timer_phase2 <= 0.0:
			_spawn_enemy(phase2_scene)
			timer_phase2 = 1.5

	# フェーズ3
	if current_phase == 3:
		timer_phase3 -= delta
		if timer_phase3 <= 0.0:
			_spawn_enemy(phase3_scene)
			timer_phase3 = 2.0

func _spawn_enemy(scene: PackedScene) -> void:
	if scene == null:
		return
	var enemy := scene.instantiate()
	enemy.position = Vector2(
		randf_range(min_x, max_x),
		spawn_y
	)
	get_parent().add_child(enemy)

#------フェーズ4------
func _spawn_phase4_row():
	if phase1_scene == null:
		return
	var step := (max_x - min_x) / (PHASE4_ENEMY_COUNT - 1)
	for i in range(PHASE4_ENEMY_COUNT):
		var enemy := phase1_scene.instantiate()
		enemy.can_move = false  # ← ここで止める
		enemy.hp = 25
		var x := min_x + i * step
		enemy.position = Vector2(x, spawn_y)
		enemy.set("is_invincible", true)
		get_parent().add_child(enemy)

		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)

# y = 100 まで一列に並ぶ（1秒）
		tween.tween_property(enemy, "position", Vector2(x, 100), 1.0)

# 順番に y=300 まで降下（1秒後に順次）
		var total_delay = 1.0 + i * 0.2  # 1秒後に右から順に落ちる
		tween.tween_property(enemy, "position", Vector2(x, 1000), 3.0).set_delay(total_delay)

# Tween終了後に移動再開
		tween.tween_callback(Callable(enemy, "_resume_move")).set_delay(total_delay + 1.0)


		# 無敵解除タイマー
		var timer := Timer.new()
		timer.wait_time = PHASE4_IMMUNITY_TIME
		timer.one_shot = true
		timer.connect("timeout", Callable(enemy, "_on_invincibility_end"))
		enemy.add_child(timer)
		timer.start()
		
		
func _go_to_boss_scene():
	await Global.change_scene_with_fade("res://tscn/boss_zikken.tscn" , Color.WHITE)
