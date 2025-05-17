extends Node2D
# ーーーーーーーーーーーーーーーーーーーー各フェーズメモーーーーーーーーーーーーーーーーーーーーー
var phases = [
	{ "type": "normal", "hp": 500, "duration": 30, "pattern": "pattern_1" },
	{ "type": "spell", "hp": 800, "duration": 30, "pattern": "skill_1", "name": "あめあめふれふれ" },
	{ "type": "normal", "hp": 500, "duration": 30, "pattern": "pattern_2" },
	{ "type": "spell", "hp": 800, "duration": 30, "pattern": "skill_2", "name": "日照り雨" },
]

var current_phase_index := 0

# ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー

var is_hitstop := false

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
	current_phase_index += 1
	if current_phase_index >= phases.size():
		print("全フェーズ終了！")
		# ここでエンディング処理とかに行く
		return

	var next_phase = phases[current_phase_index]
	print("次のフェーズ開始: ", next_phase)

	var boss = $karakasaobake
	if boss.has_method("start_phase"):
		await boss.start_phase(next_phase)  # await を忘れずに！

# ========================
# ▼ 演出関数(cutin) ▼
# ========================
func show_spell_cutin(name: String) -> void:
	var cutin = $UI/cutin  # CanvasLayerノード
	var wazamei = $UI/ameamehurehure
	cutin.visible = true
	wazamei.visible = true
	$UI/ameamehurehure.text = name
	$UI/AnimationPlayer.play("karakasa_cutin")
	await get_tree().create_timer(2.5).timeout  
	
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
