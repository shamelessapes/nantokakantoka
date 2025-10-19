extends Area2D #tekidan_5                                           # 弾（Area2D）

@export var speed: float = 260                                      # 初速（速いならここを下げる）
@export var kintama := false                                        # 複製フラグ
var speed_factor: float = 1.0                                       # 速度倍率（Tweenで 1.0→0→1.0）
var direction: Vector2 = Vector2.RIGHT                              # 進行方向（正規化前でもOK）
var velocity: Vector2 = Vector2.ZERO                                # 実速度（direction×speed を毎フレーム更新）

var spin_dir := 1                                                   # 渦巻き方向（+1 or -1）
var spin_speed := 1.0                                               # 渦の回転速度（角速度）
var spiral_enabled := true                                          # 渦巻きON/OFF
var outward_weight := 0.1                                           # 外向きと回転方向のブレンド比率（0〜1）
var accel_per_sec: float = 0.0                                      # 直線加速が必要なとき用（未使用なら0）

func set_velocity(v: Vector2) -> void:                              # 外部がベクトルで指定する入口
	direction = v.normalized()                                       # 向きを保持
	velocity  = direction * speed                                    # 実速度に反映

func setup(dir: Vector2, spd: float, accel: float = 0.0) -> void:   # 外部初期化の共通入口
	direction = dir.normalized()                                     # 向きを正規化
	speed = spd                                                      # 速度を設定
	accel_per_sec = accel                                           # 直線加速度を設定（使わなければ0）
	velocity = direction * speed                                     # 実速度に反映
	rotation = direction.angle()                                     # 見た目の向き（必要なら）

func _ready() -> void:
	add_to_group("bullet")                                           # 弾グループ
	velocity = direction.normalized() * speed                        # 念のため初期速度を確定

	# --- kintamaモード：複製して左右に分かれる（無限増殖防止あり） ---
	if kintama:
		var twin := duplicate() as Area2D                            # 自分を複製
		twin.position.x += 16                                        # 右にずらす
		twin.kintama = false                                         # 複製側は複製しない
		get_parent().add_child(twin)                                 # 追加
		position.x -= 16                                             # 元の自分は左にずらす

	# 画面外消去は VisibilityNotifier2D 推奨（なければ暫定チェック）
	if position.y >= 1080 and (position.x <= 300 or position.x >= 950):
		queue_free()                                                 # 画面外で破棄（暫定）

func _process(delta: float) -> void:
	# ※ここでは「向きの更新だけ」を行う。位置は動かさない！
	if spiral_enabled:
		var outward := direction.normalized()                        # 現在の外向きベクトル
		var rotated := outward.rotated(spin_dir * spin_speed * delta)# 少し回した向き
		direction = outward.lerp(rotated, outward_weight).normalized()# 外向き寄りにブレンド
	# 直線加速が必要な場合（使わなければaccel_per_sec=0のままでOK）
	if accel_per_sec != 0.0:
		speed = max(0.0, speed + accel_per_sec * delta)              # 速度を更新（負にならないように）
	# 毎フレーム、実速度ベクトルを更新（移動は physics でまとめて行う）
	velocity = direction * speed                                     # 実速度を最新に

func _physics_process(delta: float) -> void:
	# ★移動はここだけ★（Tweenの speed_factor が必ず効く）
	position += velocity * speed_factor * delta                      # 減速・加速込みで移動

func decel_then_accel(decel_time: float, accel_time: float, min_factor: float = 0.02) -> void:
	# 発射直後：0.2秒でほぼ停止 → 0.3秒で元速に戻す（既定値）
	var tw := create_tween()
	# 減速（SINE OUT）
	tw.tween_property(self, "speed_factor", min_factor, decel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# 加速復帰（SINE IN）
	tw.tween_property(self, "speed_factor", 1.0, accel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):                                   # プレイヤーに当たったら
		area.take_damage()                                           # ダメージ
		queue_free()                                                 # 自分は消す
