extends Control  # タイトル画面の親

var is_option_window_open := false  # オプションWindowが開いているか

# === アニメ共通設定 ===
@export var slide_distance: float = 100.0          # 画面外へ飛ばす余白
@export var base_delay: float = 0.08               # 並び順ごとの遅延
@export var slide_time: float = 0.8               # スライド時間
@export var fade_time: float = 0.25                # フェード時間
@export var trans_type := Tween.TRANS_CUBIC        # トランジション種類
@export var ease_type := Tween.EASE_OUT            # イーズ種類（終わりゆっくり）

# === 左から入場・左へ退場するノード ===
@onready var left_nodes: Array[Control] = [
	$title_logo,
	$start,
	$howtoplay,
	$material,
	$option,
	$exit
]

# === 右から入場・右へ退場するノード ===
@onready var right_nodes: Array[Control] = [
	$title_img
]

# === 元の座標保存用 ===
var _orig_pos := {}  # { node: Vector2(original_position) }

func _ready() -> void:
	Global.fade_in(Color.BLACK, 1.0)                  # 画面全体フェードイン
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)     # マウス非表示（必要に応じて）
	$start.grab_focus()                               # 最初にフォーカス

	# --- ボタン接続 ---
	$start.pressed.connect(on_start)                  # Start
	$material.pressed.connect(on_material)            # ★Material：ここで退場アニメ実行
	$howtoplay.pressed.connect(on_howtoplay)
	$option/Window.hide()                             # Optionウィンドウ初期は非表示
	$option.pressed.connect(go_to_option)             # Option
	$option/Window.close_requested.connect(on_window_close_requested)             # ×ボタン
	$option/Window/CanvasLayer/exit_window.pressed.connect(on_window_close_requested)  # 閉じる
	$exit.pressed.connect(on_exit)                    # Exit

	# レイアウト確定後に入場アニメ開始
	call_deferred("_run_intro_animation")             # 1フレーム後に実行

func _run_intro_animation() -> void:
	# 左グループを左の画面外・透明にセット
	for n in left_nodes:
		if not is_instance_valid(n):
			continue
		_orig_pos[n] = n.position                                          # 元座標を記憶
		n.position = Vector2(-slide_distance - n.size.x, n.position.y)     # 左外へ
		var c := n.modulate
		c.a = 0.0
		n.modulate = c

	# 右グループを右の画面外・透明にセット
	for n in right_nodes:
		if not is_instance_valid(n):
			continue
		_orig_pos[n] = n.position                                          # 元座標を記憶
		n.position = Vector2(size.x + slide_distance, n.position.y)        # 右外へ
		var c := n.modulate
		c.a = 0.0
		n.modulate = c

	# 左→順番にスライドイン＋フェードイン
	var idx := 0
	for n in left_nodes:
		if not is_instance_valid(n):
			continue
		_play_slide_and_fade_in(n, _orig_pos[n], idx * base_delay)
		idx += 1

	# 右→少し遅れてスライドイン＋フェードイン
	var right_offset := left_nodes.size() * base_delay
	idx = 0
	for n in right_nodes:
		if not is_instance_valid(n):
			continue
		_play_slide_and_fade_in(n, _orig_pos[n], right_offset + idx * base_delay)
		idx += 1

func _play_slide_and_fade_in(node: Control, to_pos: Vector2, delay_sec: float) -> void:
	var t := create_tween()                                   # Tween作成
	t.set_trans(trans_type).set_ease(ease_type)               # カーブ設定
	t.tween_interval(delay_sec)                               # 指定ディレイ
	t.tween_property(node, "position", to_pos, slide_time)    # 位置を元へ（入場）
	var t2 := create_tween().set_trans(trans_type).set_ease(ease_type)  # フェード用
	t2.tween_interval(delay_sec)                              # 同期ディレイ
	t2.tween_property(node, "modulate:a", 1.0, fade_time)     # 透明→不透明

# ========= ここから退場アニメ =========

func on_material() -> void:
	# Materialボタンが押されたら退場アニメを実行
	await _run_outro_animation()                              # 退場アニメが終わるまで待つ
	Global.change_scene_with_fade("res://tscn/mikotsuka_material.tscn")
	
func on_howtoplay() -> void:
	await _run_outro_animation()
	Global.change_scene_with_fade("res://tscn/mikotsuka_howtoplay.tscn")

func _run_outro_animation() -> void:
	# 退場は「入ってきた方向へ」スライドアウト＋フェードアウト
	# 並び順は入場と対称にしたいので、少しだけ“後ろから順に”出していく
	var total_nodes: int = max(left_nodes.size(), right_nodes.size())
	var max_delay: float = 0.0                                         # ← 型を明示


	# 左グループ → 左外へ退場（後ろから順に出すと気持ちいい）
	for i in range(left_nodes.size()):
		var n: Control = left_nodes[left_nodes.size() - 1 - i]         # 逆順
		if not is_instance_valid(n):
			continue
		var delay_sec := i * base_delay                                 # 逆順でディレイ
		_play_slide_and_fade_out_left(n, delay_sec)                     # 左外へ退散
		max_delay = max(max_delay, delay_sec)

	# 右グループ → 右外へ退場（こちらも逆順で）
	for j in range(right_nodes.size()):
		var n2: Control = right_nodes[right_nodes.size() - 1 - j]      # 逆順
		if not is_instance_valid(n2):
			continue
		# 右グループは左より少し遅れて開始（好みで調整）
		var base_offset := left_nodes.size() * base_delay * 0.3         # 30%ぶん遅らせ
		var delay_sec := base_offset + j * base_delay                   # ディレイ
		_play_slide_and_fade_out_right(n2, delay_sec)                   # 右外へ退散
		max_delay = max(max_delay, delay_sec)

	# 全アニメ完了まで待つ（最大ディレイ＋スライド時間＋フェード時間のmax）
	var total_time: float = max_delay + max(slide_time, fade_time) + 0.02    # ← float型を明示
	await get_tree().create_timer(total_time).timeout


func _play_slide_and_fade_out_left(node: Control, delay_sec: float) -> void:
	# 左グループを左の画面外へスライドしながらフェードアウト
	var target_x := -slide_distance - node.size.x                       # 左外の目標x
	var t := create_tween().set_trans(trans_type).set_ease(ease_type)   # 位置Tween
	t.tween_interval(delay_sec)                                         # ディレイ
	t.tween_property(node, "position:x", target_x, slide_time)          # 左へ移動
	var t2 := create_tween().set_trans(trans_type).set_ease(ease_type)  # フェードTween
	t2.tween_interval(delay_sec)                                        # 同期ディレイ
	t2.tween_property(node, "modulate:a", 0.0, fade_time)               # 不透明→透明

func _play_slide_and_fade_out_right(node: Control, delay_sec: float) -> void:
	# 右グループを右の画面外へスライドしながらフェードアウト
	var target_x := size.x + slide_distance                              # 右外の目標x
	var t := create_tween().set_trans(trans_type).set_ease(ease_type)    # 位置Tween
	t.tween_interval(delay_sec)                                          # ディレイ
	t.tween_property(node, "position:x", target_x, slide_time)           # 右へ移動
	var t2 := create_tween().set_trans(trans_type).set_ease(ease_type)   # フェードTween
	t2.tween_interval(delay_sec)                                         # 同期ディレイ
	t2.tween_property(node, "modulate:a", 0.0, fade_time)                # 不透明→透明

# ========= 既存のハンドラ =========

func on_start() -> void:
	# Start押下：フェード付きでシーン遷移
	await Global.change_scene_with_fade("res://tscn/Intro.tscn", Color.BLACK)

func go_to_option() -> void:
	# Option押下：ウィンドウを開き、最初の項目にフォーカス
	is_option_window_open = true
	$option/Window.show()
	$option/Window/CanvasLayer/DisplayModeOption.grab_focus()

func on_window_close_requested() -> void:
	# Optionウィンドウを閉じる
	is_option_window_open = false
	$option/Window.hide()
	$option.grab_focus()

func on_exit() -> void:
	# ゲーム終了
	get_tree().quit()
