extends Node2D

var is_hitstop := false

func _physics_process(delta: float) -> void:
	if Global.is_hitstop:
		return  # ヒットストップ中はスクロール停止！

	# 背景画像スクロール
	$bg/Parallax2D.scroll_offset.y += 25
	$bg/Parallax2D2.scroll_offset.y += 12
	$bg/Parallax2D3.scroll_offset.y += 2

func _ready():
	$player.life_changed.connect($HUD.update_life_ui)
