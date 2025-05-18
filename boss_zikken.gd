extends Node2D
#boss_zikken

# --------------------各フェーズメモ--------------------
var is_hitstop = false

func _physics_process(delta: float) -> void:
	if Global.is_hitstop:
		return  # ヒットストップ中はスクロール停止
		
	#背景画像スクロール	
	$bg/Parallax2D.scroll_offset.y += 25
	$bg/Parallax2D2.scroll_offset.y += 12
	$bg/Parallax2D3.scroll_offset.y += 2
	$bg/Parallax2D4.scroll_offset.y += 2
		
func _ready():
	pass
	
# ========================
# ▼ スペルカットイン演出 ▼
# ========================
func show_spell_cutin(name: String) -> void:
	var boss = $karakasaobake
	var cutin = boss.get_node("UI/cutin")
	var wazamei = boss.get_node("UI/ameamehurehure")
	cutin.visible = true
	wazamei.visible = true
	wazamei.text = name
	boss.get_node("UI/AnimationPlayer").play("karakasa_cutin")
	await get_tree().create_timer(2.5).timeout



# ========================
# ▼ 弾全消去＋演出 ▼
# ========================

# ========================
# ▼ 背景変更 ▼
# ========================
func change_background(to_spell: bool):
	if to_spell:
		$bg/Parallax2D.visible = false
		$bg/Parallax2D2.visible = false
		$bg/Parallax2D3.visible = false
		$bg/Parallax2D4.visible = true
	else:
		$bg/Parallax2D.visible = true
		$bg/Parallax2D2.visible = true
		$bg/Parallax2D3.visible = true
		$bg/Parallax2D4.visible = false
