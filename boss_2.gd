extends CharacterBody2D

signal boss_defeated
signal boss_appeared

@export var boss_battle_gate: bool = false
# --- 追加: フラグ & デバッグ ---
var _is_advancing_phase: bool = false        # next_phaseの再入防止
var _ignore_log_count: int = 0               # 無視ログの連投を抑制
const PHASE_TRACE := true                    # trueなら最初だけスタックも出す
var _saved_layer: int = 0                      # ★元のレイヤー退避
var _saved_mask: int = 0                       # ★元のマスク退避
var is_transitioning: bool = false       # フェーズ切替中フラグ（再入防止/被弾停止用）

@export var max_hp := 10000# ← 各フェーズ専用の最大HP
var current_hp := 0  # ← 残りHP
var max_phase_hp = 0  # ← 各フェーズ専用の最大HP
var invincible := false


var current_phase := 0
var started_phase_index = -1
var is_battle_started := false
var time_remaining = 0
var step_index = 0
var is_pattern_running = false
var spawned_count := 0  
var spawned_zako: Array = []

@export var attack_interval := 3.0  # 3秒ごとに放射弾
var attack_timer: Timer

@onready var phase_timer = $Timer
@onready var time_bar = $UI/timelimit
@onready var invincible_timer = $invincible_timer  # Timerノードへの参照
@onready var shot_sound_player := $shotsound
@onready var shot_sound2_player := $shotsound2
@onready var Animationplayer := $Animation
@onready var load_bgm = get_node("../bgm")
@onready var boss_bgm = get_node("../bgm_boss")
@export var arena_min: Vector2 = Vector2(310, 100)   # 画面内の左上境界（内側）
@export var arena_max: Vector2 = Vector2(970, 1100)  # 画面内の右下境界（内側）
@export var arena_margin: Vector2 = Vector2(16, 16)  # ボスの大きさぶん余白（当たり判定/見た目で微調整）

var normal1_shoot_timer: Timer = null      # 通常攻撃１の射撃タイマー参照  # 外から停止できるようクラス変数に
var normal1_tween: Tween = null            # 通常攻撃１の移動Tween参照    # 停止時にkillする用

var move_speed_factor := 1.0       # ボスの移動速度倍率（1=通常、0.05=超スロー）  # 追加
var move_slow_until := 0.0         # この時刻(秒)までは遅く動く                        # 追加
var slow_restore_timer: Timer      # 遅さ解除のための一時タイマー                      # 追加
var is_attack2_active := false     # 通常攻撃２が稼働中かどうか                         # 追加
var shoot_timer: Timer = null      # 通常攻撃２の発射タイマー                           # 追加
var slow_until_sec := 0.0               # ここまで超スローを維持する（絶対秒）
var attack2_delay_timers: Array[Timer] = []  # 連発用の遅延タイマーを全部握る
var attack2_shoot_timer: Timer = null   # 通常攻撃２の発射タイマー        ←追加




# =========================
# 必殺技１：ぽんぽこ攪乱の術
# =========================

const BULLET_LEAF := preload("res://tscn/tekidan_4.tscn")    # 葉っぱ弾（扇状・回転に使う）
const BULLET_ACORN := preload("res://tscn/tekidan_5.tscn")   # ドングリ弾（狙い・わずかに加速）
const TEKIDAN5_SCENE := preload("res://tscn/tekidan_5.tscn")

@export var sp1_duration := 28.0        # 必殺技の総時間（秒）                         # バランス調整用
@export var sp1_leaf_interval := 2.0   # 葉っぱ弾の発射間隔（秒）                     # 早すぎると密度↑
@export var sp1_acorn_interval := 1.5   # ドングリ狙い撃ちの間隔（秒）                 # 適度な圧
@export var sp1_swap_interval := 3.5    # 分身入れ替え“っぽい動き”の間隔（秒）         # 読ませすぎない

@export var sp1_leaf_speed := 150.0     # 葉っぱ弾の初速                                # 遅めで花火っぽさ
@export var sp1_acorn_speed := 200.0    # ドングリ弾の初速                              # 後で微加速
@export var sp1_acorn_accel := 30.0     # ドングリ弾の毎秒加速（対応する弾側が必要）    # 未対応なら0に

@export var sp1_leaf_fan_count := 3     # 葉っぱの同時発射数（扇の本数）                # 5Way基本
@export var sp1_leaf_fan_spread := 26.0 # 扇の開き角（度）                               # 広げすぎ注意
@export var sp1_ring_count := 8        # 爆弾破裂の円弾の数                            # 12～24くらい

var sp1_running := false                # この必殺技が進行中か                          # ダブり開始防止
var sp1_time_left := 0.0                # 残り時間                                      # 終了判定用
var sp1_fan_angle := 0.0                # 扇の回転基準角                                # じわじわ回す

var sp1_decoy_offsets: Array[Vector2] = []        # 分身の相対位置（Vector2配列）
var sp1_decoy_nodes: Array[Node] = []             # 見た目ノード（Node配列）

@onready var sp1_leaf_timer: Timer = Timer.new()   # 葉っぱ用タイマー
@onready var sp1_acorn_timer: Timer = Timer.new()  # ドングリ用タイマー
@onready var sp1_swap_timer: Timer = Timer.new()   # 入れ替え演出タイマー
@onready var sp1_end_timer:  Timer = Timer.new()   # 総時間タイマー

var sp1_decoy_step: int = 0                                              # 今どの分身インデックスか
@export var sp1_decoy_order: PackedInt32Array = PackedInt32Array([       # 回る順番を決め打ち
	0, 7, 2, 6, 1, 5, 3, 4                                                # 例：左右・斜めをバランス良く巡回
])

# --- 必殺技２ 管理用メンバ ---
var _sp2_active: bool = false                                   # 稼働フラグ
var _sp2_radial_timer: Timer                                    # 放射弾タイマー
var _sp2_giant_timer: Timer                                     # 巨大弾タイマー
var _sp2_end_timer: Timer                                       # 終了（30秒）タイマー

# 巨大弾の進行方向ループ：真下 → 左下 → 右下 → 繰り返し
var _sp2_giant_dirs := [
	Vector2.DOWN,                           # 真下
	Vector2(-1, 1).normalized(),            # 左下
	Vector2( 1, 1).normalized()             # 右下
]
var _sp2_giant_dir_idx := 0                 # 現在の方向インデックス

# =========================
# 必殺技３：四方デコイ・七彩輪射
# =========================

const SP3_BULLET := preload("res://tscn/tekidan_5.tscn")                # 使う敵弾（tekidan_5）
@export var sp3_duration := 28.0                                        # 技全体の長さ（秒）
@export var sp3_decoy_shoot_interval := 1.5                              # デコイが円射する間隔
@export var sp3_boss_aim_interval := 1.8                                 # 本体の自機狙い間隔
@export var sp3_radial_count := 7                                        # 円状の弾数（7発）
@export var sp3_radial_speed := 190.0                                    # 円射の速度
@export var sp3_aim_speed := 280.0                                       # 自機狙い弾の速度
@export var sp3_aim_accel := 0.0                                         # 自機狙いの直線加速（不要なら0）

@export var sp3_decoy_scale := 0.5                 # デコイの見た目サイズ倍率（小さめ）
@export var sp3_decoy_fallback_px := 12            # テクスチャ未設定時の代替スプライトの一辺(px)
@export var sp3_boss_bullet_scale := 1.3           # ボスが撃つ tekidan_5 の見た目サイズ倍率
@export var sp3_boss_buddy_offset := 14.0       # 相棒弾の横ズレ距離（ピクセル）   # 調整用



# ★デコイ用スプライト
@export var sp3_decoy_texture: Texture2D                                 # 無ければColorRectで代用

var sp3_running := false                                                 # 技が稼働中か（再入防止）

var sp3_decoy_nodes: Array[Node2D] = []              # ← Array[Node2D] と明示
var sp3_color_index := 0
var sp3_colors: Array[Color] = [                      # ← Array[Color] と明示
	Color(1.0, 0.55, 0.8),    # ピンク
	Color(1.0, 1.0, 0.2)      # 黄色
]


# デコイの相対配置（左右・斜め下左右）
var sp3_decoy_offsets := [
	Vector2(-120,   0),  # 左
	Vector2( 120,   0),  # 右
	Vector2(-90,  120),  # 左下
	Vector2( 90,  120),  # 右下
]

# タイマー群
var sp3_decoy_timer: Timer
var sp3_boss_aim_timer: Timer
var sp3_end_timer: Timer




#ーーーーーーーーーーーフェーズ管理ーーーーーーーーーーー
var phases = [
	{ "type": "normal", "hp": 450, "duration": 30, "pattern": "pattern_1" },
	{ "type": "skill", "hp": 600, "duration": 30, "pattern": "skill_1", "name": "ぽんぽこ攪乱の術" },
	{ "type": "normal", "hp": 500, "duration": 30, "pattern": "pattern_2" },
	{ "type": "skill", "hp": 600, "duration": 30, "pattern": "skill_2", "name": "でっかいきんのたま" },
	{ "type": "skill", "hp": 600, "duration": 30, "pattern": "skill_3", "name": "令和たぬき合戦ぽんぽこ" },
]

func set_boss_battle_gate(on: bool) -> void:
	boss_battle_gate = on                      # 値更新
	if on:                                     # ゲートON（ボス戦開始）
		# 衝突レイヤー/マスクを復元（当たり判定を戻す）
		collision_layer = _saved_layer          # 元のレイヤーに戻す
		collision_mask  = _saved_mask           # 元のマスクに戻す
		_set_hitboxes_enabled(true)             # 子のCollisionShape2Dも有効化
		add_to_group("attackable")              # ★被弾OKグループに入れる
		set_process(true)                       # 任意：処理再開
		set_physics_process(true)               # 任意：処理再開
		show()
		call_deferred("show")   # 同フレームで上書きされても次フレで確実に表示
		print("[GATE] ON")
	else:                                      # ゲートOFF（道中）
		# まず現在のレイヤー/マスクを退避
		_saved_layer = collision_layer          # 現在値を保存
		_saved_mask  = collision_mask           # 現在値を保存
		# 衝突を完全に切る（弾から見えなくする）
		collision_layer = 0                     # 何にも当たらないレイヤ
		collision_mask  = 0                     # 何も検知しないマスク
		_set_hitboxes_enabled(false)            # 子のCollisionShape2Dも無効化
		remove_from_group("attackable")         # ★被弾不可グループへ
		stop_all_attacks()                      # 実行中の攻撃を全停止
		set_process(false)                      # 任意：処理停止（呼び出しは可能）
		set_physics_process(false)              # 任意：処理停止
		hide()
		call_deferred("hide")   # 次フレでもう一度隠す（点滅等のshow対策）
		print("[GATE] OFF -> stop attacks")

func _set_hitboxes_enabled(enabled: bool) -> void:
	# ★ボス配下の CollisionShape2D / CollisionPolygon2D をまとめてON/OFF
	for n in get_children():                   # 直下から
		_enable_shapes_recursive(n, enabled)   # 再帰で子孫も見る

func _enable_shapes_recursive(node: Node, enabled: bool) -> void:
	if node is CollisionShape2D:               # 形状ノードなら
		(node as CollisionShape2D).set_deferred("disabled", not enabled)  # 遅延で切替
	elif node is CollisionPolygon2D:           # 多角形の形状も対応
		(node as CollisionPolygon2D).set_deferred("disabled", not enabled)
	for c in node.get_children():              # 子にも潜る
		_enable_shapes_recursive(c, enabled)

func _ready():
	# ★シーン読み込み直後に“必ず”OFF＋全停止（道中Phase1で暴発しないための保険）
	set_boss_battle_gate(false)              # ゲートOFF（内部で全停止
	hide()
	
	slow_restore_timer = Timer.new()                                     # 遅さ解除用タイマーを作成
	slow_restore_timer.one_shot = true                                   # 1回だけ発火
	add_child(slow_restore_timer)                                        # シーンに追加
	slow_restore_timer.timeout.connect(func ():
		var now := Time.get_ticks_msec() / 1000.0                        # 現在時刻（秒）
		if now >= move_slow_until:                                       # 期限を過ぎたら
			move_speed_factor = 1.0                                      # 速度倍率を元に戻す
		else:
			var remain := move_slow_until - now                          # まだ遅延が残っていれば
			slow_restore_timer.start(remain)                             # 残り時間でもう一度セット
	)
	
	var stage = get_parent().get_node_or_null("dialoguemanager")
	if stage:
		stage.connect("dialogue_finished", Callable(self, "_on_dialogue_finished"))
	else:
		print("dialoguemanager が見つかりません！")
	
	$Animation.play("default")
	$UI/timelimit.visible = false
	$UI/enemyHP.visible = false
	
	phase_timer.connect("timeout", Callable(self, "_on_Timer_timeout"))
	
	invincible_timer.one_shot = true
	invincible_timer.timeout.connect(_on_invincible_timer_timeout)
	
		# Timerを作ってセットアップ
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_interval
	attack_timer.one_shot = false
	add_child(attack_timer)

func slow_move_for(sec: float, slow_factor: float = 0.06) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var deadline := now + sec
	if deadline > slow_until_sec:
		slow_until_sec = deadline
	move_speed_factor = slow_factor     # すぐに遅くする



func _physics_process(delta: float) -> void:
	global_position = _clamp_to_arena(global_position)  # 毎フレーム最終的に枠に収める
		# --- 遅さの自動復帰 ---
	var now := Time.get_ticks_msec() / 1000.0
	if now >= slow_until_sec and move_speed_factor != 1.0:
		move_speed_factor = 1.0
	
func _on_Timer_timeout():
	# 1秒ごとにタイマー更新
	time_remaining -= 1
	time_bar.value = time_remaining
	
	if time_remaining <= 0:
		print("時間切れ！フェーズ強制終了！")
		phase_timer.stop()
		next_phase("phase_timer")  # ★呼び元名を渡す)

func update_hp_bar():
	$UI/enemyHP.max_value = max_phase_hp
	$UI/enemyHP.value = current_hp
	
func update_timelimit_bar(phase_index: int):
	var phase = phases[phase_index]
	time_bar.max_value = phase["duration"]
	time_bar.value = phase["duration"]

func _boss_show() -> void:
	# 登場演出
	show()
	print("登場した")
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(position.x, 200), 1.5) \
	.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)  # 上からスーッと降りる演出
	print(position)
	#tween.finished.connect(_on_drop_finished)
	await tween.finished  # Tweenが終わるのを待つ
	# ※ここではまだ攻撃開始しない（会話後に開始）

func _on_dialogue_finished():
		# ボスがまだ出てないなら無視
	if not is_visible_in_tree():
		return
	# 会話が終わったら攻撃開始
	set_boss_battle_gate(true)
	if is_battle_started:
		return # すでに開始済みなら無視
	$UI/timelimit.visible = true
	$UI/enemyHP.visible = true
	is_battle_started = true
	load_bgm.stop()
	boss_bgm.play()
	current_phase = 0
	start_phase(0)

func start_phase(phase_index: int):
	# 同じフェーズが二重に呼ばれたらキャンセル
	if not boss_battle_gate:
		print("[PHASE] gate=OFF, ignore _start_phase(", phase_index, ")")
		return
	if phase_index == started_phase_index:
		print("⚠️ 同じフェーズが二重に呼ばれたのでキャンセル")
		return
	started_phase_index = phase_index

	# フェーズ情報を取得（変数名を変えて衝突回避）
	var phase_data : Dictionary = phases[phase_index]
	
	print("フェーズ開始:", phase_data["pattern"], "HP=", current_hp)

	max_phase_hp = phase_data["hp"]
	current_hp = max_phase_hp
	update_hp_bar()
	update_timelimit_bar(phase_index)
	is_pattern_running = false

	time_remaining = phase_data["duration"]
	phase_timer.wait_time = 1.0  # 1秒ごとに減らす
	phase_timer.start()

	var pattern_name = phase_data["pattern"]
	match pattern_name:
		"pattern_1":
			start_normal_attack_1()
		"skill_1":
			set_boss_battle_gate(true)    # ★ここで初めてON！
			print("ボス攻撃開始")
			start_special_attack_1()
		"pattern_2":
			start_normal_attack_2()
		"skill_2":
			start_special_attack_2()
		"skill_3":
			start_special_attack_3()
		_:
			die()


# --- 攻撃パターン ---
# --- 通常攻撃１ ---
func start_normal_attack_1() -> void:
	print("通常攻撃１開始")                                      # ログ
	stop_normal_attack_1()                                       # 二重起動防止：以前の残りを全停止
	is_pattern_running = true                                    # パターン開始フラグON

	# 開始時に無敵＆エフェクト
	be_invincible(2.5)                                           # 2.5秒無敵（演出）
	Global.play_effect_and_sound(global_position)                # 開幕エフェクトSE

	# ▼ 長いawaitを避けて“様子見ループ”で待つ（falseになったら即中断）
	var inv_timer := get_tree().create_timer(2.5)               # 2.5秒タイマー作成
	while is_pattern_running and inv_timer.time_left > 0.0:      # 走行中かつ残り>0なら
		await get_tree().process_frame                           # 1フレーム待つ

	if not is_pattern_running:                                   # 途中で停止指示が来たら
		stop_normal_attack_1()                                   # 後始末して
		return                                                   # ここで終わり

	# 最初に指定位置まで移動（Tween＋様子見で中断可能に）
	var target := Vector2(900, 200)                              # 目的地
	if has_method("_clamp_to_arena"):                            # 画面枠クランプがあるなら
		target = _clamp_to_arena(target)                         # 枠内に補正
	normal1_tween = create_tween()                               # Tween作成
	normal1_tween.tween_property(self, "global_position", target, 0.6)  # 0.6秒で移動
	while is_pattern_running and normal1_tween.is_running():     # 動いている間だけ
		await get_tree().process_frame                           # 1フレーム待つ
	if not is_pattern_running:                                   # 停止指示が来たら
		stop_normal_attack_1()                                   # 即後始末
		return                                                   # 終了

	# 移動用のフラグと制限
	var move_dir := -1                                           # 左向きスタート
	var left_limit := 350                                        # 左端X
	var right_limit := 900                                       # 右端X
	var move_speed := 30.0                                       # 移動速度

	# 弾発射用タイマー（コールバック側でも走行中かを確認）
	normal1_shoot_timer = Timer.new()                            # タイマー作成
	normal1_shoot_timer.wait_time = 1.5                          # 発射間隔
	normal1_shoot_timer.one_shot = false                         # 繰り返し
	add_child(normal1_shoot_timer)                               # ツリーに追加
	normal1_shoot_timer.timeout.connect(func():                  # 無名関数で接続
		if not is_pattern_running:                                # 走行中でなければ
			return                                               # 何もしない
		fire_radial_bullets(10, true)                            # 10発、kintama=true（既存関数）
	)
	normal1_shoot_timer.start()                                  # タイマースタート

	# 攻撃ループ（24秒間）※ 走行中かつフェーズ条件が合う間だけ動く
	var attack_time := 24.0                                      # 総時間
	var elapsed := 0.0                                           # 経過
	while (
		is_pattern_running
		and elapsed < attack_time
		and current_phase < phases.size()
		and phases[current_phase]["pattern"] == "pattern_1"
	):
		var delta := get_process_delta_time()                     # 経過フレーム秒
		elapsed += delta                                          # 経過更新

		# 横移動（枠内で左右に往復）
		position.x += move_dir * move_speed * move_speed_factor * delta
		if position.x <= left_limit:                              # 左端で
			position.x = left_limit                               # はみ出し修正
			move_dir = 1                                          # 右向きへ
		elif position.x >= right_limit:                           # 右端で
			position.x = right_limit                              # はみ出し修正
			move_dir = -1                                         # 左向きへ

		# 画面枠のクランプ（任意：あれば安全）
		if has_method("_clamp_to_arena"):                         # クランプ関数があれば
			global_position = _clamp_to_arena(global_position)    # 枠内に収める

		await get_tree().process_frame                            # 1フレーム待つ

	# ここに来たら自然終了 or 外部停止
	stop_normal_attack_1()                                       # タイマー/Tweenを確実に停止
	print("通常攻撃１終了")                                       # ログ

	# 自然に走り切った場合のみ次フェーズへ（外部停止時は既に別開始が走る想定）
	if elapsed >= attack_time and is_inside_tree():               # 時間満了で生きているなら
		next_phase()                                             # 既存のフェーズ進行

	
func stop_normal_attack_1() -> void:
	# === 通常攻撃１を強制停止（タイマー/Tween/フラグの後始末） ===
	is_pattern_running = false                                   # パターンフラグを下げる
	if is_instance_valid(normal1_shoot_timer):                   # 射撃タイマーが生きていれば
		normal1_shoot_timer.stop()                               # 停止
		normal1_shoot_timer.queue_free()                         # 破棄
		normal1_shoot_timer = null                               # 参照クリア
	if is_instance_valid(normal1_tween):                         # 移動Tweenが生きていれば
		normal1_tween.kill()                                     # 即殺
		normal1_tween = null                                     # 参照クリア




func start_special_attack_1():
	# === 必殺技１開始 ===
	if not boss_battle_gate:
		print("[SP1] gate=OFF, ignored")       # ★道中で呼ばれても無視
		return 
	print("必殺技１開始")
	await get_tree().get_current_scene().enter_spell("ぽんぽこ攪乱の術")
	Animationplayer.play("atack")
	
	if sp1_running:                               # すでに起動していたら
		return                                     # 二重起動防止
	sp1_running = true                            # 実行フラグON
	sp1_time_left = sp1_duration                  # 残り時間を設定
	be_invincible(0.8)                       # 開幕少しだけ無敵（点滅などの演出は任意）

	# 分身の相対位置（十字＋斜め）を用意（見た目を置かなくても“そこから弾が出る”）
	sp1_decoy_offsets = [
		Vector2(120, 0), Vector2(-120, 0), Vector2(0, 120), Vector2(0, -120),
		Vector2(90, 90), Vector2(90, -90), Vector2(-90, 90), Vector2(-90, -90)
	]

	# 必要なら見た目用の分身ノードを作る（Sprite2Dがなければ小さなColorRectでもOK）
	_create_decoy_visuals()                        # 省略可：見た目いらなければ中でreturnしてOK

	# タイマー（葉っぱ扇）
	sp1_leaf_timer.one_shot = false               # 周期タイマー
	sp1_leaf_timer.wait_time = sp1_leaf_interval  # 間隔を設定
	sp1_leaf_timer.timeout.connect(_on_sp1_leaf_timeout)  # コールバック接続
	add_child(sp1_leaf_timer)                     # ノードツリーに追加
	sp1_leaf_timer.start()                        # スタート

	# タイマー（狙いドングリ）
	sp1_acorn_timer.one_shot = false              # 周期タイマー
	sp1_acorn_timer.wait_time = sp1_acorn_interval# 間隔を設定
	sp1_acorn_timer.timeout.connect(_on_sp1_acorn_timeout) # コールバック接続
	add_child(sp1_acorn_timer)                    # 追加
	sp1_acorn_timer.start()                       # スタート

	# タイマー（入れ替え演出）
	sp1_swap_timer.one_shot = false               # 周期タイマー
	sp1_swap_timer.wait_time = sp1_swap_interval  # 間隔設定
	sp1_swap_timer.timeout.connect(_on_sp1_swap_timeout)   # コールバック接続
	add_child(sp1_swap_timer)                     # 追加
	sp1_swap_timer.start()                        # スタート

	# タイマー（総時間）
	sp1_end_timer.one_shot = true                 # 一度だけ
	sp1_end_timer.wait_time = sp1_duration        # 終了までの秒数
	sp1_end_timer.timeout.connect(_on_sp1_end_timeout)     # 終了時処理
	add_child(sp1_end_timer)                      # 追加
	sp1_end_timer.start()                         # スタート

func stop_special_attack_1() -> void:
	# === 必殺技１の強制停止（フェーズ移行など） ===
	if not sp1_running:                           # 走ってなければ
		return                                     # 何もしない
	sp1_running = false                           # フラグOFF
	Animationplayer.play("default")
	if is_instance_valid(sp1_leaf_timer):         # タイマー停止と片付け
		sp1_leaf_timer.stop()
		sp1_leaf_timer.queue_free()
	if is_instance_valid(sp1_acorn_timer):        # 同上
		sp1_acorn_timer.stop()
		sp1_acorn_timer.queue_free()
	if is_instance_valid(sp1_swap_timer):         # 同上
		sp1_swap_timer.stop()
		sp1_swap_timer.queue_free()
	if is_instance_valid(sp1_end_timer):          # 同上
		sp1_end_timer.stop()
		sp1_end_timer.queue_free()
		
	await get_tree().get_current_scene().exit_spell()
	
	await move_to(Vector2(640, 200))
	_free_decoy_visuals()                         # 分身見た目を消去

func _on_sp1_leaf_timeout() -> void:
	# === 周囲の分身位置から“扇状”葉っぱ弾を撃つ ===
	if not sp1_running:
		return
	sp1_fan_angle += 8.0                              # 扇の基準角を回す
	for off in sp1_decoy_offsets:
		var origin: Vector2 = _clamp_to_arena(global_position + off)  # ★ 安全な発射原点
		_emit_leaf_fan(origin, deg_to_rad(sp1_fan_angle))             # 扇発射
		if randi() % 5 == 0:
			_spawn_leaf_bomb(origin)                    # 低確率で木の葉爆弾


func _on_sp1_acorn_timeout() -> void:
	# === 本体からプレイヤー狙いのドングリ3連 ===
	$shotsound2.play()
	if not sp1_running:                           # 念のため
		return
	var player := get_tree().get_first_node_in_group("player")  as Node2D # プレイヤー取得（あなたのプロジェクト基準のグループ名に合わせて）
	var to_player := (player.global_position - global_position).normalized() # 方向ベクトル
	if player == null:                            # いなければ
		return
	var spread := 10.0                            # 少し左右に散らす角度（度数）
	var dirs: Array[Vector2] = [                                                   # ★ 配列にも型
		to_player,
		to_player.rotated(deg_to_rad(spread)),
		to_player.rotated(deg_to_rad(-spread))
	]
	for dir in dirs:                              # 3本撃つ
		var b := BULLET_ACORN.instantiate()       # ドングリ弾生成
		b.global_position = global_position       # 位置セット
		# ドングリ3連のとき
		_apply_velocity_to_bullet(b, dir, sp1_acorn_speed, sp1_acorn_accel)
	# 葉っぱ発射のとき（加速不要なので0）
		_apply_velocity_to_bullet(b, dir, sp1_leaf_speed, 0.0)
		_add_bullet(b)                            # シーンに追加

func _on_sp1_swap_timeout() -> void:
	if not sp1_running:
		return
	be_invincible(0.25)                                              # 演出

	# ★ ランダム廃止：決め打ち順でインデックスを進める
	var idx: int = sp1_decoy_order[sp1_decoy_step % sp1_decoy_order.size()]  # 次の番号
	sp1_decoy_step += 1                                                      # カウンタ進める

	# 目標座標は“現在位置＋分身オフセット”で相対移動（クランプで安全化）
	var raw_target: Vector2 = global_position + sp1_decoy_offsets[idx]       # 相対ターゲット
	var target: Vector2 = _clamp_to_arena(raw_target)                         # 画面内に収める
	var hop: Vector2 = _clamp_to_arena(target + Vector2(18, -6))              # ちょい跳ね演出も安全化

	var tween := create_tween()
	tween.tween_property(self, "global_position", target, 0.15)               # まず移動
	tween.tween_property(self, "global_position", hop, 0.06)                  # ピョン
	tween.tween_property(self, "global_position", target, 0.08)               # 戻る



func _on_sp1_end_timeout() -> void:
	# === 規定時間で終了 ===
	stop_special_attack_1()                        # 停止＆弾消し
	# 次の処理（フェーズ進行）は既存のボス管理に合わせてここで呼ぶ              # 例: emit_signal("attack_finished")

func _clamp_to_arena(pos: Vector2) -> Vector2:
	# 座標posをステージ枠内に収めて返す
	var minx: float = arena_min.x + arena_margin.x   # 余白込みの最小X
	var maxx: float = arena_max.x - arena_margin.x   # 余白込みの最大X
	var miny: float = arena_min.y + arena_margin.y   # 余白込みの最小Y
	var maxy: float = arena_max.y - arena_margin.y   # 余白込みの最大Y
	return Vector2(clampf(pos.x, minx, maxx), clampf(pos.y, miny, maxy))  # クランプして返す

func _inside_arena(pos: Vector2) -> bool:
	# すでに枠内ならtrue（デバッグ用）
	return _clamp_to_arena(pos) == pos               # クランプ前後で変化がなければ内側


# -------------------------
# 発射系ユーティリティ
# -------------------------

func _emit_leaf_fan(origin: Vector2, base_angle_rad: float) -> void:
	$shotsound.play()
	# 扇状に葉っぱ弾をn本撃つ
	var half := (sp1_leaf_fan_count - 1) * 0.5    # 中心からのオフセット計算
	for i in sp1_leaf_fan_count:                  # 0..n-1
		var t := (i - half)                        # -2,-1,0,1,2 みたいな並び
		var ang := base_angle_rad + deg_to_rad(t * sp1_leaf_fan_spread)  # 各弾の角度
		var dir := Vector2.RIGHT.rotated(ang)      # 右ベクトルを回転して方向に
		var b := BULLET_LEAF.instantiate()         # 葉っぱ弾生成
		b.global_position = origin                 # 位置セット
		_apply_velocity_to_bullet(b, dir, sp1_leaf_speed)  # 速度セット
		_add_bullet(b)                             # 追加

func _spawn_leaf_bomb(origin: Vector2) -> void:
	# “木の葉爆弾”の簡易実装（1.2秒後に円状に葉っぱ弾をばらまいて消える）
	var bomb := Node2D.new()                      # ダミーノード（見た目はお好みで）
	bomb.global_position = origin                 # 位置セット
	add_child(bomb)                               # シーンに追加
	var t := Timer.new()                          # タイマー作成
	t.one_shot = true                             # 一度だけ
	t.wait_time = 1.2                             # 信管時間
	t.timeout.connect(func ():
		_emit_leaf_ring(bomb.global_position)     # 円形ばら撒き
		bomb.queue_free()                         # 自爆して消える
	)
	bomb.add_child(t)                              # ボムの子にする
	t.start()                                      # スタート

func _emit_leaf_ring(center: Vector2) -> void:
	# 円形に葉っぱ弾をsp1_ring_count本発射
	for i in sp1_ring_count:                       # 本数分
		var ang := TAU * (float(i) / float(sp1_ring_count))    # 0..2πまで等間隔
		var dir := Vector2.RIGHT.rotated(ang)      # 方向ベクトル
		var b := BULLET_LEAF.instantiate()         # 葉っぱ弾生成
		b.global_position = center                 # 位置セット
		_apply_velocity_to_bullet(b, dir, sp1_leaf_speed)      # 速度セット
		_add_bullet(b)                             # 追加

# -------------------------
# 弾追加・速度適用の共通化
# -------------------------

func _add_bullet(b: Node) -> void:
	# 弾を親（ステージなど）にぶら下げる。ボス直下だと一緒に動くので注意。
	get_tree().current_scene.add_child(b)          # 安全に最上位（またはステージルート）へ追加（必要に応じて修正）
	b.add_to_group("bullet")                       # 弾グループに入れる（あなたのプロジェクトに合わせて）

func _apply_velocity_to_bullet(b: Node, dir: Vector2, spd: float, accel: float = 0.0) -> void:
	# 弾の共通入口 setup(dir, speed, accel) を呼ぶ前提に統一
	if b.has_method("setup"):                                # メソッドがあれば
		b.call("setup", dir, spd, accel)                    # それを呼ぶ
	else:
		# 念のための後方互換（もし別名で用意している場合）
		if b.has_method("init"):
			b.call("init", dir, spd, accel)
		elif b.has_method("configure"):
			b.call("configure", dir, spd, accel)
		else:
			# 最低限：見た目だけでも方向を向かせる（移動は弾側の処理に任せる）
			if b is Node2D:
				(b as Node2D).rotation = dir.angle()

#func _try_set(node: Node, prop: String, value) -> void:



# -------------------------
# 見た目：分身の作成/破棄（任意）
# -------------------------
func _create_decoy_visuals() -> void:
	# Sprite2D等がなければ、軽いColorRectで代用。見た目不要ならreturnしてOK。
	for off in sp1_decoy_offsets:
		var r := ColorRect.new()                   # 四角いプレースホルダ
		r.color = Color(1, 1, 1, 0.1)             # うっすら白（半透明）
		r.size = Vector2(14, 14)                   # 小さめ
		r.pivot_offset = r.size * 0.5              # 中心揃え
		add_child(r)                               # 追加（ボスの子として相対座標でOK）
		r.position = off                           # 相対位置に置く
		sp1_decoy_nodes.append(r)                  # リストに保存

func _free_decoy_visuals() -> void:
	for n in sp1_decoy_nodes:                      # 残っていたら
		if is_instance_valid(n):
			n.queue_free()                        # 消す
	sp1_decoy_nodes.clear()                        # リストもクリア






# 弾を放射状に発射する関数
func fire_radial_bullets_phase1(count: int, kintama_flag: bool):
	var bullet_scene = preload("res://tscn/tekidan_5.tscn")
	SoundManager.play_se_by_path("res://se/ジングルベル01.mp3", 0)
	
	for i in range(count):
		var angle = (TAU / count) * i
		var dir = Vector2.RIGHT.rotated(angle).normalized()
		var offset = dir.orthogonal().normalized() * 12
		
		# 左の玉
		var b1 = bullet_scene.instantiate()
		b1.position = position - offset
		b1.set_velocity(dir)
		b1.direction = dir
		b1.kintama = false
		get_parent().add_child(b1)

		if kintama_flag:
			# 右の玉
			var b2 = bullet_scene.instantiate()
			b2.position = position + offset
			b2.set_velocity(dir)
			b2.direction = dir
			b2.kintama = false
			get_parent().add_child(b2)

# 必殺技終了
#func end_special_attack_1():
	#print("必殺技終わるよ")


func start_normal_attack_2():
	print("通常攻撃２開始")                               # デバッグ表示
	is_attack2_active = true                            # 攻撃２フラグON

	be_invincible(2.0)                                  # 開始演出：無敵
	Global.play_effect_and_sound(global_position)       # エフェクト/SE
	await get_tree().create_timer(2.0).timeout          # 少し待つ

	await move_to(Vector2(640, 200))                    # 開始位置（中央上）

	# 往復移動のパラメータ
	var move_dir := 1                                   # 右へ
	var left_limit := 360.0                             # 左端
	var right_limit := 920.0                            # 右端
	var base_speed := 120.0                             # 通常の横移動速度

	# 既存タイマーの後始末（保険）
	if attack2_shoot_timer:
		attack2_shoot_timer.stop()
		attack2_shoot_timer.queue_free()
		attack2_shoot_timer = null
	for t in attack2_delay_timers:
		if is_instance_valid(t):
			t.stop()
			t.queue_free()
	attack2_delay_timers.clear()

	# 周期発射タイマー（1.6秒ごとに3連発）
	attack2_shoot_timer = Timer.new()                   # タイマー作成
	attack2_shoot_timer.one_shot = false               # 繰り返し
	attack2_shoot_timer.wait_time = 2.0                # 発射間隔
	add_child(attack2_shoot_timer)                      # シーンに追加
	attack2_shoot_timer.timeout.connect(_on_attack2_shoot)  # 発射処理に接続
	attack2_shoot_timer.start()                        # スタート

	# 攻撃ループ：フェーズ管理は外のタイマーに任せる
	while is_attack2_active \
		and current_phase < phases.size() \
		and phases[current_phase]["pattern"] == "pattern_2":
		var delta := get_process_delta_time()           # 経過時間

		# “超スロー”の自動解除（期限を過ぎたら元速へ）
		var now := Time.get_ticks_msec() / 1000.0       # 現在時刻(秒)
		if now >= slow_until_sec and move_speed_factor != 1.0:
			move_speed_factor = 1.0

		# 横移動（速度倍率を掛ける）
		position.x += move_dir * base_speed * move_speed_factor * delta

		# 端で折り返し
		if position.x <= left_limit:
			position.x = left_limit
			move_dir = 1
		elif position.x >= right_limit:
			position.x = right_limit
			move_dir = -1

		await get_tree().process_frame                  # 次フレームへ

	# ここに来たらフェーズ外：片付け
	if attack2_shoot_timer:
		attack2_shoot_timer.stop()
		attack2_shoot_timer.queue_free()
		attack2_shoot_timer = null

	for t in attack2_delay_timers:
		if is_instance_valid(t):
			t.stop()
			t.queue_free()
	attack2_delay_timers.clear()

	move_speed_factor = 1.0                             # 元速へ戻す
	slow_until_sec = 0.0                                # 期限リセット
	is_attack2_active = false                           # フラグOFF


func stop_normal_attack_2() -> void:
	is_attack2_active = false

	# 発射タイマーを確実に停止
	if shoot_timer:
		shoot_timer.stop()
		shoot_timer.queue_free()
		shoot_timer = null

	# 遅延コール（2発目・3発目）も全破棄
	for t in attack2_delay_timers:
		if is_instance_valid(t):
			t.stop()
			t.queue_free()
	attack2_delay_timers.clear()

	# 速度を確実に元へ
	move_speed_factor = 1.0
	slow_until_sec = 0.0


# --- 通常攻撃２：周期発射の本体（3連発＋弾の減速） ---
func _on_attack2_shoot() -> void:
	if !is_attack2_active:
		return                                           # フェーズ外なら無視

	var bullet_scene: PackedScene = preload("res://tscn/tekidan_5.tscn")  # 弾シーン
	var count := 12                                     # 円の弾数
	var decel_time := 0.8                               # 弾の減速時間
	var accel_time := 1.2                               # 元速へ戻す時間

	# 1回目（角度オフセット0）
	_spawn_radial_with_slowdown(bullet_scene, count, 0.00, decel_time, accel_time)
	_make_boss_slow_for(decel_time, 0.06)              # ボスを0.8秒だけ“超スロー”に

	# 2回目（0.15秒後に少し回して撃つ）
	_delay_call_attack2(0.15, func ():
		if !is_attack2_active:
			return
		_spawn_radial_with_slowdown(bullet_scene, count, 0.45, decel_time, accel_time)
		_make_boss_slow_for(decel_time, 0.06)
	)

	# 3回目（0.30秒後にさらに回して撃つ）
	_delay_call_attack2(0.30, func ():
		if !is_attack2_active:
			return
		_spawn_radial_with_slowdown(bullet_scene, count, 0.90, decel_time, accel_time)
		_make_boss_slow_for(decel_time, 0.06)
	)





# --- 円状に生成し、各弾へ「減速→加速」を付与（左右はボス側で出す想定） ---
# --- 円状に左右2発ずつ生成し、各弾に「減速→加速」を付与 ---
func _spawn_radial_with_slowdown(
		bullet_scene: PackedScene, count: int, angle_offset: float,
		decel_time: float, accel_time: float) -> void:
	SoundManager.play_se_by_path("res://se/ジングルベル01.mp3", 0)   # 発射SE（任意）

	for i in range(count):                              # 0..count-1（重複なし）
		var angle := TAU * i / count + angle_offset     # 等間隔＋オフセット
		var dir := Vector2.RIGHT.rotated(angle).normalized()  # 発射方向
		var offset := dir.orthogonal().normalized() * 12      # 左右オフセット

		# 左弾
		var bL = bullet_scene.instantiate()
		bL.position = position - offset
		if bL.has_method("set_velocity"): bL.set_velocity(dir)
		if "direction" in bL: bL.direction = dir
		if "kintama" in bL: bL.kintama = false         # 複製は禁止（右は手動で出す）
		get_parent().add_child(bL)
		if bL.has_method("decel_then_accel"):
			bL.decel_then_accel(decel_time, accel_time, 0.02) # 0.8秒でほぼ停止→1.2秒で復帰

		# 右弾
		var bR = bullet_scene.instantiate()
		bR.position = position + offset
		if bR.has_method("set_velocity"): bR.set_velocity(dir)
		if "direction" in bR: bR.direction = dir
		if "kintama" in bR: bR.kintama = false
		get_parent().add_child(bR)
		if bR.has_method("decel_then_accel"):
			bR.decel_then_accel(decel_time, accel_time, 0.02)

# --- ボスを“超スロー”にする（指定秒だけ） ---
func _make_boss_slow_for(sec: float, factor: float = 0.06) -> void:
	move_speed_factor = factor                          # 速度倍率を下げる
	var now := Time.get_ticks_msec() / 1000.0           # 現在時刻
	var deadline := now + sec                            # 終了時刻
	if deadline > slow_until_sec:                        # より長ければ更新
		slow_until_sec = deadline


# --- 遅延呼び出し（攻撃２専用：停止時に一括破棄できるよう握る） ---
func _delay_call_attack2(sec: float, cb: Callable) -> void:
	var t := Timer.new()                                # 一時タイマー
	t.one_shot = true                                   # 1回だけ
	t.wait_time = sec                                   # 待ち時間
	add_child(t)                                        # シーンに追加
	attack2_delay_timers.append(t)                      # リストに保持
	t.timeout.connect(func ():
		if is_attack2_active and is_instance_valid(self):
			cb.call()                                   # コールバック実行
		if is_instance_valid(t):
			t.queue_free()                              # 後始末
		attack2_delay_timers.erase(t)                   # リストから外す
	)
	t.start()                                           # スタート






func start_special_attack_2() -> void:
	if _sp2_active:
		return                                       # 二重起動防止
	_sp2_active = true
	print("必殺技２『でっかいきんのたま』開始！")
	await get_tree().get_current_scene().enter_spell("でっかいきんのたま")
	if not boss_battle_gate:
		print("[SP1] gate=OFF, ignored")       # ★道中で呼ばれても無視
		return 
	Animationplayer.play("atack")
	be_invincible(2.0)

	# 攻撃中フラグON
	is_pattern_running = true

	# 中央にゆっくり移動

# ---- 放射（小弾・控えめ）----
	_sp2_radial_timer = Timer.new()
	_sp2_radial_timer.wait_time = 0.7                 # 小弾の間隔
	_sp2_radial_timer.timeout.connect(_on_sp2_radial_timeout)
	add_child(_sp2_radial_timer)
	_sp2_radial_timer.start()

	# ---- 巨大弾（方向ループ）----
	_sp2_giant_timer = Timer.new()
	_sp2_giant_timer.wait_time = 2.4                  # ★頻度半分（1.2→2.4）
	_sp2_giant_timer.timeout.connect(_on_sp2_giant_timeout)
	add_child(_sp2_giant_timer)
	_sp2_giant_timer.start()

	# ---- 30秒で自動停止 ----
	_sp2_end_timer = Timer.new()
	_sp2_end_timer.one_shot = true
	_sp2_end_timer.wait_time = 30.0
	_sp2_end_timer.timeout.connect(Callable(self, "_on_sp2_end_timeout"))  # 引数なし
	add_child(_sp2_end_timer)
	_sp2_end_timer.start()

func _on_sp2_end_timeout() -> void:
	stop_special_attack_2()



# =========================
# 必殺技２ 停止（外部からも呼べる）
# フェーズHPが0になったら Stage/Boss 側から呼んでOK
# =========================
func stop_special_attack_2() -> void:
	if not _sp2_active:
		return
	_sp2_active = false
	# タイマー掃除
	if is_instance_valid(_sp2_radial_timer): _sp2_radial_timer.queue_free()
	if is_instance_valid(_sp2_giant_timer):  _sp2_giant_timer.queue_free()
	if is_instance_valid(_sp2_end_timer):    _sp2_end_timer.queue_free()
	
	await get_tree().get_current_scene().exit_spell()
	
	print("必殺技２終了！")
	# ここで次フェーズに移行するならシグナル発火などを行う


# =========================
# 小弾（放射・控えめ）
# =========================
func _on_sp2_radial_timeout() -> void:
	if not _sp2_active: return
	var num_bullets := 10                            # 弾数控えめ
	var speed := 160.0
	for i in range(num_bullets):
		var b := TEKIDAN5_SCENE.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position

		var ang := deg_to_rad((360.0 / num_bullets) * i)
		var dir := Vector2(cos(ang), sin(ang))

		# tekidan_5 は内部で velocity 再計算する想定→ direction/speed を渡す
		b.direction = dir
		b.speed = speed
		b.scale = Vector2(0.7, 0.7)                   # ★小さめに
		# 渦巻きや外向き補正がある実装なら必要に応じて：
		# if "spiral_enabled" in b: b.spiral_enabled = true




# =========================
# 巨大弾（真下 → 左下 → 右下 → ループ）
# =========================
func _on_sp2_giant_timeout() -> void:
	if not _sp2_active: return

	var count := 2                                   # 1回に2発
	var offsets := [Vector2(-28, 0), Vector2(28, 0)] # 左右に少しずらす
	var speed := 160.0

	# 今回の進行方向を取り出し
	var dir: Vector2 = _sp2_giant_dirs[_sp2_giant_dir_idx]


	for i in range(count):
		var b := TEKIDAN5_SCENE.instantiate()
		get_parent().add_child(b)
		b.global_position = global_position + offsets[i % offsets.size()]

		# 直進させるため direction/speed を明示
		b.direction = dir
		b.speed = speed

		# 巨大弾は渦なしが安全（実装があると逸れるため）
		if "spiral_enabled" in b:  b.spiral_enabled = false
		if "outward_weight" in b:  b.outward_weight = 0.0

		b.scale = Vector2(3.2, 3.2)                   # ★より大きく
		b.modulate = Color(1.2, 1.0, 0.55)            # ほんのり金色

		# 着弾演出（時間で起爆／画面外で消す派なら tekidan 側の Notifier を使ってOK）
		var explode_timer := Timer.new()
		explode_timer.one_shot = true
		explode_timer.wait_time = 4.0

		var wr: WeakRef = weakref(b)  # ← ここも型を付けると親切
		explode_timer.timeout.connect(Callable(self, "_sp2_on_explode_timeout_wr").bind(wr))

		add_child(explode_timer)
		explode_timer.start()



	# 方向インデックスを回す（0→1→2→0…）
	_sp2_giant_dir_idx = (_sp2_giant_dir_idx + 1) % _sp2_giant_dirs.size()


# =========================
# 小弾（少量）
# =========================
func _spawn_small_bullets_few(center_pos: Vector2) -> void:
	var n := 4                                      # 量は控えめ
	var spd := 180.0
	for j in range(n):
		var s := TEKIDAN5_SCENE.instantiate()
		get_parent().add_child(s)
		s.global_position = center_pos

		var ang := deg_to_rad((360.0 / n) * j)
		s.direction = Vector2(cos(ang), sin(ang))
		s.speed = spd
		s.scale = Vector2(0.8, 0.8)


# WeakRef を受け取り、型付きで処理（Variant警告を回避）
func _sp2_on_explode_timeout_wr(wr: WeakRef) -> void:
	var bullet_obj: Object = wr.get_ref()        # ← Object型で受ける（Variant回避）
	if bullet_obj == null:
		return
	var bullet_node: Node2D = bullet_obj as Node2D  # ← Node2D(Area2Dの親)へキャスト
	if bullet_node and is_instance_valid(bullet_node):
		_spawn_small_bullets_few(bullet_node.global_position)
		bullet_node.queue_free()



func start_special_attack_3() -> void:
	# === 必殺技３ 開始 ===
	if sp3_running:
		return                                                      # 二重起動防止
	if not boss_battle_gate:
		print("[SP3] gate=OFF, ignored")                           # 道中呼び出しガード
		return

	print("必殺技３『令和たぬき合戦ぽんぽこ』開始！")
	await get_tree().get_current_scene().enter_spell("令和たぬき合戦ぽんぽこ")
	Animationplayer.play("atack")                                   # 既存アニメ名に合わせる
	be_invincible(1.5)                                              # 切替直後の保険
	sp3_running = true                                              # 稼働フラグON

	# 位置を軽く整える（演出に合わせてどうぞ）
	# await move_to(Vector2(640, 220))                             # 必要なら中央へ

	# デコイ生成（Spriteが未設定でも代替で動作）
	_sp3_create_decoys()

	# --- デコイの円射タイマー ---
	sp3_decoy_timer = Timer.new()
	sp3_decoy_timer.wait_time = sp3_decoy_shoot_interval
	sp3_decoy_timer.timeout.connect(_on_sp3_decoy_timeout)
	add_child(sp3_decoy_timer)
	sp3_decoy_timer.start()

	# --- 本体の自機狙いタイマー ---
	sp3_boss_aim_timer = Timer.new()
	sp3_boss_aim_timer.wait_time = sp3_boss_aim_interval
	sp3_boss_aim_timer.timeout.connect(_on_sp3_boss_aim_timeout)
	add_child(sp3_boss_aim_timer)
	sp3_boss_aim_timer.start()

	# --- 規定時間で自動終了 ---
	sp3_end_timer = Timer.new()
	sp3_end_timer.one_shot = true
	sp3_end_timer.wait_time = sp3_duration
	sp3_end_timer.timeout.connect(_on_sp3_end_timeout)
	add_child(sp3_end_timer)
	sp3_end_timer.start()


func stop_special_attack_3() -> void:
	await get_tree().get_current_scene().exit_spell()
	Global.clear_bullets()
	# === 必殺技３ 停止（フェーズ移行やHP0時など） ===
	if not sp3_running:
		return
	sp3_running = false                                              # 稼働フラグOFF
	Animationplayer.play("default")                                  # アイドルに戻す

	# タイマー後片付け（存在チェックしつつ安全に）
	if is_instance_valid(sp3_decoy_timer):
		sp3_decoy_timer.stop()
		sp3_decoy_timer.queue_free()
	if is_instance_valid(sp3_boss_aim_timer):
		sp3_boss_aim_timer.stop()
		sp3_boss_aim_timer.queue_free()
	if is_instance_valid(sp3_end_timer):
		sp3_end_timer.stop()
		sp3_end_timer.queue_free()

	# デコイ破棄
	_sp3_free_decoys()

	# 必要なら移動や無敵解除・弾消しなど、他必殺技に合わせてここで
	# （グローバル弾消し関数があれば呼ぶ）

# --- 内部：デコイ作成/破棄 ---
func _sp3_create_decoys() -> void:
	_sp3_free_decoys()                                              # 既存を掃除
	for off in sp3_decoy_offsets:                                   # 4体ぶん
		var n: Sprite2D                                             # 見た目は Sprite2D に統一
		if sp3_decoy_texture:
			n = Sprite2D.new()                                      # スプライト作成
			n.texture = sp3_decoy_texture                           # 用意済みテクスチャ
		else:
			# テクスチャ未設定時の簡易代替（半透明の白い正方形）
			var img := Image.create(sp3_decoy_fallback_px, sp3_decoy_fallback_px, false, Image.FORMAT_RGBA8)  # 正方形画像
			img.fill(Color(1, 1, 1, 0.15))                           # 半透明
			var tex := ImageTexture.create_from_image(img)           # テクスチャ化
			n = Sprite2D.new()                                      # スプライト作成
			n.texture = tex                                         # 貼る
		n.centered = true                                           # 原点は中心
		n.scale = Vector2(sp3_decoy_scale, sp3_decoy_scale)         # ★デコイのサイズを小さく
		add_child(n)                                                # ボスの子に追加（相対固定）
		n.position = off                                            # 位置
		sp3_decoy_nodes.append(n)                                   # 配列に保持



func _sp3_free_decoys() -> void:
	for n in sp3_decoy_nodes:
		if is_instance_valid(n):
			n.queue_free()                                        # 安全に消す
	sp3_decoy_nodes.clear()                                       # 配列も空に

# --- 内部：色ループ（ピンク→黄色→…） ---
func _sp3_next_color() -> Color:
	var c: Color = sp3_colors[sp3_color_index % sp3_colors.size()]  # ← Color を明示
	sp3_color_index = (sp3_color_index + 1) % sp3_colors.size()
	return c


# --- 内部：位置から円状に弾を撃つ ---
func _sp3_fire_radial_at(world_pos: Vector2) -> void:
	SoundManager.play_se_by_path("res://se/se_beam05.mp3")
	var col: Color = _sp3_next_color()
	for i in range(sp3_radial_count):
		var angle := TAU * float(i) / float(sp3_radial_count)
		var dir := Vector2.RIGHT.rotated(angle)
		var b := SP3_BULLET.instantiate() as Area2D
		get_tree().current_scene.add_child(b)
		b.global_position = world_pos
		b.modulate = col

		await get_tree().process_frame          # ★ _ready() 完了を保証
		_sp3_disable_swirl(b)                   # ★ 確実に無効化
		b.setup(dir, sp3_radial_speed, 0.0)     # 直進で発射

		b.kintama = true


# --- 内部：自機狙いを本体から「2連装」で発射（kintamaは使わず自前生成） ---
func _sp3_fire_aim_from_boss() -> void:
	SoundManager.play_se_by_path("res://se/ジングルベル01.mp3")
	var player := get_tree().get_first_node_in_group("player") as Node2D  # プレイヤー取得  # null対策
	if player == null:                                                     # 見つからなければ撃たない
		return                                                             # 早期return

	var dir := (player.global_position - global_position).normalized()     # 進行方向ベクトル（自機への単位ベクトル）
	var perp := Vector2(-dir.y, dir.x)                                     # dirに直交する単位ベクトル（左手系）※見た目で左右を決めたい時は符号反転でOK

	# ========== 1発目（メイン弾） ==========
	var b1 := SP3_BULLET.instantiate() as Area2D                           # 弾インスタンス生成
	b1.scale = Vector2(sp3_boss_bullet_scale, sp3_boss_bullet_scale)       # 見た目を拡大（先に設定）
	b1.global_position = global_position                                   # ★追加前にも座標を入れておく（保険）

	_add_bullet(b1)                                                         # 共通の追加関数でツリーに入れる（ここで_readyが走る）
	b1.global_position = global_position                                   # ★追加“後”にも念のため座標を再設定（位置が初期化される環境対策）
	b1.setup(dir, sp3_aim_speed, sp3_aim_accel)                             # 速度・加速を適用（渦巻きは既定のまま）

	# ========== 2発目（相棒弾：横にずらして双玉に見せる） ==========
	var b2 := SP3_BULLET.instantiate() as Area2D                           # もう1発生成
	b2.scale = Vector2(sp3_boss_bullet_scale, sp3_boss_bullet_scale)       # 同じサイズで拡大
	var buddy_spawn := global_position + perp * sp3_boss_buddy_offset      # 直交方向へオフセットした出現位置
	b2.global_position = buddy_spawn                                       # ★追加前に座標を入れておく

	_add_bullet(b2)                                                         # ツリーに入れる
	b2.global_position = buddy_spawn                                       # ★追加後にも座標を上書き（左上(0,0)発射の事故を防ぐ）
	b2.setup(dir, sp3_aim_speed, sp3_aim_accel)                             # 同じ速度で並走（＝見た目が“二連弾”になる）





# --- タイマー：デコイの円射 ---
func _on_sp3_decoy_timeout() -> void:
	if not sp3_running:
		return
	# デコイが消えていたら再生成（安全対策）
	if sp3_decoy_nodes.is_empty():
		_sp3_create_decoys()
	# 各デコイの「世界座標」から円射
	for n in sp3_decoy_nodes:
		if is_instance_valid(n):
			_sp3_fire_radial_at(n.global_position)

# --- タイマー：本体の自機狙い ---
func _on_sp3_boss_aim_timeout() -> void:
	if not sp3_running:
		return
	_sp3_fire_aim_from_boss()
	
	
# --- 汎用：プロパティ存在チェック（Object.get_property_list()で確認）
func _has_prop(obj: Object, name: String) -> bool:
	for p in obj.get_property_list():             # すべての公開プロパティ情報を走査
		if p.name == name:                        # 名前一致で存在とみなす
			return true
	return false

# --- 汎用：存在する時だけ set する
func _safe_set(obj: Object, name: String, value) -> void:
	if _has_prop(obj, name):
		obj.set(name, value)                      # 安全にセット（無ければ何もしない）

# --- tekidan_5.gd 用：渦巻き挙動を完全停止
func _sp3_disable_swirl(bullet: Area2D) -> void:
	if not is_instance_valid(bullet):
		return                                     # 弾が既に消えていたら無視

	# ↓ tekidan_5.gd に合わせて、存在するプロパティだけを確実にOFF/0にする
	_safe_set(bullet, "spiral_enabled", false)     # 渦巻きフラグOFF
	_safe_set(bullet, "spin_speed", 0.0)           # 回転角速度ゼロ
	_safe_set(bullet, "outward_weight", 0.0)       # 外向き補正ゼロ（完全直進化）
	_safe_set(bullet, "accel_per_sec", 0.0)        # 念のため加速もゼロ
	_safe_set(bullet, "spin_dir", 0)               # 向き±1を無効化（0）




# --- タイマー：終了 ---
func _on_sp3_end_timeout() -> void:
	stop_special_attack_3()               


#------------弾発射の関数------------
#-----------phase normal 1 ----------
func fire_radial_bullets(count: int, kintama_flag: bool):
	var bullet_scene = preload("res://tscn/tekidan_5.tscn")
	
	# === 1発目 ===
	_spawn_radial(bullet_scene, count, 0.0, kintama_flag)

	# === 0.3秒後に2発目（少し角度をずらす） ===
	await get_tree().create_timer(0.3).timeout
	_spawn_radial(bullet_scene, count, 1.0, kintama_flag)  # ← angle_offsetを0.1ラジアンくらいズラす

func _spawn_radial(bullet_scene, count: int, angle_offset: float, kintama_flag: bool):
	SoundManager.play_se_by_path("res://se/ジングルベル01.mp3", 0)
	for i in range(count):
		var angle = (TAU / count) * i + angle_offset  # ← ここで角度を少しずらす
		var dir = Vector2.RIGHT.rotated(angle).normalized()

		var offset = dir.orthogonal().normalized() * 12
		
		# 左の玉
		var b1 = bullet_scene.instantiate()
		b1.position = position - offset
		b1.set_velocity(dir)
		b1.direction = dir
		b1.kintama = false
		get_parent().add_child(b1)

		if kintama_flag:
			# 右の玉
			var b2 = bullet_scene.instantiate()
			b2.position = position + offset
			b2.set_velocity(dir)
			b2.direction = dir
			b2.kintama = false
			get_parent().add_child(b2)


func stop_all_attacks() -> void:                                      # すべての攻撃を強制停止する
	Global.clear_bullets()
	stop_special_attack_1()                                           # 必殺技１を停止（タイマー/分身/爆弾/弾消し）
	# stop_normal_attack_1()                                          # 他の攻撃があれば同様に呼ぶ（任意）
	# stop_normal_attack_2()                                          # ↑任意
	is_pattern_running = false                                        # 自前の進行フラグがあれば下げておく



# ---------------------------------------------

func take_damage(amount: int):
	if invincible:
		return
	if not boss_battle_gate:                   # 道中ヒットは無視
		return                                 # ここで終わり（next_phaseに行かない）
	current_hp = max(current_hp - amount, 0)
	update_hp_bar()
	if current_hp == 0:
		phase_timer.stop()
		stop_all_attacks()
		next_phase()

func be_invincible(time: float) -> void:
	invincible = true
	invincible_timer.wait_time = time  # タイマーの待ち時間をセット
	invincible_timer.start()  # タイマー開始
func _on_invincible_timer_timeout() -> void:
	invincible = false  # 無敵解除
	print("無敵終了！")
	
func move_to(target_pos: Vector2) -> void:
	var tween = create_tween()
	tween.tween_property(self, "position", target_pos, 1.0)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	await tween.finished

func next_phase(src: String = "unknown") -> void:
	# ★道中では絶対動かさない
	if not boss_battle_gate:
		print("[PHASE] gate=OFF, ignore next_phase from:", src)
		return

	# ★多重呼びを捨てる
	if is_transitioning:
		print("[PHASE] already transitioning, drop:", src)
		return
	is_transitioning = true

	# まず現在の攻撃を完全停止＆無敵に（先に止めることで後続の事故を防ぐ）
	stop_all_attacks()                           # タイマー/Tween/一時ノード/弾消し
	stop_normal_attack_2()
	stop_special_attack_2()
	be_invincible(3.0)                           # 切替演出の無敵
	Global.add_time_bonus_score(time_remaining)  # ボーナス
	Global.clear_bullets()                       # 画面の弾を掃除

	# ★ここで“先に”次フェーズを確定し、HP/UIを即座に更新（0のままを防ぐ）
	var next_id: int = current_phase + 1
	if next_id >= phases.size():
		is_transitioning = false
		die()                                     # 最終フェーズの処理
		return

	current_phase = next_id                      # フェーズ番号を進める
	current_hp = int(phases[current_phase]["hp"])# ★HPを先にリセット！
	update_hp_bar()                              # HPバー更新（ここで0から回復して見える）
	update_timelimit_bar(current_phase)          # 制限時間バー更新など

	# 以降は“非ブロッキング”で移動→開始へつなぐ（await禁止）
	var target := Vector2(634, 200)
	if has_method("_clamp_to_arena"):            # 画面枠があれば安全化
		target = _clamp_to_arena(target)


	# Tweenシーケンスで「ちょい待ち → 移動 → 開始」を連結
	var tw := create_tween()
	tw.tween_interval(1.0)                       # 以前の 1.0秒待ちを置き換え
	tw.tween_property(self, "global_position", target, 0.6)
	tw.finished.connect(func ():
		# 途中でゲートが閉じた/撃破された等なら抜ける
		if not boss_battle_gate or not is_inside_tree():
			is_transitioning = false
			return
		# 切替直後のお化粧（任意）
		be_invincible(4.0)
		is_transitioning = false                 # 切替完了
		
		start_phase(current_phase)               # ★ここで通常攻撃２などを開始
	)


func die():
	Global.clear_bullets()
	await get_tree().get_current_scene().exit_spell()
	emit_signal("boss_defeated")
	Global.shake_screen(10.0, 0.5)  # 強さ8、0.3秒間
	Global.add_score(10000)
	Global.play_boss_dead_effect(Vector2(640, 200))  # 画面中央あたり
	queue_free()
