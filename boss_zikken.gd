extends Node2D
#boss_zikken

@onready var fade_rect = $CanvasLayer/FadeRect
@onready var skill_background = $CanvasLayer/Parallax2D4/SkillBackground

var skill_backgrounds = {
	"あめあめふれふれ": "res://image/bgkarakasa .png",
	"日照り雨": "res://image/bgkarakasa .png"
}


# --------------------各フェーズメモ--------------------
var is_hitstop = false

func _physics_process(delta: float) -> void:
	if Global.is_hitstop:
		return  # ヒットストップ中はスクロール停止
		
	#背景画像スクロール	
	$bg/Parallax2D.scroll_offset.y += 25
	$bg/Parallax2D2.scroll_offset.y += 12
	$bg/Parallax2D3.scroll_offset.y += 2
	$CanvasLayer/Parallax2D4.scroll_offset.y += 2
		
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
# ▼ スキル時背景 ▼
# ========================
func start_phase(phase_data):
	print("フェーズ開始: ", phase_data)
	if phase_data.type == "skill":
		print("スキルフェーズ判定 OK")
		var bg_path = skill_backgrounds.get(phase_data.name, "res://image/bgkarakasa .png")
		print("スキル背景を読み込み中: ", bg_path)
		await fade_out()
		print("フェードアウト終了")
		skill_background.texture = load(bg_path)
		skill_background.position = get_viewport_rect().size / 2
		skill_background.visible = true
		skill_background.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(skill_background, "modulate:a", 1.0, 0.5)
		await tween.finished
		print("スキル背景のフェードイン完了")
		await fade_in()
		print("フェードイン終了")
	else:
		print("通常フェーズ: 背景は変更しない")


		
func end_skill_phase():
	var tween = create_tween()
	tween.tween_property(skill_background, "modulate:a", 0.0, 0.5)
	await tween.finished
	skill_background.visible = false
	skill_background.texture = null  # メモリ節約にもなる



func change_background_with_fade(new_bg_path: String):
	await fade_out()
	await fade_in()

func fade_out(duration := 0.5):
	print("フェードアウト開始")
	fade_rect.visible = true
	fade_rect.color.a = 0.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished
	print("フェードアウト完了")

func fade_in(duration := 0.5):
	print("フェードイン開始")
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished
	print("フェードイン完了")
	fade_rect.visible = false




	
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
