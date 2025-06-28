extends Area2D

#-----------関数の定義------------
@export var speed := 500      #デフォルトの移動速度
@export var slow_speed := 200 #shift押したときのスピード
@export var shot_scene: PackedScene # 弾のプレハブ（bullet.tscn）
@export var homing_bullet_scene: PackedScene  # ホーミング弾のプレハブ
@export var max_lives := 5
@export var current_lives := 3
@export var start_position := Vector2.ZERO  # 初期位置
@onready var shot_sound_player := $shotsound  # AudioStreamPlayerノード
@onready var sprite := $AnimatedSprite2D # 左右方向移動時の画像
@onready var collision_sprite := $collisionsprite  # 当たり判定用の画像（Spriteノード）
@onready var damagesound: AudioStream = preload("res://se/se_damage9.mp3")  # 音をファイルとしてロード
@onready var explosion_scene = preload("res://tscn/explosion.tscn")  # 爆発エフェクトをロード
@onready var shot_left = $shotL
@onready var shot_right = $shotR
@onready var hud = $HUD
@onready var damage_flash = $flash/ColorRect
var current_speed := speed     #見たまんま
var verocity := Vector2.ZERO   #速度ベクトル
var can_move := true          #壁に入ったらfalseにする
var previous_position := Vector2.ZERO  #前の位置を記録しておく
var shoot_cooldown := 0.08             # 弾を撃つ間隔（秒） 
var homingshot_cooldown := 0.2        # ホーミング弾の感覚
var shoot_timer := 0.0                # クールダウンタイマー　0以下になったら次の弾が打てる
var homingshot_timer := 0.0          # ホーミング弾のクールダウンタイマー
var invincible = false
var invincible_time = 2.0  # 無敵時間2秒
var invincible_timer = 0.0
var blink_speed = 5.0                # 点滅の速さ（大きいほどはやい）
var blink_sprite: AnimatedSprite2D
var is_blinking = false  # ← 点滅するかどうかのスイッチ
var continue_scene = preload("res://tscn/continue.tscn").instantiate()
signal life_changed(lives)
signal player_dead

func _ready() -> void:
	Global.load_current_lives(self)
	update_life_ui(current_lives)
	position = start_position  # 初期化時にセット
	$HUD.update_life_ui(current_lives) 
	damage_flash.visible = false
	add_to_group("player")


# ライフ更新の関数
func update_life_ui(lives: int):
	life_changed.connect($HUD.update_life_ui)
	blink_sprite = $AnimatedSprite2D  # 子ノードのスプライトを取得


# ----------弾を発射する関数-----------
func _process(delta):
	if Global.is_talking:
		return  # 会話中は何もしない！
	# Zキー長押しで連射
	if Input.is_action_pressed("shot"): #justがないと「押してる間」という意味になる
		shoot_timer -= delta
		if shoot_timer <= 0.0:          #残りタイマーが0以下なら
			shot()                      #shot()を呼び出す
			shoot_timer = shoot_cooldown#タイマーをリセット　0.1秒たったら次の弾を打てる
	else:
		shoot_timer = 0.0  # 離したらタイマーをリセット
		
	if Input.is_action_pressed("shot"):      # 押してる間
		homingshot_timer -= delta            
		if homingshot_timer <= 0.0:          # homingshottimerが0なら
			homingshot()                     # 弾を打つ
			homingshot_timer = homingshot_cooldown
	else:
		homingshot_timer = 0.0
			
			
	#for area in get_overlapping_areas():
	# 敵と弾に当たった場合にダメージを受ける
		#if area.is_in_group("enemy"):
			#take_damage()
		#elif area.is_in_group("bullet"):
			#take_damage()

			
	if invincible:
		invincible_timer -= delta
		if invincible_timer <= 0:
			invincible = false
		
	if is_blinking:
		blink_sprite.modulate.a = abs(sin(Time.get_ticks_msec() / 1000.0 * blink_speed))
	else:
		blink_sprite.modulate.a = 1.0  # 通常は完全に表示
	# サイン波で透明度を0〜1に変化させる

# ----------弾を発射する関数-----------
# 弾を発射する関数（2連射＋位置調整）
func shot():
	if shot_scene:  # shot_scene が正しく読み込まれているときのみ
		# プレイヤーの移動とは無関係に、発射する瞬間の位置を固定
		var shot_left = $shotL.global_position
		var shot_right = $shotR.global_position
		
		# 発射ポイント（左右）のリストを作成
		var spawn_points = [shot_left, shot_right]

		# それぞれの発射ポイントに弾をインスタンス化
		for spawn_point in spawn_points:
			var shot = shot_scene.instantiate() # 弾をインスタンス化
			get_tree().current_scene.add_child(shot)
			shot.global_position = spawn_point  # add_childの後にこれをやる
		# 効果音を再生
		shot_sound_player.play()
		
# ホーミング弾発射
func homingshot():
	if homing_bullet_scene:
		var bullet = homing_bullet_scene.instantiate()
		bullet.global_position = global_position
		get_parent().add_child(bullet)

# 移動操作
func _physics_process(delta: float) -> void:
	verocity = Vector2.ZERO
	
	if Input.is_action_pressed("ui_right"):
		verocity.x += 1
	if Input.is_action_pressed("ui_left"):
		verocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		verocity.y += 1
	if Input.is_action_pressed("ui_up"):
		verocity.y -= 1
	#shift押したら遅くなる
	if Input.is_action_pressed("slow"):  
		current_speed = slow_speed
		collision_sprite.visible = true  # 当たり判定用の画像を表示
		collision_sprite.play("collisionanime")  # 当たり判定のアニメーションを再生
	else:
		current_speed = speed  #shift離すと元に戻る
		collision_sprite.visible = false  # 当たり判定用の画像を非表示
		collision_sprite.stop()  # アニメーションを停止

# アニメーション切り替え
	if verocity.x < 0:  # 左に動いている場合
		sprite.play("left")
	elif verocity.x > 0:  # 右に動いている場合
		sprite.play("right")
	else:  # どちらにも動いていない場合
		sprite.play("default")

	#壁に当たると止まる処理の定義
	if not can_move : #もしcan_moveでないなら
		position = previous_position  #前の位置に戻す（押し返す）
		return                 #止まる

	#斜め移動の動きを滑らかにする処置
	if verocity != Vector2.ZERO:  #もしプレイヤーがどこかの方向に入力していて、移動しようとしているなら
		verocity = verocity.normalized()  #ベクトルの長さを1にして、方向だけを保持する(ノーマライズドする)

	previous_position = position  #移動前の位置を記録
	position += verocity * current_speed * delta  
	#位置（position）を現在の方向 × 速度 × 経過時間（delta）で更新する（PCの性能で位置が変わっちゃうから）

# wallに入ったときに呼ばれる（コードで接続）
func _on_area_entered(area: Area2D) -> void:
	print("Entered: ", area.name)  # テスト用
	if area.is_in_group("wall"):
		can_move = false  #壁に入ったら移動を一時停止
# wallから出たときに呼ばれる（コードで接続）
func _on_area_exited(area: Area2D) -> void:
	print("Exited: ", area.name)  # テスト用
	if area.is_in_group("wall"):
		can_move = true  #壁から出たら移動再開

# ----------ダメージ処理----------
func take_damage():
	if invincible or current_lives <= 0:
		return
	invincible = true               # 無敵オン
	invincible_timer = invincible_time
	current_lives -= 1  # ライフを減らす
	Global.save_current_lives(current_lives)
	emit_signal("life_changed", current_lives)
	explode()
	flash_screen()
	player_damaged()
	Global.apply_hitstop()
	await hit_stop()                # 止める
	position = start_position       # 初期位置へ
	start_blink() # 点滅
	
	if current_lives <= 0:
		die()
		
func start_blink(duration: float = 2.0):  # 二秒点滅
	is_blinking = true
	await get_tree().create_timer(duration).timeout
	is_blinking = false

func hit_stop(duration: float = 0.023) -> void:  # ここで停止時間調整
	Engine.time_scale = 0.01
	await get_tree().create_timer(duration, true).timeout
	Engine.time_scale = 1.0
	print("時間再開！")
	
func player_damaged() -> void: # 効果音処理
	var new_sound = AudioStreamPlayer2D.new()
	new_sound.stream = damagesound
	new_sound.volume_db = 0
	new_sound.position = position  # global_position は使わない (Godot 4.2以降では position でOK)
	get_tree().current_scene.add_child(new_sound)
	new_sound.play()

	new_sound.finished.connect(func(): new_sound.queue_free())

func explode() -> void: #爆発処理
	var explosion = explosion_scene.instantiate()
	if get_parent():
		get_parent().add_child(explosion)
	else:
		get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position

	await get_tree().create_timer(0.05).timeout

func flash_screen():
	damage_flash.visible = true      # 点滅開始で見えるようにする
	damage_flash.color.a = 0.8       # 透明度調整
	var tween = create_tween()
	tween.tween_property(damage_flash, "color:a", 0.0, 0.08).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	tween.connect("finished", Callable(self, "_on_flash_finished"))
	
func _on_flash_finished():
	damage_flash.visible = false     # 点滅終わったら見えなくする
	
func die():
	emit_signal("player_dead")
	hide()
	get_tree().paused = true  # ゲームを一時停止（UIは Process Always なら動く）

	var continue_scene = preload("res://tscn/continue.tscn").instantiate()
	continue_scene.process_mode = Node.PROCESS_MODE_ALWAYS  # 念のため
	get_tree().get_root().add_child(continue_scene)
	continue_scene.show()  # ← これがないと表示されない！

	print("🧪 continue_scene を add_child したよ")
	print("pause mode:", continue_scene.process_mode)
	print("visible:", continue_scene.visible)
