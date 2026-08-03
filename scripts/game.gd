extends Node2D

# A dependency-free vertical slice. Character textures live in the repository;
# remaining geometry, animation, and UI are drawn in code.

const VIEW := Vector2(1280.0, 720.0)
const GROUND_Y := 590.0
const WORLD_END := 2520.0
const PLAYER_SPEED := 285.0
const JUMP_SPEED := 610.0
const GRAVITY := 1650.0
const WARDEN_TEXTURE_PATH := "res://assets/characters/warden.png"
const WARDEN_DRAW_HEIGHT := 96.0
const GUARD_TEXTURE_PATH := "res://assets/characters/guard.png"
const GUARD_DRAW_HEIGHT := 82.0
const FRESH_FLY_TEXTURE_PATH := "res://assets/characters/fresh_fly.png"
const FRESH_FLY_DRAW_SIZE := 47.5
const SQUAD_FOLLOW_FIRST_OFFSET := 70.0
const SQUAD_FOLLOW_SPACING := 115.0
const ESCORT_PRISONER_OFFSET := 150.0
const ESCORT_GUARD_OFFSET := 75.0
const ESCORT_MINIMUM_LEAD := 55.0
const VEY_ESCAPE_SPEED := 260.0
const VEY_ESCAPE_EXIT_X := 1325.0
const PUNCH_COOLDOWN := 0.5
const PUNCH_MOVEMENT_LOCK := 0.16
const PUNCH_RANGE := 105.0
const PUNCH_DAMAGE := 16.0
const SPIT_COOLDOWN := 10.0
const SPIT_SPEED := Vector2(430.0, -310.0)
const SPIT_GRAVITY := 900.0
const SPIT_PUDDLE_LIFETIME := 6.0
const SPIT_PUDDLE_RADIUS := 58.0
const DIRECT_SPIT_STUN := 3.0
const NEEDLE_DAMAGE := 7.0
const NEEDLE_RANGE := 76.0
const NEEDLE_COOLDOWN := 0.9
const ACID_IMPACT_DAMAGE := 2.0
const ACID_TICK_DAMAGE := 1.0
const ACID_TICK_INTERVAL := 0.25
const ACID_DURATION_PER_HIT := 1.0
const ACID_MAX_DURATION := 8.0
const ACID_SPIT_COOLDOWN := 1.4
const ACID_SPIT_SPEED := Vector2(340.0, -240.0)
const ACID_SPIT_GRAVITY := 720.0
const ACID_MIN_RANGE := 145.0
const ACID_PREFERRED_RANGE := 225.0
const ACID_MAX_RANGE := 275.0
const FRESH_FLY_CAPACITY := 9
const FRESH_FLY_SWARM_LIMIT := 3
const FRESH_FLY_SWARM_TIME := 5.0
const FRESH_FLY_ATTACK_INTERVAL := 5.0
const FRESH_FLY_REPLACEMENT_DELAY := 3.0
const FRESH_FLY_SWARM_CENTER := Vector2(0.0, -105.0)
const FRESH_FLY_SWARM_RADIUS := Vector2(64.0, 30.0)
const FRESH_FLY_SWARM_ROTATION_SPEED := 1.25
const FRESH_FLY_SPEED := 390.0
const FRESH_FLY_EXPLOSION_RADIUS := 82.0
const FRESH_FLY_DAMAGE := 9.0

enum Phase { BRIEFING, EXPEDITION, SLAB, OUTCOME }
enum Order { FOLLOW, HOLD, ATTACK, DEFEND, RESTRAIN, RETREAT }

var phase := Phase.BRIEFING
var content := {}
var player := {"pos": Vector2(170, GROUND_Y), "vel": Vector2.ZERO, "health": 100.0, "facing": 1.0}
var squad: Array[Dictionary] = []
var order := Order.FOLLOW
var order_names := ["FOLLOW", "HOLD", "ATTACK", "DEFEND", "RESTRAIN", "RETREAT"]
var order_flash := 0.0
var attack_cooldown := 0.0
var movement_lock := 0.0
var spit_cooldown := 0.0
var punch_flash := 0.0
var invulnerable := 0.0
var spit_projectiles: Array[Dictionary] = []
var spit_puddles: Array[Dictionary] = []
var acid_projectiles: Array[Dictionary] = []
# Flies in flight toward an enemy or returning to the swarm.
var fresh_flies: Array[Dictionary] = []
var fresh_fly_swarm: Array[Dictionary] = []
var fresh_fly_bursts: Array[Dictionary] = []
var fresh_fly_swarm_angle := 0.0
var fresh_fly_replacement_cooldown := 0.0
var next_fresh_fly_id := 0

var target := {"pos": Vector2(2050, GROUND_Y), "health": 100.0, "max_health": 100.0, "capture_threshold": 35.0, "captured": false, "stun": 0.0, "size": 2.0, "puddle_stun": 0.0, "acid_duration": 0.0, "acid_tick": 0.0}
var scout := {"pos": Vector2(1120, GROUND_Y), "health": 48.0, "capture_threshold": 1.0, "captured": false, "active": true, "stun": 0.0, "size": 1.0, "puddle_stun": 0.0, "acid_duration": 0.0, "acid_tick": 0.0}
var capture_progress := 0.0
var camp_progress := 0.0
var expedition_message := "Reach Vey alive. The squad awaits your word."

var slab_tasks := {"brood_fed": false, "cell_inspected": false}
var cell_guards := 1
var emergency_started := false
var emergency_resolved := false
var emergency_delay := 3.0
var cell_integrity := 100.0
var raiders: Array[Dictionary] = []
var vey_escaped := false
var slab_message := "The prisoner is restless. Tend the Slab before departure."
var coins := 20
var result := {}
var elapsed := 0.0
var warden_texture: Texture2D
var guard_texture: Texture2D
var fresh_fly_texture: Texture2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	if ResourceLoader.exists(WARDEN_TEXTURE_PATH):
		warden_texture = load(WARDEN_TEXTURE_PATH) as Texture2D
	if ResourceLoader.exists(GUARD_TEXTURE_PATH):
		guard_texture = load(GUARD_TEXTURE_PATH) as Texture2D
	if ResourceLoader.exists(FRESH_FLY_TEXTURE_PATH):
		fresh_fly_texture = load(FRESH_FLY_TEXTURE_PATH) as Texture2D
	var file := FileAccess.open("res://data/prototype_content.json", FileAccess.READ)
	if file:
		content = JSON.parse_string(file.get_as_text())
	_reset_squad()
	queue_redraw()


func _setup_input() -> void:
	_bind_key("move_left", KEY_A)
	_bind_key("move_left", KEY_LEFT)
	_bind_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_key("move_right", KEY_D)
	_bind_key("move_right", KEY_RIGHT)
	_bind_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_bind_key("jump", KEY_SPACE)
	_bind_button("jump", JOY_BUTTON_A)
	_bind_key("attack", KEY_J)
	_bind_button("attack", JOY_BUTTON_X)
	_bind_key("spit", KEY_K)
	_bind_button("spit", JOY_BUTTON_Y)
	_bind_key("interact", KEY_E)
	_bind_button("interact", JOY_BUTTON_B)
	_bind_key("command_wheel", KEY_Q)
	_bind_button("command_wheel", JOY_BUTTON_LEFT_SHOULDER)
	for index in 6:
		_bind_key("command_%s" % order_names[index].to_lower(), KEY_1 + index)
	_bind_key("pause", KEY_ESCAPE)
	_bind_button("pause", JOY_BUTTON_START)


func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.25)


func _bind_key(action: StringName, keycode) -> void:
	_ensure_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _bind_button(action: StringName, button) -> void:
	_ensure_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _bind_axis(action: StringName, axis, value: float) -> void:
	_ensure_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	InputMap.action_add_event(action, event)


func _reset_squad() -> void:
	squad.clear()
	fresh_flies.clear()
	fresh_fly_swarm.clear()
	fresh_fly_bursts.clear()
	fresh_fly_swarm_angle = 0.0
	# The opening swarm deploys through the same staggered three-second cadence
	# as later replacements instead of appearing all at once.
	fresh_fly_replacement_cooldown = FRESH_FLY_REPLACEMENT_DELAY
	next_fresh_fly_id = 0
	var guard_definitions: Array = content.get("expedition_guards", [])
	for index in guard_definitions.size():
		var definition: Dictionary = guard_definitions[index]
		var start_x := 115.0 - index * 30.0
		squad.append({
			"pos": Vector2(start_x, GROUND_Y),
			"role": String(definition.role),
			"health": float(definition.health),
			"max_health": float(definition.health),
			"hold_x": start_x,
			"facing": 1.0,
			"attack_cooldown": 0.0,
			"attack_flash": 0.0,
			"hurt_cooldown": 0.0,
			"fresh_fly_launch_cooldown": 0.0,
			"fresh_flies": int(definition.get("fresh_flies", 0))
		})


func _process(delta: float) -> void:
	elapsed += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	movement_lock = maxf(0.0, movement_lock - delta)
	spit_cooldown = maxf(0.0, spit_cooldown - delta)
	punch_flash = maxf(0.0, punch_flash - delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	order_flash = maxf(0.0, order_flash - delta)

	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
	if get_tree().paused:
		queue_redraw()
		return

	match phase:
		Phase.BRIEFING:
			_update_briefing()
		Phase.EXPEDITION:
			_update_expedition(delta)
		Phase.SLAB:
			_update_slab(delta)
		Phase.OUTCOME:
			_update_outcome()
	queue_redraw()


func _update_briefing() -> void:
	if Input.is_action_just_pressed("interact"):
		phase = Phase.EXPEDITION
		player.pos = Vector2(170, GROUND_Y)


func _read_orders() -> void:
	var chosen := -1
	if Input.is_action_just_pressed("command_follow"): chosen = Order.FOLLOW
	if Input.is_action_just_pressed("command_hold"): chosen = Order.HOLD
	if Input.is_action_just_pressed("command_attack"): chosen = Order.ATTACK
	if Input.is_action_just_pressed("command_defend"): chosen = Order.DEFEND
	if Input.is_action_just_pressed("command_restrain"): chosen = Order.RESTRAIN
	if Input.is_action_just_pressed("command_retreat"): chosen = Order.RETREAT
	if Input.is_action_just_pressed("command_wheel"):
		chosen = (order + 1) % order_names.size()
	if chosen >= 0:
		order = chosen
		order_flash = 1.1
		if order == Order.HOLD:
			for member in squad:
				member.hold_x = member.pos.x
		if order == Order.DEFEND:
			for member in squad:
				if member.role == "ACID_SPITTER":
					member.hold_x = member.pos.x


func _move_player(delta: float, left_bound: float, right_bound: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if movement_lock > 0.0:
		player.vel.x = 0.0
	else:
		player.vel.x = move_toward(player.vel.x, axis * PLAYER_SPEED, 1700.0 * delta)
	if movement_lock <= 0.0 and absf(axis) > 0.1:
		player.facing = signf(axis)
	if movement_lock <= 0.0 and Input.is_action_just_pressed("jump") and player.pos.y >= GROUND_Y - 0.5:
		player.vel.y = -JUMP_SPEED
	player.vel.y += GRAVITY * delta
	player.pos += player.vel * delta
	player.pos.x = clampf(player.pos.x, left_bound, right_bound)
	if player.pos.y > GROUND_Y:
		player.pos.y = GROUND_Y
		player.vel.y = 0.0


func _update_expedition(delta: float) -> void:
	_move_player(delta, 45.0, WORLD_END)
	_read_orders()
	_update_spit(delta, [target, scout])
	_update_acid_projectiles(delta, [target, scout])
	_update_acid_effects(delta, [target, scout])
	_update_squad(delta)
	# Orbit from the Brood Mother's position after squad movement. This keeps the
	# swarm attached and advancing even on the frame she reverses direction.
	_update_fresh_flies(delta, [target, scout])
	_update_enemy(target, delta, true)
	if scout.active:
		_update_enemy(scout, delta, false)

	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		_start_punch()
		_player_strike(target, PUNCH_DAMAGE)
		if scout.active: _player_strike(scout, PUNCH_DAMAGE)
	if Input.is_action_just_pressed("spit") and spit_cooldown <= 0.0:
		_fire_spit()

	if scout.active and scout.health <= 1.0 and player.pos.distance_to(scout.pos) < 90.0:
		expedition_message = "The scout yields. Press E to take them into custody."
		if Input.is_action_just_pressed("interact"):
			scout.captured = true
			scout.active = false
			expedition_message = "Optional prisoner secured. One fewer voice will answer the retaliation."

	var vulnerable: bool = target.health <= 35.0
	var binders := 0
	for member in squad:
		if member.pos.distance_to(target.pos) < 88.0 and member.health > 0.0:
			binders += 1
	if vulnerable and not target.captured and order == Order.RESTRAIN and binders >= 2 and player.pos.distance_to(target.pos) < 105.0:
		if Input.is_action_pressed("interact"):
			capture_progress = minf(1.0, capture_progress + delta / 1.35)
			expedition_message = "Hold steady. The Bell-Sworn must survive."
			if capture_progress >= 1.0:
				target.captured = true
				order = Order.FOLLOW
				expedition_message = "Vey is bound. Return west to the expedition camp."
		else:
			capture_progress = maxf(0.0, capture_progress - delta * 0.8)
	elif not target.captured:
		capture_progress = maxf(0.0, capture_progress - delta * 0.8)
		if vulnerable:
			expedition_message = "Vey falters. Order RESTRAIN and bring two squad members close."

	if target.captured:
		var escort_position: Vector2 = player.pos + Vector2(-ESCORT_PRISONER_OFFSET * player.facing, 0)
		var proposed_position: Vector2 = target.pos.lerp(escort_position, minf(1.0, delta * 5.0))
		target.pos = _limit_prisoner_to_forward_guard(proposed_position)
		if player.pos.x < 235.0:
			camp_progress = minf(1.0, camp_progress + delta / 1.0)
			if camp_progress >= 1.0:
				_enter_slab()
		else:
			camp_progress = 0.0

	if player.health <= 0.0:
		player.health = 100.0
		player.pos = Vector2(170, GROUND_Y)
		expedition_message = "The Warden was carried back to camp. Vey's wounds have closed a little."
		target.health = minf(target.max_health, target.health + 20.0)


func _player_strike(enemy: Dictionary, damage: float) -> void:
	if enemy.captured or player.pos.distance_to(enemy.pos) > PUNCH_RANGE:
		return
	if signf(enemy.pos.x - player.pos.x) != player.facing and absf(enemy.pos.x - player.pos.x) > 28.0:
		return
	enemy.health = maxf(1.0, enemy.health - damage)
	enemy.stun = 0.28
	var knockback := 10.0 if float(enemy.get("size", 1.0)) > 1.0 else 22.0
	enemy.pos.x += player.facing * knockback
	# Contract targets are never killed by continued attacks.
	if enemy == target and enemy.health <= 1.0:
		expedition_message = "Vey is incapacitated. Further violence only burdens the journey."


func _start_punch() -> void:
	attack_cooldown = PUNCH_COOLDOWN
	movement_lock = PUNCH_MOVEMENT_LOCK
	punch_flash = PUNCH_MOVEMENT_LOCK
	player.vel.x = 0.0
	if player.pos.y < GROUND_Y - 0.5:
		player.vel.y = maxf(player.vel.y, 480.0)


func _fire_spit() -> void:
	spit_cooldown = SPIT_COOLDOWN
	movement_lock = PUNCH_MOVEMENT_LOCK
	player.vel.x = 0.0
	spit_projectiles.append({
		"pos": player.pos + Vector2(player.facing * 28.0, -55.0),
		"vel": Vector2(SPIT_SPEED.x * player.facing, SPIT_SPEED.y)
	})


func _update_spit(delta: float, enemies: Array = [target, scout]) -> void:
	for index in range(spit_projectiles.size() - 1, -1, -1):
		var projectile := spit_projectiles[index]
		projectile.vel.y += SPIT_GRAVITY * delta
		projectile.pos += projectile.vel * delta
		var hit_enemy := false
		for enemy in enemies:
			if not bool(enemy.get("active", true)) or bool(enemy.get("captured", false)) or float(enemy.get("health", 0.0)) <= 0.0:
				continue
			var center: Vector2 = enemy.pos + Vector2(0.0, -34.0)
			if projectile.pos.distance_to(center) <= 34.0:
				enemy.stun = DIRECT_SPIT_STUN
				enemy.puddle_stun = 0.0
				hit_enemy = true
				break
		if hit_enemy:
			spit_projectiles.remove_at(index)
		elif projectile.pos.y >= GROUND_Y:
			spit_puddles.append({"x": projectile.pos.x, "lifetime": SPIT_PUDDLE_LIFETIME})
			spit_projectiles.remove_at(index)

	for index in range(spit_puddles.size() - 1, -1, -1):
		spit_puddles[index].lifetime -= delta
		if spit_puddles[index].lifetime <= 0.0:
			spit_puddles.remove_at(index)

	for enemy in enemies:
		if not bool(enemy.get("active", true)) or bool(enemy.get("captured", false)) or float(enemy.get("health", 0.0)) <= 0.0:
			continue
		var in_puddle := false
		for puddle in spit_puddles:
			if absf(enemy.pos.x - float(puddle.x)) <= SPIT_PUDDLE_RADIUS:
				in_puddle = true
				break
		var stun_time := 1.8 if float(enemy.get("size", 1.0)) > 1.0 else 0.8
		if in_puddle:
			enemy.puddle_stun = minf(stun_time, float(enemy.puddle_stun) + delta)
			if enemy.puddle_stun >= stun_time:
				enemy.stun = DIRECT_SPIT_STUN
				enemy.puddle_stun = 0.0
		else:
			enemy.puddle_stun = maxf(0.0, float(enemy.puddle_stun) - delta * 0.5)


func _fire_acid_spit(member: Dictionary, enemy: Dictionary) -> void:
	member.attack_cooldown = ACID_SPIT_COOLDOWN
	member.attack_flash = 0.18
	member.facing = signf(enemy.pos.x - member.pos.x)
	acid_projectiles.append({
		"pos": member.pos + Vector2(member.facing * 24.0, -50.0),
		"vel": Vector2(ACID_SPIT_SPEED.x * member.facing, ACID_SPIT_SPEED.y)
	})


func _update_acid_projectiles(delta: float, enemies: Array) -> void:
	for index in range(acid_projectiles.size() - 1, -1, -1):
		var projectile := acid_projectiles[index]
		projectile.vel.y += ACID_SPIT_GRAVITY * delta
		projectile.pos += projectile.vel * delta
		var hit_enemy := false
		for enemy in enemies:
			if not bool(enemy.get("active", true)) or bool(enemy.get("captured", false)) or float(enemy.get("health", 0.0)) <= 0.0:
				continue
			var center: Vector2 = enemy.pos + Vector2(0.0, -34.0)
			if projectile.pos.distance_to(center) <= 34.0:
				_apply_acid_hit(enemy)
				hit_enemy = true
				break
		if hit_enemy or projectile.pos.y >= GROUND_Y or projectile.pos.x < 0.0 or projectile.pos.x > WORLD_END:
			# Missed acid is spent on the ground and never creates a puddle.
			acid_projectiles.remove_at(index)


func _apply_acid_hit(enemy: Dictionary) -> void:
	enemy.health = maxf(1.0, float(enemy.health) - ACID_IMPACT_DAMAGE)
	enemy.acid_duration = minf(ACID_MAX_DURATION, float(enemy.get("acid_duration", 0.0)) + ACID_DURATION_PER_HIT)
	if float(enemy.get("acid_tick", 0.0)) <= 0.0:
		enemy.acid_tick = ACID_TICK_INTERVAL


func _update_acid_effects(delta: float, enemies: Array) -> void:
	for enemy in enemies:
		if bool(enemy.get("captured", false)) or float(enemy.get("acid_duration", 0.0)) <= 0.0:
			continue
		var active_time := minf(delta, float(enemy.acid_duration))
		enemy.acid_duration = maxf(0.0, float(enemy.acid_duration) - delta)
		enemy.acid_tick = float(enemy.acid_tick) - active_time
		while enemy.acid_tick <= 0.0:
			enemy.health = maxf(1.0, float(enemy.health) - ACID_TICK_DAMAGE)
			enemy.acid_tick += ACID_TICK_INTERVAL
		if enemy.acid_duration <= 0.0:
			enemy.acid_tick = 0.0


func _update_enemy(enemy: Dictionary, delta: float, is_target: bool) -> void:
	if enemy.captured:
		return
	enemy.stun = maxf(0.0, enemy.stun - delta)
	if enemy.stun > 0.0:
		return
	var distance: float = enemy.pos.distance_to(player.pos)
	var brood_mother := _tiny_brood_mother()
	if not brood_mother.is_empty():
		var brood_distance: float = brood_mother.pos.distance_to(enemy.pos)
		if brood_distance <= 76.0 and brood_distance < distance and brood_mother.hurt_cooldown <= 0.0:
			_damage_squad_member(brood_mother, 13.0 if is_target else 8.0, enemy)
			return
	if distance < 360.0 and distance > 72.0:
		enemy.pos.x += signf(player.pos.x - enemy.pos.x) * (95.0 if is_target else 125.0) * delta
	elif distance <= 76.0 and invulnerable <= 0.0:
		var damage := 13.0 if is_target else 8.0
		if order == Order.DEFEND:
			var nearby_defenders := 0
			for member in squad:
				if member.health > 0.0 and member.pos.distance_to(player.pos) < 115.0:
					nearby_defenders += 1
			damage *= maxf(0.35, 1.0 - nearby_defenders * 0.2)
		player.health -= damage
		invulnerable = 0.72
		player.vel.x = signf(player.pos.x - enemy.pos.x) * 290.0


func _update_squad(delta: float) -> void:
	for index in squad.size():
		var member := squad[index]
		member.attack_cooldown = maxf(0.0, float(member.attack_cooldown) - delta)
		member.attack_flash = maxf(0.0, float(member.attack_flash) - delta)
		member.hurt_cooldown = maxf(0.0, float(member.get("hurt_cooldown", 0.0)) - delta)
		member.fresh_fly_launch_cooldown = maxf(0.0, float(member.get("fresh_fly_launch_cooldown", 0.0)) - delta)
		if member.health <= 0.0:
			continue
		var destination: float = member.pos.x
		match order:
			Order.FOLLOW:
				if target.captured:
					# One guard leads the prisoner and the others close the formation.
					var escort_side := 1.0 if index == 0 else -1.0
					destination = target.pos.x + player.facing * ESCORT_GUARD_OFFSET * escort_side
				else:
					destination = player.pos.x - player.facing * (
						SQUAD_FOLLOW_FIRST_OFFSET + index * SQUAD_FOLLOW_SPACING
					)
			Order.DEFEND:
				if member.role == "ACID_SPITTER":
					destination = member.hold_x
				else:
					destination = player.pos.x - player.facing * SQUAD_FOLLOW_FIRST_OFFSET
			Order.HOLD:
				destination = member.hold_x
			Order.ATTACK:
				if member.role == "ACID_SPITTER":
					var target_direction := signf(target.pos.x - member.pos.x)
					if target_direction == 0.0:
						target_direction = member.facing
					destination = target.pos.x - target_direction * ACID_PREFERRED_RANGE
				elif member.role == "NEEDLE":
					destination = target.pos.x - 45.0
				else:
					destination = player.pos.x - player.facing * SQUAD_FOLLOW_FIRST_OFFSET
			Order.RESTRAIN:
				destination = target.pos.x + (-42.0 if index % 2 == 0 else 42.0)
			Order.RETREAT:
				destination = 150.0 + index * 34.0
		if absf(destination - member.pos.x) > 0.5:
			member.facing = signf(destination - member.pos.x)
		member.pos.x = move_toward(member.pos.x, destination, 215.0 * delta)
		if order == Order.ATTACK and member.role == "NEEDLE" and not target.captured:
			member.facing = signf(target.pos.x - member.pos.x)
			if absf(member.pos.x - target.pos.x) <= NEEDLE_RANGE and member.attack_cooldown <= 0.0:
				_needle_guard_attack(member)
		if member.role == "ACID_SPITTER" and member.attack_cooldown <= 0.0:
			var acid_target: Dictionary = {}
			if order == Order.ATTACK and not target.captured:
				var attack_distance := absf(target.pos.x - member.pos.x)
				if attack_distance >= ACID_MIN_RANGE and attack_distance <= ACID_MAX_RANGE:
					acid_target = target
			elif order == Order.DEFEND:
				acid_target = _acid_defend_target(member)
			if not acid_target.is_empty():
				_fire_acid_spit(member, acid_target)
		if member.role == "TINY_BROOD_MOTHER" and order == Order.ATTACK:
			_try_launch_swarm_fly(member, target)


func _tiny_brood_mother() -> Dictionary:
	for member in squad:
		if member.role == "TINY_BROOD_MOTHER" and member.health > 0.0:
			return member
	return {}


func _fresh_fly_reserve_count(member: Dictionary) -> int:
	# Undeployed and orbiting flies have not launched yet. Flies already in
	# flight are committed and therefore no longer appear in the reserve count.
	return mini(FRESH_FLY_CAPACITY, int(member.get("fresh_flies", 0)) + fresh_fly_swarm.size())


func _can_fresh_fly_target(enemy: Dictionary) -> bool:
	return (
		bool(enemy.get("active", true))
		and not bool(enemy.get("captured", false))
		and float(enemy.get("health", 0.0)) > float(enemy.get("capture_threshold", 1.0))
	)


func _add_fresh_fly_to_swarm(member: Dictionary) -> bool:
	if int(member.get("fresh_flies", 0)) <= 0 or fresh_fly_swarm.size() >= FRESH_FLY_SWARM_LIMIT:
		return false
	member.fresh_flies -= 1
	fresh_fly_swarm.append({
		"id": next_fresh_fly_id,
		"pos": member.pos + FRESH_FLY_SWARM_CENTER,
		"swarm_time": 0.0,
		"facing": -1.0
	})
	next_fresh_fly_id += 1
	return true


func _try_launch_swarm_fly(member: Dictionary, enemy: Dictionary) -> bool:
	if member.fresh_fly_launch_cooldown > 0.0 or not _can_fresh_fly_target(enemy):
		return false
	for index in fresh_fly_swarm.size():
		if float(fresh_fly_swarm[index].swarm_time) >= FRESH_FLY_SWARM_TIME:
			_launch_swarm_fly(member, index, enemy)
			member.fresh_fly_launch_cooldown = FRESH_FLY_ATTACK_INTERVAL
			return true
	return false


func _launch_swarm_fly(member: Dictionary, swarm_index: int, enemy: Dictionary) -> void:
	var fly := fresh_fly_swarm[swarm_index]
	var launch_facing := signf(enemy.pos.x - fly.pos.x)
	if launch_facing == 0.0:
		launch_facing = member.facing
	member.attack_flash = 0.18
	fly.target = enemy
	fly.returning = false
	fly.facing = launch_facing
	fresh_flies.append(fly)
	fresh_fly_swarm.remove_at(swarm_index)
	if fresh_fly_replacement_cooldown <= 0.0:
		fresh_fly_replacement_cooldown = FRESH_FLY_REPLACEMENT_DELAY


func _damage_squad_member(member: Dictionary, damage: float, attacker: Dictionary) -> void:
	var was_alive := float(member.health) > 0.0
	member.health = maxf(0.0, float(member.health) - damage)
	member.hurt_cooldown = 0.72
	if was_alive and member.health <= 0.0:
		expedition_message = "%s is down and can no longer act." % String(member.role).replace("_", " ").capitalize()
		if member.role == "TINY_BROOD_MOTHER":
			fresh_fly_swarm.clear()
			fresh_flies.clear()
	if member.role != "TINY_BROOD_MOTHER" or member.health <= 0.0:
		return
	# Retaliation launches every fly already in the swarm, regardless of its age
	# or the ordinary commanded-attack interval.
	for index in range(fresh_fly_swarm.size() - 1, -1, -1):
		_launch_swarm_fly(member, index, attacker)
	member.fresh_fly_launch_cooldown = FRESH_FLY_ATTACK_INTERVAL


func _update_fresh_flies(delta: float, enemies: Array = [target, scout]) -> void:
	for index in range(fresh_fly_bursts.size() - 1, -1, -1):
		fresh_fly_bursts[index].lifetime -= delta
		if fresh_fly_bursts[index].lifetime <= 0.0:
			fresh_fly_bursts.remove_at(index)
	var brood_mother := _tiny_brood_mother()
	if not brood_mother.is_empty():
		# Mark invalid targets before considering replacements so a returning fly
		# keeps its place in the three-fly swarm.
		for flying_fly in fresh_flies:
			if not bool(flying_fly.returning) and not _can_fresh_fly_target(flying_fly.target):
				flying_fly.returning = true
		fresh_fly_swarm_angle = fmod(fresh_fly_swarm_angle + FRESH_FLY_SWARM_ROTATION_SPEED * delta, TAU)
		for index in fresh_fly_swarm.size():
			var swarm_fly := fresh_fly_swarm[index]
			swarm_fly.swarm_time = float(swarm_fly.swarm_time) + delta
			var angle := fresh_fly_swarm_angle + TAU * float(index) / maxf(1.0, float(fresh_fly_swarm.size()))
			var previous_x := float(swarm_fly.pos.x)
			swarm_fly.pos = brood_mother.pos + FRESH_FLY_SWARM_CENTER + Vector2(cos(angle) * FRESH_FLY_SWARM_RADIUS.x, sin(angle) * FRESH_FLY_SWARM_RADIUS.y)
			if absf(float(swarm_fly.pos.x) - previous_x) > 0.5:
				swarm_fly.facing = signf(float(swarm_fly.pos.x) - previous_x)

		var returning_count := 0
		for flying_fly in fresh_flies:
			if bool(flying_fly.returning):
				returning_count += 1
		if fresh_fly_swarm.size() + returning_count < FRESH_FLY_SWARM_LIMIT and int(brood_mother.fresh_flies) > 0:
			fresh_fly_replacement_cooldown = maxf(0.0, fresh_fly_replacement_cooldown - delta)
			if fresh_fly_replacement_cooldown <= 0.0:
				_add_fresh_fly_to_swarm(brood_mother)
				if fresh_fly_swarm.size() + returning_count < FRESH_FLY_SWARM_LIMIT and int(brood_mother.fresh_flies) > 0:
					fresh_fly_replacement_cooldown = FRESH_FLY_REPLACEMENT_DELAY
		else:
			fresh_fly_replacement_cooldown = 0.0
	for index in range(fresh_flies.size() - 1, -1, -1):
		var fly := fresh_flies[index]
		var enemy: Dictionary = fly.target
		if not bool(fly.returning) and not _can_fresh_fly_target(enemy):
			fly.returning = true
		if bool(fly.returning):
			if brood_mother.is_empty():
				fresh_flies.remove_at(index)
				continue
			var return_destination: Vector2 = brood_mother.pos + Vector2(0.0, -48.0)
			if absf(return_destination.x - fly.pos.x) > 0.5:
				fly.facing = signf(return_destination.x - fly.pos.x)
			fly.pos = fly.pos.move_toward(return_destination, FRESH_FLY_SPEED * delta)
			if fly.pos.distance_to(return_destination) <= 8.0:
				fly.erase("target")
				fly.erase("returning")
				fly.swarm_time = 0.0
				fresh_fly_swarm.append(fly)
				fresh_flies.remove_at(index)
			continue
		var destination: Vector2 = enemy.pos + Vector2(0.0, -32.0)
		if absf(destination.x - fly.pos.x) > 0.5:
			fly.facing = signf(destination.x - fly.pos.x)
		fly.pos = fly.pos.move_toward(destination, FRESH_FLY_SPEED * delta)
		if fly.pos.distance_to(destination) <= 10.0:
			_explode_fresh_fly(fly.pos, enemies)
			fresh_flies.remove_at(index)


func _explode_fresh_fly(position: Vector2, enemies: Array) -> void:
	fresh_fly_bursts.append({"pos": position, "lifetime": 0.22})
	for enemy in enemies:
		if not bool(enemy.get("active", true)) or bool(enemy.get("captured", false)):
			continue
		if (enemy.pos + Vector2(0.0, -32.0)).distance_to(position) > FRESH_FLY_EXPLOSION_RADIUS:
			continue
		var threshold := float(enemy.get("capture_threshold", 1.0))
		enemy.health = maxf(threshold, float(enemy.health) - FRESH_FLY_DAMAGE)
		enemy.stun = maxf(float(enemy.get("stun", 0.0)), 0.15)


func _acid_defend_target(member: Dictionary) -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_distance := INF
	for enemy in [target, scout]:
		if enemy == scout and not scout.active:
			continue
		if enemy.captured or enemy.health <= 1.0:
			continue
		var distance := absf(enemy.pos.x - member.pos.x)
		if distance <= ACID_MAX_RANGE and distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest


func _needle_guard_attack(member: Dictionary) -> void:
	member.attack_cooldown = NEEDLE_COOLDOWN
	member.attack_flash = 0.18
	# The swing is aimed at the commanded target but cleaves every enemy in its
	# forward attack area. It deliberately applies no knockback.
	for enemy in [target, scout]:
		if enemy == scout and not scout.active:
			continue
		if enemy.captured:
			continue
		var offset: float = enemy.pos.x - member.pos.x
		if absf(offset) <= NEEDLE_RANGE and (signf(offset) == member.facing or absf(offset) < 24.0):
			enemy.health = maxf(1.0, float(enemy.health) - NEEDLE_DAMAGE)
			enemy.stun = maxf(float(enemy.stun), 0.1)


func _limit_prisoner_to_forward_guard(proposed_position: Vector2) -> Vector2:
	var travel_direction: float = player.facing
	var forward_guard_progress := -INF
	for member in squad:
		if member.health > 0.0:
			forward_guard_progress = maxf(forward_guard_progress, member.pos.x * travel_direction)
	if forward_guard_progress == -INF:
		return proposed_position

	var maximum_prisoner_progress := forward_guard_progress - ESCORT_MINIMUM_LEAD
	var proposed_progress := proposed_position.x * travel_direction
	if proposed_progress > maximum_prisoner_progress:
		proposed_position.x = maximum_prisoner_progress * travel_direction
	return proposed_position


func _enter_slab() -> void:
	phase = Phase.SLAB
	player.pos = Vector2(120, GROUND_Y)
	player.vel = Vector2.ZERO
	player.health = 100.0
	_reset_squad()
	for index in squad.size():
		squad[index].pos = Vector2(160 + index * 30, GROUND_Y)


func _update_slab(delta: float) -> void:
	_move_player(delta, 45.0, 1215.0)
	_update_spit(delta, raiders)
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		_start_punch()
		for raider in raiders:
			var offset: float = raider.pos.x - player.pos.x
			if raider.health > 0.0 and player.pos.distance_to(raider.pos) < PUNCH_RANGE and (signf(offset) == player.facing or absf(offset) < 28.0):
				raider.health -= 24.0
				raider.pos.x += player.facing * 22.0
	if Input.is_action_just_pressed("spit") and spit_cooldown <= 0.0:
		_fire_spit()

	if not emergency_started:
		_update_slab_stations()
		if slab_tasks.brood_fed and slab_tasks.cell_inspected:
			emergency_delay -= delta
			slab_message = "A low bell answers from beyond the walls..."
			if emergency_delay <= 0.0:
				_start_emergency()
	else:
		_update_emergency(delta)

	if emergency_resolved and player.pos.x > 1110.0:
		slab_message = "The Citadel carriage waits. Press E to entrust Vey to the Memorium."
		if Input.is_action_just_pressed("interact"):
			_finish_prototype()

	if player.health <= 0.0:
		player.health = 60.0
		player.pos = Vector2(300, GROUND_Y)
		cell_integrity = maxf(5.0, cell_integrity - 18.0)
		slab_message = "The staff pull the Warden from danger. The cell paid the price."


func _update_slab_stations() -> void:
	if player.pos.x < 350.0:
		if not slab_tasks.brood_fed:
			slab_message = "The Brood Mother waits. Press E to spend 10 shell on food."
			if Input.is_action_just_pressed("interact"):
				coins -= 10
				slab_tasks.brood_fed = true
				slab_message = "She eats. New hands will come, in time."
	elif player.pos.x > 520.0 and player.pos.x < 770.0:
		slab_message = "Guard desk: %d assigned to Vey. Press E to change (1–3)." % cell_guards
		if Input.is_action_just_pressed("interact"):
			cell_guards = cell_guards % 3 + 1
	elif player.pos.x > 880.0:
		if not slab_tasks.cell_inspected:
			slab_message = "Vey's bindings sing against the stone. Press E to inspect the cell."
			if Input.is_action_just_pressed("interact"):
				slab_tasks.cell_inspected = true
				slab_message = "The cell will hold—if enough guards remain near it."


func _start_emergency() -> void:
	emergency_started = true
	var count := 4 - (1 if scout.captured else 0)
	for index in count:
		raiders.append({"pos": Vector2(1160 + index * 36, GROUND_Y), "health": 42.0, "hit": 0.0, "stun": 0.0, "size": 1.0, "puddle_stun": 0.0})
	slab_message = "The Mourning Choir breaches the east hall. Protect the living—and the prisoner."


func _update_emergency(delta: float) -> void:
	if vey_escaped:
		_update_vey_escape(delta)
		return

	var living := 0
	for raider in raiders:
		if raider.health <= 0.0:
			continue
		living += 1
		raider.stun = maxf(0.0, float(raider.stun) - delta)
		if raider.stun > 0.0:
			continue
		raider.hit = maxf(0.0, raider.hit - delta)
		var destination: float = player.pos.x
		if cell_guards < 2:
			destination = 960.0
		if absf(raider.pos.x - destination) > 62.0:
			raider.pos.x = move_toward(raider.pos.x, destination, 105.0 * delta)
		elif destination == player.pos.x and raider.hit <= 0.0 and invulnerable <= 0.0:
			player.health -= 9.0
			invulnerable = 0.6
			raider.hit = 0.7
		elif destination == 960.0:
			cell_integrity -= 7.0 * delta

	# Guards at the cell slow a breach; guards held back help defeat attackers.
	cell_integrity -= maxf(0.0, 2.0 - cell_guards) * 2.4 * delta
	var field_guards := 3 - cell_guards
	if field_guards > 0 and living > 0:
		for raider in raiders:
			if raider.health > 0.0:
				raider.health -= field_guards * 4.2 * delta
				break

	if player.pos.x > 875.0 and player.pos.x < 1035.0 and Input.is_action_just_pressed("interact"):
		cell_integrity = minf(100.0, cell_integrity + 18.0)
		slab_message = "The Warden braces the bindings. The cell holds a little longer."

	if cell_integrity <= 0.0:
		_release_vey()
		return
	if living == 0:
		emergency_resolved = true
		slab_message = "The breach is quiet. Take Vey east when you are ready."


func _release_vey() -> void:
	cell_integrity = 0.0
	vey_escaped = true
	target.captured = false
	target.pos = Vector2(970.0, GROUND_Y)
	player.health = maxf(15.0, player.health - 25.0)
	for raider in raiders:
		raider.health = 0.0
	slab_message = "The bars give way. Vey runs for the east breach."


func _update_vey_escape(delta: float) -> void:
	target.pos.x += VEY_ESCAPE_SPEED * delta
	if target.pos.x >= VEY_ESCAPE_EXIT_X:
		_finish_escape()


func _finish_escape() -> void:
	phase = Phase.OUTCOME
	result = {
		"escaped": true,
		"payment": 0,
		"cell": 0,
		"scout": scout.captured
	}


func _finish_prototype() -> void:
	phase = Phase.OUTCOME
	var payment: int = int(content.contract.payment) + (int(content.optional_prisoner.payment) if scout.captured else 0)
	result = {
		"escaped": false,
		"payment": payment,
		"cell": roundi(cell_integrity),
		"scout": scout.captured,
		"retaliation": 1,
		"research": content.contract.research
	}


func _update_outcome() -> void:
	if Input.is_action_just_pressed("interact"):
		get_tree().reload_current_scene()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("11141d"))
	match phase:
		Phase.BRIEFING: _draw_briefing()
		Phase.EXPEDITION: _draw_expedition()
		Phase.SLAB: _draw_slab()
		Phase.OUTCOME: _draw_outcome()
	if get_tree().paused:
		draw_rect(Rect2(Vector2.ZERO, VIEW), Color(0.03, 0.04, 0.05, 0.72))
		_title("PAUSED", Vector2(565, 330), 32)
		_text("Escape / Start to return", Vector2(515, 375), 17)


func _draw_briefing() -> void:
	draw_circle(Vector2(1020, 150), 210, Color("1b2830"))
	draw_circle(Vector2(1020, 150), 160, Color("24343a"), false, 3.0)
	_title("A CONTRACT IN QUIET INK", Vector2(88, 92), 34)
	_text(content.department.name, Vector2(92, 140), 22, Color("b9c7bf"))
	_text("Curator %s requests the preservation of" % content.department.curator.trim_prefix("Curator "), Vector2(92, 193), 20)
	_text(content.contract.target, Vector2(92, 229), 32, Color("e1c48d"))
	_text("Danger", Vector2(92, 300), 16, Color("74878d")); _text(content.contract.danger, Vector2(260, 300), 18)
	_text("Containment", Vector2(92, 338), 16, Color("74878d")); _text(content.contract.containment, Vector2(260, 338), 18)
	_text("Reward", Vector2(92, 376), 16, Color("74878d")); _text("180 shell + Resonance baffling", Vector2(260, 376), 18)
	_text("One target. Bring them breathing.", Vector2(92, 465), 21, Color("b9c7bf"))
	_prompt("E / B  ACCEPT CONTRACT", Vector2(92, 610))


func _camera_x() -> float:
	return clampf(player.pos.x - 430.0, 0.0, WORLD_END - VIEW.x)


func _draw_expedition() -> void:
	var cam := _camera_x()
	# Layered cavern silhouettes.
	draw_circle(Vector2(960 - cam * 0.12, 260), 230, Color("172830"))
	for x in range(0, 2800, 170):
		var height := 100.0 + float((x * 37) % 170)
		draw_polygon(PackedVector2Array([Vector2(x-cam, GROUND_Y), Vector2(x+75-cam, GROUND_Y-height), Vector2(x+150-cam, GROUND_Y)]), PackedColorArray([Color("1b2429")]))
	draw_rect(Rect2(0, GROUND_Y + 28, VIEW.x, 130), Color("24262b"))
	draw_line(Vector2(0, GROUND_Y+27), Vector2(VIEW.x, GROUND_Y+27), Color("53605d"), 3)
	for puddle in spit_puddles:
		var puddle_pos := Vector2(float(puddle.x) - cam, GROUND_Y + 20.0)
		draw_ellipse(puddle_pos, SPIT_PUDDLE_RADIUS, 10.0, Color(0.49, 0.68, 0.58, 0.68))
	for projectile in spit_projectiles:
		draw_circle(projectile.pos - Vector2(cam, 0.0), 9.0, Color("91bea3"))
	for projectile in acid_projectiles:
		draw_circle(projectile.pos - Vector2(cam, 0.0), 7.0, Color("b7d65b"))
	for fly in fresh_fly_swarm:
		_draw_fresh_fly(fly.pos - Vector2(cam, 0.0), false, float(fly.facing))
	for fly in fresh_flies:
		_draw_fresh_fly(fly.pos - Vector2(cam, 0.0), bool(fly.returning), float(fly.facing))
	for burst in fresh_fly_bursts:
		var burst_ratio: float = float(burst.lifetime) / 0.22
		draw_circle(burst.pos - Vector2(cam, 0.0), FRESH_FLY_EXPLOSION_RADIUS * (1.0 - burst_ratio * 0.35), Color(0.88, 0.58, 0.25, burst_ratio * 0.42), false, 6.0)
	_draw_camp(Vector2(145-cam, GROUND_Y))
	if scout.active: _draw_enemy(scout.pos - Vector2(cam, 0), scout.health / 48.0, false)
	_draw_enemy(target.pos - Vector2(cam, 0), target.health / target.max_health, true)
	for member in squad:
		_draw_squad_member(
			member.pos - Vector2(cam, 0),
			member.role,
			member.facing,
			member.attack_flash,
			float(member.health) / float(member.max_health)
		)
	_draw_warden(player.pos - Vector2(cam, 0))
	_draw_hud("EXPEDITION · THE HUSHED GALLERIES", expedition_message)
	_draw_order_bar()
	if capture_progress > 0.0:
		_bar(Vector2(480, 505), Vector2(320, 13), capture_progress, Color("d9bd83"), "BINDING")
	if camp_progress > 0.0:
		_bar(Vector2(480, 505), Vector2(320, 13), camp_progress, Color("8eb5a0"), "TRANSPORTING")


func _draw_slab() -> void:
	draw_rect(Rect2(0, 145, VIEW.x, 475), Color("1b2026"))
	for x in range(0, 1280, 128):
		draw_line(Vector2(x, 145), Vector2(x, 620), Color("242d32"), 2)
	draw_line(Vector2(0, 618), Vector2(1280, 618), Color("68706b"), 4)
	for puddle in spit_puddles:
		draw_ellipse(Vector2(float(puddle.x), GROUND_Y + 20.0), SPIT_PUDDLE_RADIUS, 10.0, Color(0.49, 0.68, 0.58, 0.68))
	for projectile in spit_projectiles:
		draw_circle(projectile.pos, 9.0, Color("91bea3"))
	# Brood chamber, command desk, containment cell, and east gate.
	draw_circle(Vector2(245, 480), 82, Color("4c3f3c"))
	draw_circle(Vector2(245, 478), 54, Color("8c6c62"))
	_text("BROOD", Vector2(205, 385), 15, Color("b79b8e"))
	draw_rect(Rect2(555, 510, 150, 75), Color("384147")); _text("GUARD DESK", Vector2(567, 495), 14, Color("91a0a1"))
	draw_rect(Rect2(895, 340, 150, 250), Color("252b30"), true)
	if vey_escaped:
		_draw_enemy(target.pos, target.health / target.max_health, true, false)
	_draw_cell_bars()
	_text("VEY", Vector2(952, 320), 15, Color("d6bd8b"))
	draw_rect(Rect2(1160, 250, 85, 340), Color("30383b")); _text("EAST", Vector2(1175, 230), 14)
	for raider in raiders:
		if raider.health > 0.0: _draw_raider(raider.pos)
	_draw_warden(player.pos)
	_draw_hud("THE SLAB · CONTAINMENT LEVEL", slab_message)
	_bar(Vector2(895, 650), Vector2(250, 10), cell_integrity / 100.0, Color("b98d72"), "CELL INTEGRITY")
	_text("Shell %d" % coins, Vector2(50, 680), 17, Color("d9bd83"))
	_text("Cell guards %d   Field guards %d" % [cell_guards, 3-cell_guards], Vector2(190, 680), 17)
	if not emergency_started:
		_text("Feed Brood %s     Inspect cell %s" % [_mark(slab_tasks.brood_fed), _mark(slab_tasks.cell_inspected)], Vector2(510, 680), 16)


func _draw_outcome() -> void:
	if result.get("escaped", false):
		_draw_escape_outcome()
		return
	draw_circle(Vector2(640, 295), 195, Color("213037"))
	draw_circle(Vector2(640, 295), 148, Color("11141d"), false, 4)
	_title("PRESERVED", Vector2(525, 110), 35)
	_text("Vey, the Bell-Sworn", Vector2(515, 176), 25, Color("e1c48d"))
	_text("rests beyond violence in the Memorium.", Vector2(425, 215), 19)
	_text("Payment", Vector2(390, 355), 16, Color("74878d")); _text("%d shell" % result.payment, Vector2(610, 355), 20)
	_text("Research", Vector2(390, 392), 16, Color("74878d")); _text(result.research, Vector2(610, 392), 20)
	_text("Cell integrity", Vector2(390, 429), 16, Color("74878d")); _text("%d%%" % result.cell, Vector2(610, 429), 20)
	_text("Optional prisoner", Vector2(390, 466), 16, Color("74878d")); _text("secured" if result.scout else "left free", Vector2(610, 466), 20)
	_text("The Mourning Choir is diminished—but now it knows the Slab.", Vector2(335, 535), 18, Color("b9c7bf"))
	_text("Retaliation rises to I", Vector2(520, 570), 17, Color("bd8175"))
	_prompt("E / B  BEGIN AGAIN", Vector2(520, 650))


func _draw_escape_outcome() -> void:
	draw_circle(Vector2(640, 295), 195, Color("32252a"))
	draw_circle(Vector2(640, 295), 148, Color("11141d"), false, 4)
	_title("CONTAINMENT BROKEN", Vector2(455, 110), 35)
	_text("Vey, the Bell-Sworn", Vector2(515, 176), 25, Color("d79b8f"))
	_text("has fled alive into Pharloom.", Vector2(490, 215), 19)
	_text("Payment", Vector2(390, 355), 16, Color("74878d")); _text("0 shell", Vector2(610, 355), 20)
	_text("Preservation", Vector2(390, 392), 16, Color("74878d")); _text("not completed", Vector2(610, 392), 20)
	_text("Optional prisoner", Vector2(390, 429), 16, Color("74878d")); _text("secured" if result.scout else "left free", Vector2(610, 429), 20)
	_text("The Choir bought Vey a road into the dark.", Vector2(440, 520), 18, Color("b9c7bf"))
	_text("The target remains alive—and at large.", Vector2(460, 557), 17, Color("bd8175"))
	_prompt("E / B  BEGIN AGAIN", Vector2(520, 650))


func _draw_cell_bars() -> void:
	if not vey_escaped:
		for x in range(910, 1040, 24):
			draw_line(Vector2(x, 350), Vector2(x, 580), Color("7a8580"), 4)
		return

	# Split and offset the center bars to leave a visibly broken opening.
	for index in range(6):
		var x := 910.0 + index * 24.0
		if index == 0 or index == 5:
			draw_line(Vector2(x, 350), Vector2(x + (5.0 if index == 0 else -5.0), 580), Color("626b68"), 4)
			continue
		var bend := -13.0 if index % 2 == 0 else 11.0
		var break_y := 425.0 + (index % 3) * 13.0
		draw_line(Vector2(x, 350), Vector2(x + bend, break_y), Color("7a8580"), 4)
		draw_line(Vector2(x - bend * 0.7, break_y + 42.0), Vector2(x + bend * 1.4, 580), Color("626b68"), 4)


func _draw_hud(location: String, message: String) -> void:
	draw_rect(Rect2(0, 0, VIEW.x, 112), Color(0.045, 0.055, 0.075, 0.94))
	_text(location, Vector2(34, 34), 15, Color("83999b"))
	_text(message, Vector2(34, 74), 18, Color("d2d5ca"))
	_bar(Vector2(1020, 36), Vector2(220, 12), player.health / 100.0, Color("b96e68"), "WARDEN")
	if phase == Phase.EXPEDITION or phase == Phase.SLAB:
		var spit_status := "READY" if spit_cooldown <= 0.0 else "%.1fs" % spit_cooldown
		_text("SPIT  %s" % spit_status, Vector2(1090, 82), 14, Color("91bea3"))


func _draw_order_bar() -> void:
	draw_rect(Rect2(330, 646, 620, 57), Color(0.04, 0.05, 0.07, 0.92))
	for index in order_names.size():
		var active: bool = order == index
		_text("%d %s" % [index+1, order_names[index]], Vector2(345 + index*98, 680), 13, Color("e1c48d") if active else Color("788489"))
	if order_flash > 0.0:
		_text(order_names[order], Vector2(575, 625), 18, Color("e1c48d"))


func _draw_warden(pos: Vector2) -> void:
	var blink := invulnerable > 0.0 and int(elapsed * 15.0) % 2 == 0
	if blink: return
	if warden_texture:
		var texture_size := warden_texture.get_size()
		var draw_width := WARDEN_DRAW_HEIGHT * texture_size.x / texture_size.y
		# The source artwork faces left, so invert it when the Warden faces right.
		draw_set_transform(pos, 0.0, Vector2(-player.facing, 1.0))
		draw_texture_rect(
			warden_texture,
			Rect2(-draw_width / 2.0, -WARDEN_DRAW_HEIGHT + 24.0, draw_width, WARDEN_DRAW_HEIGHT),
			false
		)
		draw_set_transform(Vector2.ZERO)
		if punch_flash > 0.0:
			draw_line(pos + Vector2(player.facing * 16.0, -38.0), pos + Vector2(player.facing * 54.0, -38.0), Color("d8c190"), 7.0)
			draw_circle(pos + Vector2(player.facing * 58.0, -38.0), 7.0, Color("d8c190"))
		return
	draw_circle(pos + Vector2(0, -36), 17, Color("c4d5cc"))
	draw_polygon(PackedVector2Array([pos+Vector2(-20,-20), pos+Vector2(20,-20), pos+Vector2(27,22), pos+Vector2(-27,22)]), PackedColorArray([Color("526a70")]))
	draw_line(pos+Vector2(player.facing*10,-20), pos+Vector2(player.facing*39,3), Color("d8c190"), 5)


func _draw_squad_member(pos: Vector2, role: String, facing: float, attack_flash: float = 0.0, health_ratio: float = 1.0) -> void:
	var downed := health_ratio <= 0.0
	var displayed_health := clampf(health_ratio, 0.0, 1.0)
	draw_rect(Rect2(pos + Vector2(-28.0, -91.0), Vector2(56.0, 6.0)), Color("20252a"))
	draw_rect(Rect2(pos + Vector2(-27.0, -90.0), Vector2(54.0 * displayed_health, 4.0)), Color("80ad83") if not downed else Color("704f4b"))
	if guard_texture:
		var texture_size := guard_texture.get_size()
		var draw_width := GUARD_DRAW_HEIGHT * texture_size.x / texture_size.y
		# The source artwork faces left, so invert it when a guard faces right.
		draw_set_transform(pos, 0.0, Vector2(-facing, 1.0))
		draw_texture_rect(
			guard_texture,
			Rect2(-draw_width / 2.0, -GUARD_DRAW_HEIGHT + 24.0, draw_width, GUARD_DRAW_HEIGHT),
			false,
			Color(0.34, 0.36, 0.38, 0.72) if downed else Color.WHITE
		)
		draw_set_transform(Vector2.ZERO)
		if downed:
			_text("DOWN", pos + Vector2(-22.0, 32.0), 12, Color("b98d72"))
			return
		if role == "NEEDLE":
			draw_line(pos + Vector2(facing * 8.0, -34.0), pos + Vector2(facing * 54.0, -15.0), Color("d9bd83"), 4.0)
			if attack_flash > 0.0:
				draw_arc(pos + Vector2(facing * 18.0, -28.0), 58.0, -1.25 if facing > 0.0 else 1.9, 1.25 if facing > 0.0 else 4.4, 18, Color("e8d9ae"), 5.0)
		elif role == "ACID_SPITTER":
			draw_circle(pos + Vector2(facing * 25.0, -48.0), 5.0, Color("b7d65b"))
			if attack_flash > 0.0:
				draw_line(pos + Vector2(facing * 28.0, -48.0), pos + Vector2(facing * 48.0, -53.0), Color("d5ed83"), 4.0)
		elif role == "TINY_BROOD_MOTHER":
			draw_circle(pos + Vector2(0.0, -34.0), 18.0, Color("8c6c62"), false, 4.0)
			_text(str(_fresh_fly_reserve_count(_tiny_brood_mother())), pos + Vector2(-5.0, -29.0), 12, Color("ead8a6"))
		return
	draw_circle(pos + Vector2(0,-25), 12, Color("4b5050") if downed else Color("8ca4a0"))
	draw_rect(Rect2(pos+Vector2(-14,-13), Vector2(28,35)), Color("292d30") if downed else Color("405159"))
	if downed:
		_text("DOWN", pos + Vector2(-22.0, 32.0), 12, Color("b98d72"))
		return
	_text(role.substr(0,1), pos+Vector2(-5,5), 12, Color("d9bd83"))
	if role == "NEEDLE":
		draw_line(pos + Vector2(facing * 8.0, -28.0), pos + Vector2(facing * 50.0, -10.0), Color("d9bd83"), 4.0)
	elif role == "ACID_SPITTER":
		draw_circle(pos + Vector2(facing * 20.0, -32.0), 5.0, Color("b7d65b"))
	elif role == "TINY_BROOD_MOTHER":
		draw_circle(pos + Vector2(0.0, -26.0), 18.0, Color("8c6c62"), false, 4.0)


func _draw_fresh_fly(pos: Vector2, returning: bool, facing: float) -> void:
	var color := Color("a7b9a2") if returning else Color("e0b66f")
	if fresh_fly_texture:
		# The source artwork faces left, so mirror it while flying right.
		draw_set_transform(pos, 0.0, Vector2(-facing, 1.0))
		draw_texture_rect(
			fresh_fly_texture,
			Rect2(Vector2.ONE * -FRESH_FLY_DRAW_SIZE / 2.0, Vector2.ONE * FRESH_FLY_DRAW_SIZE),
			false,
			color
		)
		draw_set_transform(Vector2.ZERO)
		return
	draw_circle(pos, 7.0, color)
	draw_line(pos + Vector2(-4.0, -3.0), pos + Vector2(-11.0, -8.0), color.lightened(0.2), 2.0)
	draw_line(pos + Vector2(4.0, -3.0), pos + Vector2(11.0, -8.0), color.lightened(0.2), 2.0)


func _draw_enemy(pos: Vector2, ratio: float, primary: bool, show_health: bool = true) -> void:
	if primary and target.captured:
		draw_circle(pos+Vector2(0,-25), 22, Color("716051"))
		draw_line(pos+Vector2(-24,-15), pos+Vector2(24,15), Color("d9bd83"), 3)
		return
	var color := Color("805e63") if primary else Color("665872")
	draw_circle(pos+Vector2(0,-34), 25 if primary else 17, color)
	draw_polygon(PackedVector2Array([pos+Vector2(-29,-15),pos+Vector2(29,-15),pos+Vector2(20,24),pos+Vector2(-20,24)]), PackedColorArray([color.darkened(0.18)]))
	if show_health:
		_bar(pos+Vector2(-32,-82), Vector2(64,6), ratio, Color("b98474"), "")


func _draw_raider(pos: Vector2) -> void:
	draw_circle(pos+Vector2(0,-27), 15, Color("795868"))
	draw_polygon(PackedVector2Array([pos+Vector2(-18,-12),pos+Vector2(18,-12),pos+Vector2(15,22),pos+Vector2(-15,22)]), PackedColorArray([Color("4f414d")]))


func _draw_camp(pos: Vector2) -> void:
	draw_polygon(PackedVector2Array([pos+Vector2(-80,25),pos+Vector2(0,-75),pos+Vector2(80,25)]), PackedColorArray([Color("394449")]))
	draw_circle(pos+Vector2(0,10), 12, Color("c68a5c"))
	_text("CAMP", pos+Vector2(-25,52), 13, Color("819193"))


func _bar(pos: Vector2, size: Vector2, ratio: float, color: Color, label: String) -> void:
	draw_rect(Rect2(pos, size), Color("292f35"))
	draw_rect(Rect2(pos+Vector2(2,2), Vector2((size.x-4)*clampf(ratio,0,1), size.y-4)), color)
	if label != "": _text(label, pos+Vector2(0,-7), 11, Color("a9b2ae"))


func _title(value: String, pos: Vector2, size: int) -> void:
	_text(value, pos, size, Color("d8c190"))


func _prompt(value: String, pos: Vector2) -> void:
	_text(value, pos, 18, Color("e1c48d"))


func _text(value: String, pos: Vector2, size: int = 18, color: Color = Color("d2d5ca")) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _mark(done: bool) -> String:
	return "[done]" if done else "[waiting]"
