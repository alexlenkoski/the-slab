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
	_check(game.squad.size() == 3, "prototype expedition should begin with three squad members")
	_check(game.squad[0].role == "NEEDLE", "first squad member was not the needle guard")
	_check(game.squad[1].role == "ACID_SPITTER", "second squad member was not the Acid Spitter")
	_check(game.squad[2].role == "TINY_BROOD_MOTHER", "third squad member was not the Tiny Brood Mother")
	_check(game.squad[2].fresh_flies == 6 and game.fresh_fly_swarm.size() == 3, "Tiny Brood Mother did not begin with three of nine flies in her swarm")
	_check(game.fresh_fly_texture != null, "Fresh Fly artwork did not load")

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

	var brood_mother: Dictionary = game.squad[2]
	game.fresh_flies.clear()
	game.fresh_fly_swarm.clear()
	brood_mother.fresh_flies = 9
	brood_mother.fresh_fly_launch_cooldown = 0.0
	for fly_index in 3:
		game._add_fresh_fly_to_swarm(brood_mother)
	var initial_swarm_angle: float = game.fresh_fly_swarm_angle
	game._update_fresh_flies(0.1, [])
	_check(game.fresh_fly_swarm_angle > initial_swarm_angle, "Fresh Fly swarm did not rotate clockwise")
	_check(game.fresh_fly_swarm[0].pos != game.fresh_fly_swarm[1].pos, "Fresh Flies did not hold a spread triangular formation")
	game.target.health = 100.0
	game.target.captured = false
	game.order = game.Order.ATTACK
	game._update_squad(0.1)
	_check(game.fresh_flies.is_empty(), "an immature swarm fly launched before five seconds")
	game._update_fresh_flies(4.9, [game.target, game.scout])
	var oldest_fly_id: int = game.fresh_fly_swarm[0].id
	game._update_squad(0.0)
	_check(game.fresh_flies.size() == 1 and game.fresh_fly_swarm.size() == 2, "Attack did not launch exactly one mature swarm fly")
	_check(game.fresh_flies[0].id == oldest_fly_id, "Fresh Flies did not launch in swarm arrival order")
	game._update_squad(4.9)
	_check(game.fresh_flies.size() == 1, "a second fly launched before the five-second attack interval")
	game._update_squad(0.11)
	_check(game.fresh_flies.size() == 2, "the next eligible fly did not launch after five seconds")

	game.fresh_flies.clear()
	game.fresh_fly_swarm.clear()
	brood_mother.fresh_flies = 9
	for fly_index in 3:
		game._add_fresh_fly_to_swarm(brood_mother)
	for fly in game.fresh_fly_swarm:
		fly.swarm_time = 5.0
	game._launch_swarm_fly(brood_mother, 0, game.target)
	game._update_fresh_flies(2.9, [])
	_check(game.fresh_fly_swarm.size() == 2, "a replacement joined the swarm before three seconds")
	game._update_fresh_flies(0.11, [])
	_check(game.fresh_fly_swarm.size() == 3 and brood_mother.fresh_flies == 5, "a reserve fly did not join the swarm after three seconds")
	_check(game.fresh_fly_swarm[2].swarm_time < 0.2, "a replacement fly did not join as immature")

	game.target.health = 50.0
	game.scout.health = 40.0
	game.target.pos = Vector2(700, game.GROUND_Y)
	game.scout.pos = Vector2(740, game.GROUND_Y)
	game._explode_fresh_fly(game.target.pos + Vector2(0, -32), [game.target, game.scout])
	_check(game.target.health == 35.0, "Fresh Fly explosion crossed the target's capture threshold")
	_check(game.scout.health == 22.0, "Fresh Fly explosion did not damage every enemy in its area")

	game.fresh_flies.clear()
	game.fresh_fly_swarm.clear()
	brood_mother.fresh_flies = 8
	game.fresh_fly_replacement_cooldown = 3.0
	game.fresh_flies.append({"id": 20, "pos": brood_mother.pos + Vector2(0, -48), "target": game.target, "returning": false, "facing": 1.0})
	game._update_fresh_flies(0.01, [game.target, game.scout])
	_check(game.fresh_flies.is_empty() and game.fresh_fly_swarm.size() == 1, "fly did not return to the swarm at capture threshold")
	_check(game.fresh_fly_swarm[0].swarm_time == 0.0, "a returning fly did not restart its five-second swarm time")

	game.target.health = 100.0
	game.fresh_flies.clear()
	game.fresh_fly_swarm.clear()
	brood_mother.fresh_flies = 9
	for fly_index in 3:
		game._add_fresh_fly_to_swarm(brood_mother)
	brood_mother.health = 55.0
	game._damage_squad_member(brood_mother, 5.0, game.target)
	_check(game.fresh_flies.size() == 3 and game.fresh_fly_swarm.is_empty(), "attacking the Tiny Brood Mother did not launch her whole swarm")

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
