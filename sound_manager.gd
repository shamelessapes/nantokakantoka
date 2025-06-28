extends Node2D

# 効果音キャッシュ用の辞書
var se_cache := {}

func play_se_by_path(path: String, volume_db: float = 0) -> void:
	if not se_cache.has(path):
		var stream = load(path)
		if stream:
			se_cache[path] = stream
		else:
			print("効果音ファイルが見つかりません: ", path)
			return

	var player = AudioStreamPlayer2D.new()
	add_child(player)
	player.stream = se_cache[path]
	player.volume_db = volume_db
	player.play()

	var timer = Timer.new()
	timer.wait_time = player.stream.get_length()
	timer.one_shot = true
	add_child(timer)
	timer.start()
	timer.timeout.connect(Callable(player, "queue_free"))
