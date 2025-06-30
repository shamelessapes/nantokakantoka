extends Area2D

@onready var explosion_scene = preload("res://tscn/explosion.tscn")  # 爆発エフェクトをロード
@onready var zakodead_sound: AudioStream = preload("res://se/se_damage9.mp3")  # 死亡時の音（音をファイルとしてロード）
const BULLET_SCN := preload("res://tscn/tekidan_3.tscn")
@export var exit_speed: float = 100.0                    # 発射後に下へ去っていく速度
@export var stop_y: float = 100                        # 降下を止める Y 座標（スポナー側で上書き） 
@export var descend_duration: float = 0.8                # Tweenで降りる時間

var hp := 35  # 敵の最大HP
var is_dead := false  # 死亡フラグ

@onready var zakodead_player = $AudioStreamPlayer  # AudioStreamPlayerノードを取得

enum State {DESCEND, ATTACK, EXIT}                       # シンプルなステート列挙
var _state: State = State.DESCEND                        # 現在ステートを保持

func _physics_process(delta):
	if _state == State.EXIT:
		position.y += exit_speed * delta
		if position.y > 1100:
			queue_free()

func _ready():
	$AnimatedSprite2D.play("default")
	zakodead_player.stream = zakodead_sound
	_start_descend()                                     # 降下開始

func _start_descend():
	var tween := create_tween()                            # SceneTreeTween を作成
	tween.tween_property(self, "position:y", stop_y, descend_duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.connect("finished", _on_tween_finished)        # 降下完了後に呼び出し

func _on_tween_finished():
	if _state == State.DESCEND:                             # 降下完了時
		_enter_attack_state()                            # 攻撃ステートへ
				
func _enter_attack_state() -> void:                      # 攻撃ステート突入処理
	_state = State.ATTACK                                #   ステート更新
	$AnimatedSprite2D.play("attack")                      #   発射アニメ再生
	_fire_bullet()                                       #   弾を 1 発撃つ
	await get_tree().create_timer(0.8).timeout       # 0.8秒待って次の行動へ
	_enter_exit_state()                              # 移動フェーズへ

func _fire_bullet() -> void:                             # 弾生成関数
	var b = BULLET_SCN.instantiate()                     #   弾シーン生成
	SoundManager.play_se_by_path("res://se/ジングルベル01.mp3", -5)
	b.position = position + Vector2(0, 10)  # 敵のちょっと下から出す
	b.velocity = Vector2(0, 200)              # 下方向に速度150で発射！
	get_parent().add_child(b)              # 弾をシーンに追加

func _enter_exit_state() -> void:
	_state = State.EXIT
	$AnimatedSprite2D.play("default")





		
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		area.take_damage()

func _on_shot_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_shot"):
		var damage = area.damage
		take_damage(damage)

func take_damage(damage: int) -> void:
	if is_dead:
		return  # すでに死亡処理済みなら無視

	hp -= damage
	if hp <= 0:
		is_dead = true  # 死亡フラグを立てる
		SoundManager.play_se_by_path("res://se/Balloon-Pop01-1(Dry).mp3", +10)
		Global.add_score(20)
		explode()


func explode() -> void:
	var explosion = explosion_scene.instantiate()
	if get_parent():
		get_parent().add_child(explosion)
	else:
		get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position

	await get_tree().create_timer(0.05).timeout
	queue_free()
