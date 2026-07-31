extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error("SMOKE TEST: " + message)


func _run() -> void:
	var game = load("res://scripts/game.gd").new()
	root.add_child(game)
	await process_frame

	_check(game.content.contract.target == "Vey, the Bell-Sworn", "content data did not load")
	_check(InputMap.has_action("command_restrain"), "prototype inputs were not registered")

	game.player.pos = game.target.pos - Vector2(30, 0)
	game.player.facing = 1.0
	for hit in 20:
		game._player_strike(game.target, 20.0)
	_check(game.target.health == 1.0, "contract target was not protected from lethal damage")

	game.scout.captured = true
	game.scout.active = false
	game._enter_slab()
	_check(game.phase == 2, "return transport did not enter the Slab phase")
	game._start_emergency()
	_check(game.raiders.size() == 3, "optional capture did not reduce the retaliation force")

	game.cell_integrity = 72.0
	game._finish_prototype()
	_check(game.phase == 3, "preservation did not enter the outcome phase")
	_check(game.result.payment == 225, "contract and optional-prisoner payments were not combined")
	_check(game.result.research == "Resonance baffling", "research reward was not reported")

	game.queue_free()
	if failures.is_empty():
		print("SMOKE TEST PASSED: vertical-slice invariants hold")
		quit(0)
	else:
		quit(1)
