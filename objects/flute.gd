extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or GameState.hasFlute:
		return
		
	GameState.hasFlute = true
	print(GameState.hasFlute)
	queue_free()
