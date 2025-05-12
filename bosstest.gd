extends Node2D
# ーーーーーーーーーーーーーーーーーーーー各フェーズメモーーーーーーーーーーーーーーーーーーーーー
var phases = [
	{ "type": "normal", "hp": 100, "duration": 30, "pattern": "pattern_1" },
	{ "type": "spell", "hp": 150, "duration": 30, "pattern": "skill_1", "name": "あめあめふれふれ" },
	{ "type": "normal", "hp": 120, "duration": 30, "pattern": "pattern_2" },
	{ "type": "spell", "hp": 180, "duration": 30, "pattern": "skill_2", "name": "日照り雨" },
]
# ーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーーー



func _physics_process(delta: float) -> void:
	#背景画像スクロール	
	$bg/Parallax2D.scroll_offset.y += 25
	$bg/Parallax2D2.scroll_offset.y += 12
	$bg/Parallax2D3.scroll_offset.y += 2
	
func _ready():
	$player.life_changed.connect($HUD.update_life_ui)
