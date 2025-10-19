extends Node2D  # ステージのルート

var is_hitstop := false  # ヒットストップ中かどうか

@onready var fade_rect: ColorRect = $Control/FadeRect  # 画面フェード用
@onready var spell_cutin: CanvasLayer = $SpellCutIn  # カットインの親
@onready var name_label: Label = $SpellCutIn/NameLabel  # 技名表示
@onready var cutin_sprite: Sprite2D = $SpellCutIn/Sprite2D  # 立ち絵
@onready var cutin_anim: AnimationPlayer = $SpellCutIn/AnimationPlayer  # カットイン用AP

#@onready var bg_normal_1: Parallax2D = $bg/Parallax2D        # 通常背景①
@onready var bg_normal_2: Parallax2D = $bg/Parallax2D       # 通常背景②
@onready var bg_normal_3: Parallax2D = $bg/Parallax2D3       # 通常背景③
@onready var bg_skill_layer: Sprite2D = $bg/SkillBackground    # 必殺技用背景レイヤ
@onready var skill_background: Sprite2D = $bg/SkillBackground  # 必殺技用の1枚絵

# 技名→背景画像の対応（必要に応じてパスを差し替え）
var SKILL_BGS := {
	"ぽんぽこ攪乱の術": "res://image/ステージ2/bg_boss2.png",  # 技Aの背景
	"でっかいきんのたま": "res://image/ステージ2/bg_boss2.png",  
	"令和たぬき合戦ぽんぽこ":"res://image/ステージ2/bg_boss2.png"
}

func _ready():  # ステージ開始時
	var current_lives := 3  # 初期残機
	var player = get_tree().get_nodes_in_group("player")[0]  # プレイヤー取得
	player.update_life_ui(current_lives)  # 残機UI更新
	Global.register_camera($Camera2D)  # カメラをグローバル登録（画面揺れ等で使用）
	await get_tree().create_timer(2.0).timeout  # 2秒待つ
	$bgm.play()  # BGM再生
	var stage_manager = get_tree().get_first_node_in_group("stage_manager")  # ステージマネージャ取得
	if stage_manager:  # 存在するなら
		stage_manager.start_stage()  # 道中スタート

	# 初期状態では必殺技レイヤを非表示にしておく
	bg_skill_layer.visible = false  # 必殺技背景非表示
	spell_cutin.visible = false  # カットイン非表示
	fade_rect.modulate.a = 0.0  # フェード透明

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
# ▼ ボスから呼ぶ公開API ▼
# ========================

func enter_spell(spell_name: String) -> void:  # 必殺技開始時に呼ぶ
	# 1) カットイン表示（SEやアニメ）
	await show_spell_cutin(spell_name)  # カットイン演出を待つ

	# 2) 背景切替（フェード→差し替え→フェード戻し）
	await fade_out(0.35)  # すっと暗転
	_set_skill_background_for(spell_name)  # 技名に応じた背景設定
	_change_background(true)  # 必殺技レイヤON / 通常OFF
	await fade_in(0.35)  # すっと明転

func exit_spell() -> void:  # 必殺技終了時に呼ぶ
	# 背景を通常へ戻す（フェード付き）
	await fade_out(0.35)  # 暗転
	_change_background(false)  # 通常ON / 必殺技OFF
	await fade_in(0.35)  # 明転

# ========================
# ▼ 背景の実体処理 ▼
# ========================

func _set_skill_background_for(spell_name: String) -> void:  # 技名で背景を決める
	var path : String = SKILL_BGS.get(spell_name, "")  # 対応するパス取得
	if path != "":  # パスがあるなら
		var tex := load(path)  # テクスチャ読み込み
		if tex:  # 読み込めたら
			skill_background.texture = tex  # 差し替え
			# 画面中央に置きたい場合は以下（必要なら調整）
			skill_background.position = get_viewport_rect().size / 2.0  # 中央

func _change_background(to_spell: bool) -> void:  # 表示レイヤを切り替える
	if to_spell:  # 必殺技へ
		#bg_normal_1.visible = false  # 通常①隠す
		bg_normal_2.visible = false  # 通常②隠す
		bg_normal_3.visible = false  # 通常③隠す
		bg_skill_layer.visible = true  # 必殺技レイヤ見せる
	else:  # 通常へ戻す
		#bg_normal_1.visible = true  # 通常①見せる
		bg_normal_2.visible = true  # 通常②見せる
		bg_normal_3.visible = true  # 通常③見せる
		bg_skill_layer.visible = false  # 必殺技レイヤ隠す

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

# ========================
# ▼ カットイン演出 ▼
# ========================

func show_spell_cutin(spell_name: String) -> void:  # 技名とカットイン表示
	name_label.text = spell_name  # ラベルに技名をセット
	spell_cutin.visible = true  # パネルを表示
	SoundManager.play_se_by_path("res://se/Onoma-Flash06-mp3/Onoma-Flash06-1(Low-Mid).mp3", +10)
	# AnimationPlayerがあれば優先して使う（名前: "spell_cutin"）
	if cutin_anim and "cutin" in cutin_anim.get_animation_list():  # アニメが存在するなら
		cutin_anim.stop()  # 念のため停止
		cutin_anim.play("cutin")  # 再生
		await cutin_anim.animation_finished  # 終了待機

	spell_cutin.visible = false  # 最後に隠す
