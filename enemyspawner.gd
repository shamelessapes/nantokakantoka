extends Node2D                                             # ルートは Node2D

# === フェーズ1（0〜20 秒）用 ===
@export var phase1_scene: PackedScene           # フェーズ1で出す敵シーン
@export var phase1_interval: float = 1.5        # フェーズ1の出現間隔（秒）

# === フェーズ2（20〜40 秒）用 ===
@export var phase2_scene: PackedScene           # フェーズ2で出す敵シーン
@export var phase2_interval: float = 1.5        # フェーズ2の出現間隔（秒）

# === フェーズ3（40 秒以降）用 ===
@export var phase3_scene: PackedScene           # フェーズ3で出す敵シーン
@export var phase3_interval: float = 2.0        # フェーズ3の出現間隔（秒）

# === 出現範囲 ===
@export var min_x: float = 280.0                # X 最小
@export var max_x: float = 710.0                # X 最大
@export var spawn_y: float = 0.0                # Y 固定（上端）

const PHASE2_START_TIME := 20.0                 # Phase2 開始秒
const PHASE3_START_TIME := 40.0                 # Phase3 開始秒

var elapsed_time := 0.0                         # 経過時間
var timer_phase1 := 0.0                         # フェーズ1用タイマー
var timer_phase2 := 0.0                         # フェーズ2用タイマー
var timer_phase3 := 0.0                         # フェーズ3用タイマー
var current_phase := 1                          # 今のフェーズ (1 / 2 / 3)
var spawn_enabled := false                      # 出現許可フラグ（最初は false）
const SPAWN_DELAY := 3.0                        # 出現までの待機秒数


func _process(delta: float) -> void:            # 毎フレーム処理
	elapsed_time += delta                       # 経過時間を進める
	# 最初の3秒間は何も出さない
	if not spawn_enabled:
		elapsed_time += delta
		if elapsed_time >= SPAWN_DELAY:
			spawn_enabled = true  # 3秒経過後に敵出現開始
			elapsed_time = 0.0    # 経過時間をリセットして Phase 管理開始
		return  # 敵出現処理はスキップ

	# ── フェーズ移行判定 ──
	if current_phase == 1 and elapsed_time >= PHASE2_START_TIME:
		current_phase = 2                       # Phase2 へ移行
		timer_phase2 = 0.0                      # Phase2 タイマー初期化
	elif current_phase == 2 and elapsed_time >= PHASE3_START_TIME:
		current_phase = 3                       # Phase3 へ移行
		timer_phase2 = 0.0                      # 旧タイマー再リセット
		timer_phase3 = 0.0                      # Phase3 タイマー初期化

	# ── Phase1 処理 ──
	if current_phase == 1:
		timer_phase1 -= delta
		if timer_phase1 <= 0.0:
			_spawn_enemy(phase1_scene)
			timer_phase1 = phase1_interval

	# ── Phase2 敵（Phase2 と Phase3 で継続） ──
	if current_phase >= 2:
		timer_phase2 -= delta
		if timer_phase2 <= 0.0:
			_spawn_enemy(phase2_scene)
			timer_phase2 = phase2_interval

	# ── Phase3 敵（Phase3 のみ） ──
	if current_phase == 3:
		timer_phase3 -= delta
		if timer_phase3 <= 0.0:
			_spawn_enemy(phase3_scene)
			timer_phase3 = phase3_interval

# === 敵を出現させる共通関数 ===
func _spawn_enemy(scene: PackedScene) -> void:
	if scene == null:                           # シーン未設定なら何もしない
		return
	var enemy := scene.instantiate()            # 敵インスタンス生成
	enemy.position = Vector2(                   # 乱数で X を決めて
		randf_range(min_x, max_x),              #   ……ここが X
		spawn_y                                 #   ……ここが Y（固定）
	)
	get_parent().add_child(enemy)               # ステージに追加
