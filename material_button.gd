extends TextureButton  # タイトルのボタン用スクリプト

@export var hover_scale: float = 1.08     # ホバー/フォーカス時の拡大倍率
@export var tween_time: float = 0.08      # 拡大・縮小の時間
@export var trans: Tween.TransitionType = Tween.TRANS_QUAD  # アニメ曲線
@export var ease: Tween.EaseType = Tween.EASE_OUT           # アニメの減速具合

#@onready var fx: TextureRect = $Fx        # 桜のオーバーレイ用（子ノード）
var _tween: Tween = null                  # 進行中Tween

func _ready() -> void:
	# キーボード操作でも反応できるように
	focus_mode = Control.FOCUS_ALL                             # フォーカス受け取りON
	# 中心から拡大させる
	pivot_offset = size * 0.5                                  # 拡大の基準を中央に
	scale = Vector2.ONE                                        # 等倍から開始
	# オーバーレイは最初は消しておく
	#fx.visible = false                                         # 桜は通常時非表示
	# シグナル接続（エディタ接続でもOK）
	mouse_entered.connect(_on_enter)                           # マウスが乗った
	mouse_exited.connect(_on_exit)                             # マウスが離れた
	focus_entered.connect(_on_enter)                           # キーボードで選ばれた
	focus_exited.connect(_on_exit)                             # フォーカスが外れた

func _on_enter() -> void:
	#fx.visible = true                                          # 桜を表示
	_play_scale_to(hover_scale)                                # ふわっと拡大

func _on_exit() -> void:
	#fx.visible = false                                         # 桜を非表示
	_play_scale_to(1.0)                                        # 等倍に戻す

func _play_scale_to(target: float) -> void:
	# 動作中のTweenがあれば止める（カクつき防止）
	if _tween and _tween.is_valid():
		_tween.kill()
	# 新しいTweenでscaleをアニメ
	_tween = create_tween().set_trans(trans).set_ease(ease)
	_tween.tween_property(self, "scale", Vector2(target, target), tween_time)
