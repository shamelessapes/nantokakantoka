extends Control  # 画面の親（Control）

var is_option_window_open := false  # 今回は未使用。残しておいてもOK

# === 画像表示（HowTo画像）設定 ===
@export var img_button: Texture2D        # Button 用に表示したい画像
@export var img_button2: Texture2D       # Button2 用に表示したい画像
@export var img_button3: Texture2D       # Button3 用に表示したい画像

@onready var howto: TextureRect = $howtoplay_img  # 画像を出す先のTextureRect
var _img_tween: Tween = null                      # フェード用Tweenを保持
var _current_tex: Texture2D = null                # 現在表示中のテクスチャを覚える


# === アニメ共通設定（インスペクタから調整可能） ===
@export var slide_distance: float = 100.0          # 画面外へ飛ばす余白（左へどれだけ外すか）
@export var base_delay: float = 0.08               # 並び順ごとのズラし時間（秒）
@export var slide_time: float = 0.8                # スライドにかける時間（秒）
@export var fade_time: float = 0.25                # フェードにかける時間（秒）
@export var trans_type := Tween.TRANS_CUBIC        # 動きのカーブ種
@export var ease_type := Tween.EASE_OUT            # 終わりをゆっくりに

# === 左から入って左へ退場するノード一覧（順番に出る） ===
@onready var left_nodes: Array[Control] = [
	$Button,     # 1つ目のボタン
	$Button2,    # 2つ目のボタン
	$Button3,    # 3つ目のボタン
	$exit        # 4つ目：Exit
]

# === 元の座標を保存（キー=Node、値=Vector2） ===
var _orig_pos: Dictionary = {}  # { node: Vector2(...) }

func _ready() -> void:
	Global.fade_in(Color.BLACK, 0.4)             # 画面全体のフェードイン演出
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN) # マウスカーソルを隠す（必要なら）
	$Button.grab_focus()                            # 最初にフォーカス（↑↓で選べるように）

	$exit.pressed.connect(_on_exit_pressed)       # Exitが押されたら退場→遷移

	call_deferred("_run_intro_animation")         # レイアウト確定後に入場アニメ開始
	
	
	# --- 画像表示の初期化 ---
	howto.visible = false                               # 最初は非表示
	var c0: Color = howto.modulate                      # 現在の色を取得
	c0.a = 0.0                                          # 透明にしておく
	howto.modulate = c0                                 # 反映
	howto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # 縦横比を保つ

	# --- 3つのボタンに画像表示を割り当て ---
	$Button.pressed.connect(func(): _show_howto(img_button))    # Button クリックで画像1
	$Button2.pressed.connect(func(): _show_howto(img_button2))  # Button2 クリックで画像2
	$Button3.pressed.connect(func(): _show_howto(img_button3))  # Button3 クリックで画像3

# 画像をフェードイン表示する（同じ画像が来たらトグルで閉じる）
func _show_howto(tex: Texture2D) -> void:
	# すでに同じ画像が表示中なら、押下で閉じる挙動にする（任意）
	if _current_tex == tex and howto.visible:
		_hide_howto()                                    # 非表示へ
		return                                           # 処理終了

	# フェード中だったTweenがあれば止める
	if _img_tween and _img_tween.is_valid():
		_img_tween.kill()                                # 前のアニメを打ち切り

	# 新しい画像を差し込む
	howto.texture = tex                                  # TextureRectに画像セット
	_current_tex = tex                                   # 現在の画像として記録
	howto.visible = true                                 # ノードを表示状態に

	# 透明から1.0へフェード
	var c: Color = howto.modulate                        # 現在の色を取得
	c.a = 0.0                                            # 透明スタート
	howto.modulate = c                                   # 反映
	_img_tween = create_tween()                          # 新しいTween作成
	_img_tween.set_trans(Tween.TRANS_CUBIC)              # カーブ設定（好みでOK）
	_img_tween.set_ease(Tween.EASE_OUT)                  # 終わりゆっくり
	_img_tween.tween_property(howto, "modulate:a", 1.0, 0.2)  # 0→1を0.2秒で

# 画像をフェードアウトで消す
func _hide_howto() -> void:
	# フェード中だったTweenがあれば止める
	if _img_tween and _img_tween.is_valid():
		_img_tween.kill()                                # 前のアニメを打ち切り

	# 1→0へフェードしてから非表示に
	_img_tween = create_tween()                          # 新しいTween作成
	_img_tween.set_trans(Tween.TRANS_CUBIC)              # カーブ設定
	_img_tween.set_ease(Tween.EASE_OUT)                  # 終わりゆっくり
	_img_tween.tween_property(howto, "modulate:a", 0.0, 0.18)  # 1→0を0.18秒で
	_img_tween.finished.connect(func():                  # フェード完了時に……
		howto.visible = false                             # ノードを隠す
		_current_tex = null                               # 現在画像をクリア
	)


func _run_intro_animation() -> void:
	# まず全ノードの元位置を覚え、左の画面外＆透明からスタート
	for n in left_nodes:                           # リストの全ノードを回す
		if not is_instance_valid(n):               # 念のため存在チェック
			continue                               # 無ければ飛ばす
		_orig_pos[n] = n.position                  # 元の座標を保存
		n.position = Vector2(-slide_distance - n.size.x, n.position.y)  # 左外へ置く
		var c: Color = n.modulate                  # 色（アルファ含む）を取得
		c.a = 0.0                                  # 透明にする
		n.modulate = c                             # 反映

	# 左→順番にスライドイン＋フェードイン
	var idx: int = 0                               # 並び順カウンタ
	for n in left_nodes:                           # 1つずつ処理
		if not is_instance_valid(n):               # 念のため
			continue
		var delay_sec: float = idx * base_delay    # 要素ごとのディレイ時間
		_play_slide_and_fade_in(n, _orig_pos[n], delay_sec)  # アニメをかける
		idx += 1                                   # 次の要素へ

func _play_slide_and_fade_in(node: Control, to_pos: Vector2, delay_sec: float) -> void:
	var t := create_tween()                        # 位置用Tweenを作る
	t.set_trans(trans_type).set_ease(ease_type)    # 動きのカーブ設定
	t.tween_interval(delay_sec)                    # 最初に待機（並びズラし用）
	t.tween_property(node, "position", to_pos, slide_time)  # 左外→元位置へスライド
	var t2 := create_tween()                       # フェード用Tweenを別に作る（並列）
	t2.set_trans(trans_type).set_ease(ease_type)   # 同じカーブにしておく
	t2.tween_interval(delay_sec)                   # 同じだけ待つ
	t2.tween_property(node, "modulate:a", 1.0, fade_time)   # 透明→不透明へ

# ===== 退場（左へスライドアウト＋フェードアウト） =====

func _run_outro_animation() -> void:
	# 後ろの要素から出ていくと流れが綺麗（逆順で退場）
	var max_delay: float = 0.0                     # 最後に全体待機するための最大ディレイを控える
	for i in range(left_nodes.size()):             # 0..(要素数-1)
		var n: Control = left_nodes[left_nodes.size() - 1 - i]  # 逆順に取り出す
		if not is_instance_valid(n):               # 念のため
			continue
		var delay_sec: float = i * base_delay      # 1つずつ退場をずらす
		_play_slide_and_fade_out_left(n, delay_sec)            # 左外へ退散
		max_delay = max(max_delay, delay_sec)      # 最大値を更新

	# 全アニメ完了まで待つ（最大ディレイ＋スライド/フェードのうち長い方＋少し余裕）
	var total_time: float = max_delay + max(slide_time, fade_time) + 0.02
	await get_tree().create_timer(total_time).timeout  # タイマーで待機

func _play_slide_and_fade_out_left(node: Control, delay_sec: float) -> void:
	var target_x: float = -slide_distance - node.size.x    # 左の画面外X座標
	var t := create_tween()                        # 位置用Tween
	t.set_trans(trans_type).set_ease(ease_type)    # カーブ設定
	t.tween_interval(delay_sec)                    # 待機で順番をずらす
	t.tween_property(node, "position:x", target_x, slide_time)  # 左へ移動
	var t2 := create_tween()                       # フェード用Tween
	t2.set_trans(trans_type).set_ease(ease_type)   # カーブ設定
	t2.tween_interval(delay_sec)                   # 同期待機
	t2.tween_property(node, "modulate:a", 0.0, fade_time)       # 不透明→透明へ

# ===== Exitボタン押下：退場してからシーン遷移 =====

func _on_exit_pressed() -> void:
	await _run_outro_animation()                   # 退場アニメが終わるまで待つ
	await Global.change_scene_with_fade("res://tscn/mikotsuka_title.tscn", Color.BLACK)  # 黒フェードで遷移
