extends Node

## サウンド再生を管理するシングルトン

const MAX_SIMULTANEOUS_SFX: int = 8

var _active_sfx_count: int = 0


func play_sfx(stream: AudioStream) -> void:
	if _active_sfx_count >= MAX_SIMULTANEOUS_SFX:
		return

	var player := AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.play()
	_active_sfx_count += 1
	player.finished.connect(func() -> void:
		_active_sfx_count -= 1
		player.queue_free()
	)


func play_bgm(stream: AudioStream) -> void:
	# TODO: BGM 再生（フェードイン/アウト対応）
	pass
