extends SceneTree

func _initialize() -> void:
	call_deferred("check_flow")

func check_flow() -> void:
	var game_state := root.get_node("GameState")
	game_state.set("hasKey", false)
	var phase := load("res://phases/phase_a/phase_a.tscn").instantiate() as Node2D
	root.add_child(phase)
	for frame in range(4):
		await physics_frame

	var door_a := phase.get_node("RoomA/DoorA") as Area2D
	var door_b := phase.get_node("RoomA/DoorB") as Area2D
	var door_c := phase.get_node("RoomA/DoorC") as Area2D
	var player := phase.get_node("RoomA/Player") as CharacterBody2D
	if door_a.get("state") != 2 or door_b.get("state") != 1 or door_c.get("state") != 1:
		fail("Estados iniciais das portas incorretos.")
		return
	if door_b.call("get_destination_door") != phase.get_node("RoomB/Door") or door_c.call("get_destination_door") != phase.get_node("RoomC/Door"):
		fail("Destinos das portas incorretos.")
		return

	door_a.call("_on_body_entered", player)
	if door_a.get("state") != 2:
		fail("Porta trancada abriu sem chave.")
		return
	door_a.call("_on_body_exited", player)
	door_a.set_physics_process(false)

	var enemies: Array[CharacterBody2D] = []
	for child in phase.get_node("RoomA").get_children():
		if child is CharacterBody2D and child.has_method("receive_sword_hit"):
			enemies.append(child)
	if enemies.size() != 2:
		fail("Sala A deve ter dois inimigos.")
		return
	enemies[0].call("receive_sword_hit")
	await create_timer(0.5).timeout
	if door_b.get("state") != 1:
		fail("DoorB abriu antes da última derrota.")
		return
	enemies[1].call("receive_sword_hit")
	await create_timer(0.5).timeout
	if door_b.get("state") != 0 or door_c.get("state") != 1:
		fail("A última derrota não abriu somente DoorB.")
		return

	var camera := phase.get_node("Camera2D") as Camera2D
	var resting_offset := camera.offset
	var position_before_shake := player.global_position
	player.call("move", Vector2.RIGHT)
	var player_sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	phase.get_node("RoomB/Objects/LaserPuzzle").call("_finish_success")
	var frame_before_shake := player_sprite.frame
	if door_c.get("state") != 0:
		fail("O puzzle não abriu DoorC.")
		return
	if not player.get("event_frozen"):
		fail("O player não ficou imóvel durante a animação do puzzle.")
		return
	var saw_shake := false
	for frame in range(12):
		await process_frame
		if camera.offset != resting_offset:
			saw_shake = true
	await create_timer(0.35).timeout
	if player.global_position.distance_to(position_before_shake) > 0.01 or player_sprite.frame != frame_before_shake or not saw_shake:
		fail("O movimento do player ou o tremor da câmera falhou durante a animação.")
		return
	await create_timer(0.85).timeout
	if player.get("event_frozen") or camera.offset != resting_offset:
		fail("O player ou a câmera não voltaram ao normal após a animação.")
		return
	if player.global_position.distance_to(position_before_shake + Vector2.RIGHT * 16.0) > 0.01:
		fail("O passo pausado não terminou após a animação.")
		return

	var key := phase.get_node("RoomC/Key") as Area2D
	player.global_position = key.global_position
	for frame in range(3):
		await physics_frame
	await process_frame
	if not game_state.get("hasKey") or is_instance_valid(key):
		fail("O player não coletou a chave ao tocá-la.")
		return

	player.global_position = door_a.global_position + Vector2(0, 64)
	await physics_frame
	player.call("move", Vector2.UP)
	await create_timer(0.3).timeout
	if door_a.get("state") != 0 or game_state.get("hasKey"):
		fail("A porta não abriu ou não consumiu a chave.")
		return

	var reusable_door := load("res://objects/Door.tscn").instantiate() as Area2D
	reusable_door.set("state", 2)
	root.add_child(reusable_door)
	reusable_door.call("_on_unlock_area_body_entered", player)
	if reusable_door.get("state") != 2:
		fail("Outra porta trancada abriu sem uma nova chave.")
		return
	game_state.set("hasKey", true)
	reusable_door.call("_on_unlock_area_body_entered", player)
	if reusable_door.get("state") != 0 or game_state.get("hasKey"):
		fail("O destrancamento não foi reutilizado pela cena base da porta.")
		return

	game_state.set("hasKey", true)
	game_state.call("restart_game")
	if game_state.get("hasKey"):
		fail("A chave permaneceu no inventário após reiniciar o jogo.")
		return

	print("OK: fluxo da fase 01, puzzle, chave e porta trancada.")
	quit()

func fail(message: String) -> void:
	push_error(message)
	quit(1)
