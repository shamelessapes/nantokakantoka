extends Node2D                                                    # ルートは Node2D

# === フェーズ1（0〜20秒）用 ===
@export var phase1_scene: PackedScene           # フェーズ1で出す敵シーン
@export var phase1_interval: float = 1.5        # フェーズ1の出現間隔（秒）

# === フェーズ2（20秒以降）用 ===
@export var phase2_scene: PackedScene           # フェーズ2で出す敵シーン
@export var phase2_interval: float = 2.0        # フェーズ2の出現間隔（秒）

# === 出現範囲 ===
@export var min_x: float = 280                  # X 最小
@export var max_x: float = 710                  # X 最大
@export var spawn_y: float = 0               # Y は画面上固定（下げたいときは数値調整）

const PHASE_SWITCH_TIME := 20.0                 # フェーズ切替秒数

var elapsed_time := 0.0                         # 経過時間
var timer_phase1 := 0.0                         # フェーズ1用タイマー
var timer_phase2 := 0.0                         # フェーズ2用タイマー
var in_phase2 := false                          # 今フェーズ2かどうか

func _process(delta: float) -> void:
	elapsed_time += delta                       # 経過時間を加算

	# ── フェーズ切替判定 ──
	if not in_phase2 and elapsed_time >= PHASE_SWITCH_TIME:
		in_phase2 = true                        # 20秒到達でフェーズ2に切替
		timer_phase2 = 0.0                      # 新タイマーをリセット

	# ── フェーズ1処理 ──
	if not in_phase2:                           # フェーズ1中なら
		timer_phase1 -= delta
		if timer_phase1 <= 0.0:
			_spawn_enemy(phase1_scene)          # 旧ザコを出す
			timer_phase1 = phase1_interval      # タイマー再設定

	# ── フェーズ2処理 ──
	else:                                       # フェーズ2中なら
		timer_phase2 -= delta
		if timer_phase2 <= 0.0:
			_spawn_enemy(phase2_scene)          # 新ザコを出す
			timer_phase2 = phase2_interval      # タイマー再設定

# 敵を出現させる共通関数
func _spawn_enemy(scene: PackedScene) -> void:
	var enemy := scene.instantiate()                                # シーン生成
	enemy.position = Vector2(randf_range(min_x, max_x), spawn_y)    # Xランダム・Y固定
	get_parent().add_child(enemy)                                   # ステージに追加
