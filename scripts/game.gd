extends Node2D

# A dependency-free vertical slice. Geometry, animation, and UI are drawn in code
# so the prototype can be opened without importing external assets.

const VIEW := Vector2(1280.0, 720.0)
const GROUND_Y := 590.0
const WORLD_END := 2520.0
const PLAYER_SPEED := 285.0
const JUMP_SPEED := 610.0
const GRAVITY := 1650.0

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
var invulnerable := 0.0

var target := {"pos": Vector2(2050, GROUND_Y), "health": 100.0, "max_health": 100.0, "captured": false, "stun": 0.0}
var scout := {"pos": Vector2(1120, GROUND_Y), "health": 48.0, "captured": false, "active": true, "stun": 0.0}
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
var slab_message := "The prisoner is restless. Tend the Slab before departure."
var coins := 20
var result := {}
var elapsed := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
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
	squad = [
		{"pos": Vector2(115, GROUND_Y), "role": "WARD", "health": 70.0, "hold_x": 115.0},
		{"pos": Vector2(85, GROUND_Y), "role": "BINDER", "health": 65.0, "hold_x": 85.0},
		{"pos": Vector2(55, GROUND_Y), "role": "LANTERN", "health": 55.0, "hold_x": 55.0}
	]


func _process(delta: float) -> void:
	elapsed += delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
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


func _move_player(delta: float, left_bound: float, right_bound: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	player.vel.x = move_toward(player.vel.x, axis * PLAYER_SPEED, 1700.0 * delta)
	if absf(axis) > 0.1:
		player.facing = signf(axis)
	if Input.is_action_just_pressed("jump") and player.pos.y >= GROUND_Y - 0.5:
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
	_update_squad(delta)
	_update_enemy(target, delta, true)
	if scout.active:
		_update_enemy(scout, delta, false)

	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		attack_cooldown = 0.32
		_player_strike(target, 16.0)
		if scout.active: _player_strike(scout, 19.0)

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
		target.pos = target.pos.lerp(player.pos + Vector2(-55.0 * player.facing, 0), minf(1.0, delta * 5.0))
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
	if enemy.captured or player.pos.distance_to(enemy.pos) > 105.0:
		return
	if signf(enemy.pos.x - player.pos.x) != player.facing and absf(enemy.pos.x - player.pos.x) > 28.0:
		return
	enemy.health = maxf(1.0, enemy.health - damage)
	enemy.stun = 0.28
	# Contract targets are never killed by continued attacks.
	if enemy == target and enemy.health <= 1.0:
		expedition_message = "Vey is incapacitated. Further violence only burdens the journey."


func _update_enemy(enemy: Dictionary, delta: float, is_target: bool) -> void:
	if enemy.captured:
		return
	enemy.stun = maxf(0.0, enemy.stun - delta)
	if enemy.stun > 0.0:
		return
	var distance: float = enemy.pos.distance_to(player.pos)
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
		if member.health <= 0.0:
			continue
		var destination: float = member.pos.x
		match order:
			Order.FOLLOW, Order.DEFEND:
				destination = player.pos.x - player.facing * (55.0 + index * 34.0)
			Order.HOLD:
				destination = member.hold_x
			Order.ATTACK:
				destination = target.pos.x + (-45.0 + index * 35.0)
			Order.RESTRAIN:
				destination = target.pos.x + (-42.0 if index % 2 == 0 else 42.0)
			Order.RETREAT:
				destination = 150.0 + index * 34.0
		member.pos.x = move_toward(member.pos.x, destination, 215.0 * delta)
		if order == Order.ATTACK and absf(member.pos.x - target.pos.x) < 70.0 and target.health > 35.0:
			target.health = maxf(1.0, target.health - 10.0 * delta)
			target.stun = 0.08


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
	if Input.is_action_just_pressed("attack") and attack_cooldown <= 0.0:
		attack_cooldown = 0.32
		for raider in raiders:
			if raider.health > 0.0 and player.pos.distance_to(raider.pos) < 105.0:
				raider.health -= 24.0

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
		raiders.append({"pos": Vector2(1160 + index * 36, GROUND_Y), "health": 42.0, "hit": 0.0})
	slab_message = "The Mourning Choir breaches the east hall. Protect the living—and the prisoner."


func _update_emergency(delta: float) -> void:
	var living := 0
	for raider in raiders:
		if raider.health <= 0.0:
			continue
		living += 1
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

	if living == 0:
		emergency_resolved = true
		slab_message = "The breach is quiet. Take Vey east when you are ready."
	if cell_integrity <= 0.0:
		cell_integrity = 35.0
		player.health = maxf(15.0, player.health - 25.0)
		for raider in raiders:
			raider.health = 0.0
		emergency_resolved = true
		slab_message = "Vey nearly escaped. The Warden chose injury over losing the prisoner."


func _finish_prototype() -> void:
	phase = Phase.OUTCOME
	var payment: int = int(content.contract.payment) + (int(content.optional_prisoner.payment) if scout.captured else 0)
	result = {
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
	_draw_camp(Vector2(145-cam, GROUND_Y))
	if scout.active: _draw_enemy(scout.pos - Vector2(cam, 0), scout.health / 48.0, false)
	_draw_enemy(target.pos - Vector2(cam, 0), target.health / target.max_health, true)
	for member in squad: _draw_squad_member(member.pos - Vector2(cam, 0), member.role)
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
	# Brood chamber, command desk, containment cell, and east gate.
	draw_circle(Vector2(245, 480), 82, Color("4c3f3c"))
	draw_circle(Vector2(245, 478), 54, Color("8c6c62"))
	_text("BROOD", Vector2(205, 385), 15, Color("b79b8e"))
	draw_rect(Rect2(555, 510, 150, 75), Color("384147")); _text("GUARD DESK", Vector2(567, 495), 14, Color("91a0a1"))
	draw_rect(Rect2(895, 340, 150, 250), Color("252b30"), true)
	for x in range(910, 1040, 24): draw_line(Vector2(x, 350), Vector2(x, 580), Color("7a8580"), 4)
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


func _draw_hud(location: String, message: String) -> void:
	draw_rect(Rect2(0, 0, VIEW.x, 112), Color(0.045, 0.055, 0.075, 0.94))
	_text(location, Vector2(34, 34), 15, Color("83999b"))
	_text(message, Vector2(34, 74), 18, Color("d2d5ca"))
	_bar(Vector2(1020, 36), Vector2(220, 12), player.health / 100.0, Color("b96e68"), "WARDEN")


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
	draw_circle(pos + Vector2(0, -36), 17, Color("c4d5cc"))
	draw_polygon(PackedVector2Array([pos+Vector2(-20,-20), pos+Vector2(20,-20), pos+Vector2(27,22), pos+Vector2(-27,22)]), PackedColorArray([Color("526a70")]))
	draw_line(pos+Vector2(player.facing*10,-20), pos+Vector2(player.facing*39,3), Color("d8c190"), 5)


func _draw_squad_member(pos: Vector2, role: String) -> void:
	draw_circle(pos + Vector2(0,-25), 12, Color("8ca4a0"))
	draw_rect(Rect2(pos+Vector2(-14,-13), Vector2(28,35)), Color("405159"))
	_text(role.substr(0,1), pos+Vector2(-5,5), 12, Color("d9bd83"))


func _draw_enemy(pos: Vector2, ratio: float, primary: bool) -> void:
	if primary and target.captured:
		draw_circle(pos+Vector2(0,-25), 22, Color("716051"))
		draw_line(pos+Vector2(-24,-15), pos+Vector2(24,15), Color("d9bd83"), 3)
		return
	var color := Color("805e63") if primary else Color("665872")
	draw_circle(pos+Vector2(0,-34), 25 if primary else 17, color)
	draw_polygon(PackedVector2Array([pos+Vector2(-29,-15),pos+Vector2(29,-15),pos+Vector2(20,24),pos+Vector2(-20,24)]), PackedColorArray([color.darkened(0.18)]))
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
