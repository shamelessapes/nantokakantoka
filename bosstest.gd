extends Node2D

# --------------------各フェーズメモ--------------------
var phases = [
	{ "type": "normal", "hp": 500, "duration": 30, "pattern": "pattern_1" },
	{ "type": "spell", "hp": 800, "duration": 30, "pattern": "skill_1", "name": "あめあめふれふれ" },
	{ "type": "normal", "hp": 500, "duration": 30, "pattern": "pattern_2" },
	{ "type": "spell", "hp": 800, "duration": 30, "pattern": "skill_2", "name": "日照り雨" },
]

var current_phase_index = 0
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
	$player.life_changed.connect($HUD.update_life_ui)
	var first_phase = phases[0]
	await get_tree().create_timer(2.0).timeout
	$karakasaobake.start_phase(first_phase)
	


func start_next_phase():
	print("=== start_next_phase called! current=", current_phase_index)
	current_phase_index += 1
	if current_phase_index >= phases.size():
		print("全フェーズ終了！")
		return

	var next_phase = phases[current_phase_index]
	print("次のフェーズ開始: ", next_phase)

	var boss = $karakasaobake
	if boss.has_method("start_phase"):
		await boss.start_phase(next_phase)
	print("=== start_next_phase 完了")

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
	# 弾消し演出
	erase_all_bullets_with_effect()


# ========================
# ▼ 弾全消去＋演出 ▼
# ========================
func erase_all_bullets_with_effect():
	var bullets = get_tree().get_nodes_in_group("bullet")
	for bullet in bullets:
		Global.bullet_erase(bullet.global_position)
		bullet.queue_free()

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
