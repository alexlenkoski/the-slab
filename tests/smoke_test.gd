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
	_check(InputMap.has_action("spit"), "spit input was not registered")
	_check(game.squad.size() == 2, "prototype expedition should begin with two squad members")
	_check(game.squad[0].role == "NEEDLE", "first squad member was not the needle guard")
	_check(game.squad[1].role == "ACID_SPITTER", "second squad member was not the Acid Spitter")

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

	game.player.pos = Vector2(500, game.GROUND_Y - 80.0)
	game.player.vel = Vector2(100.0, -50.0)
	game._start_punch()
	_check(game.attack_cooldown == 0.5, "punch did not apply its prototype cooldown")
	_check(game.player.vel.x == 0.0 and game.player.vel.y >= 480.0, "air punch did not stop forward movement and force a fall")

	game.target.health = 100.0
	game.scout.health = 48.0
	game.scout.active = true
	game.target.pos = Vector2(700, game.GROUND_Y)
	game.scout.pos = Vector2(710, game.GROUND_Y)
	game.squad[0].pos = Vector2(650, game.GROUND_Y)
	game.squad[0].facing = 1.0
	game._needle_guard_attack(game.squad[0])
	_check(game.target.health == 86.0 and game.scout.health == 34.0, "needle swing did not cleave overlapping enemies")
	_check(game.target.pos.x == 700.0 and game.scout.pos.x == 710.0, "needle swing incorrectly applied knockback")

	var acid_spitter: Dictionary = game.squad[1]
	acid_spitter.pos = Vector2(400, game.GROUND_Y)
	acid_spitter.attack_cooldown = 0.0
	game.target.pos = Vector2(500, game.GROUND_Y)
	game.order = game.Order.ATTACK
	game._update_squad(0.1)
	_check(acid_spitter.pos.x < 400.0, "Acid Spitter did not fall back from a close target")

	game.acid_projectiles.clear()
	acid_spitter.pos = Vector2(400, game.GROUND_Y)
	acid_spitter.hold_x = 400.0
	acid_spitter.attack_cooldown = 0.0
	game.target.pos = Vector2(650, game.GROUND_Y)
	game.order = game.Order.DEFEND
	game._update_squad(0.1)
	_check(acid_spitter.pos.x == 400.0, "Acid Spitter left its fixed Defend position")
	_check(game.acid_projectiles.size() == 1, "Acid Spitter did not fire at a target in Defend range")

	game.target.health = 100.0
	game.target.acid_duration = 0.0
	game.target.acid_tick = 0.0
	for hit in 10:
		game._apply_acid_hit(game.target)
	_check(game.target.acid_duration == 8.0, "repeated acid hits did not cap duration at eight seconds")
	_check(game.target.health == 60.0, "acid impact damage did not remain weak and constant")
	game._update_acid_effects(0.25, [game.target])
	_check(game.target.health == 58.0, "acid did not apply its fixed tick damage")

	game.spit_projectiles.clear()
	game.player.pos = Vector2(500, game.GROUND_Y)
	game.player.facing = 1.0
	game._fire_spit()
	_check(game.spit_cooldown == 10.0, "spit did not apply its prototype cooldown")
	game.spit_projectiles[0].pos = game.target.pos + Vector2(0, -34)
	game._update_spit(0.01, [game.target, game.scout])
	_check(game.target.stun == 3.0, "direct spit hit did not stun for three seconds")
	_check(game.spit_projectiles.is_empty() and game.spit_puddles.is_empty(), "direct spit hit was not consumed")

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
