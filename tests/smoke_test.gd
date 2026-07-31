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
	_check(game.squad.size() == 2, "prototype expedition should begin with two squad members")

	game.target.captured = true
	game.target.pos = Vector2(1000, game.GROUND_Y)
	game.player.facing = 1.0
	game.order = game.Order.FOLLOW
	for member in game.squad:
		member.pos = game.target.pos
	game._update_squad(0.1)
	_check(
		game.squad[0].pos.x > game.target.pos.x and game.squad[1].pos.x < game.target.pos.x,
		"captured target was not positioned between its two escorts"
	)
	game.squad[0].pos.x = 1075.0
	game.squad[1].pos.x = 925.0
	var limited_position: Vector2 = game._limit_prisoner_to_forward_guard(Vector2(1200, game.GROUND_Y))
	_check(limited_position.x == 1020.0, "captured target advanced beyond the forward escort")
	game.target.captured = false

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

	game._release_vey()
	_check(game.vey_escaped, "zero cell integrity did not release Vey")
	_check(game.cell_integrity == 0.0, "broken cell retained integrity")
	_check(not game.target.captured, "escaped Vey remained marked as captured")
	game._update_vey_escape(2.0)
	_check(game.phase == 3, "Vey leaving the Slab did not reach the escape outcome")
	_check(game.result.escaped, "escape outcome was not recorded")
	_check(game.result.payment == 0, "failed containment awarded contract payment")

	game.queue_free()
	if failures.is_empty():
		print("SMOKE TEST PASSED: vertical-slice invariants hold")
		quit(0)
	else:
		quit(1)
