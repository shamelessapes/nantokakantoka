extends Control  # タイトル画面の親

var is_option_window_open := false  # オプションWindowが開いているか

# === アニメ共通設定 ===
@export var slide_distance: float = 100.0          # 画面外へ飛ばす余白
@export var base_delay: float = 0.08               # 並び順ごとの遅延
@export var slide_time: float = 0.8               # スライド時間
@export var fade_time: float = 0.25                # フェード時間
@export var trans_type := Tween.TRANS_CUBIC        # トランジション種類
@export var ease_type := Tween.EASE_OUT            # イーズ種類（終わりゆっくり）

func _ready() -> void:
	Global.fade_in(Color.BLACK, 0.4)                  # 画面全体フェードイン
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)     # マウス非表示（必要に応じて）
	$exit.grab_focus()                               # 最初にフォーカス


	$exit.pressed.connect(on_exit)                    # Exit


func on_exit() -> void:
	# ゲーム終了
	Global.change_scene_with_fade("res://tscn/mikotsuka_title.tscn")
