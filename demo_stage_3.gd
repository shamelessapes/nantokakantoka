extends Node2D  # ステージのルート

var is_hitstop := false  # ヒットストップ中かどうか
signal stage_cleared
@onready var fade_rect: ColorRect = $Control/FadeRect  # 画面フェード用



@onready var bg_normal_2: Parallax2D = $bg/Parallax2D       # 通常背景②
@onready var bg_normal_3: Parallax2D = $bg/Parallax2D3       # 通常背景③


# 技名→背景画像の対応（必要に応じてパスを差し替え）


func _ready():  # ステージ開始時
	var current_lives := 3  # 初期残機
	var player = get_tree().get_nodes_in_group("player")[0]  # プレイヤー取得
	player.update_life_ui(current_lives)  # 残機UI更新
	Global.register_camera($Camera2D)  # カメラをグローバル登録（画面揺れ等で使用）
	await Global.fade_in(Color.BLACK)
	$bgm.play()  # BGM再生
	await get_tree().create_timer(2.0).timeout  # 2秒待つ
	emit_signal("stage_cleared")


func _unhandled_input(event):  # 入力監視
	if event.is_action_pressed("pause"):  # ポーズボタン
		toggle_pause()  # ポーズ切替

func toggle_pause():  # ポーズのON/OFF
	if get_tree().paused:  # すでにポーズ中なら
		get_tree().paused = false  # 再開
		$PauseMenu.visible = false  # ポーズメニュー非表示
	else:  # 停止していないなら
		get_tree().paused = true  # 停止
		$PauseMenu.visible = true  # ポーズメニュー表示
		$PauseMenu/Restart.grab_focus()  # ボタンにフォーカス
		SoundManager.play_se_by_path("res://se/決定ボタンを押す49.mp3")  # SE再生

# ===============================
# ▼ フレームごとのスクロール処理
# ===============================
func _physics_process(delta: float) -> void:
	if Global.is_hitstop:
		return  # ヒットストップ中はスクロール停止

	# 背景画像をゆっくり下方向に流す
	$bg/Parallax2D.scroll_offset.y += 410 * delta
	$bg/Parallax2D3.scroll_offset.y += 230 * delta



# ========================
# ▼ フェードユーティリティ ▼
# ========================

func fade_out(dur := 0.3) -> void:  # 画面を暗くする
	var t := create_tween()  # Tween作成
	t.tween_property(fade_rect, "modulate:a", 1.0, dur)  # 不透明へ
	await t.finished  # 完了待機

func fade_in(dur := 0.3) -> void:  # 画面を明るくする
	var t := create_tween()  # Tween作成
	t.tween_property(fade_rect, "modulate:a", 0.0, dur)  # 透明へ
	await t.finished  # 完了待機
