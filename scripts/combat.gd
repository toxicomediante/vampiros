extends Control

const CombatantStateScript = preload("res://scripts/combat/combatant_state.gd")
const CombatDeckScript = preload("res://scripts/combat/combat_deck.gd")

const COMBAT_FRAME_SIZE := Vector2i(362, 644)
const IDLE_FRAME_COUNT := 6
const CHARACTER_POSITION := Vector2(520, 900)
const MAX_ENERGY := 3
const HAND_SIZE := 5
const ENERGY_FRAME_SIZE := Vector2i(384, 560)
const ENERGY_FRAME_Y := 220
const CARD_SIZE := Vector2(210, 315)
const CARD_GAP := -78.0
const CARD_Y := 748.0
const CARD_FAN_ROTATION := 6.0
const CARD_FAN_LIFT := 17.0
const PLAY_LINE_Y := 700.0

const PLAYER_HP := {
	&"juan": 72,
	&"michu": 60,
}
const ENEMY_DEFINITIONS := [
	{
		"id": &"tarantula",
		"name": "TARÁNTULA",
		"max_hp": 34,
		"damage": 6,
		"texture": preload("res://assets/enemies/tarantula.png"),
		"position": Vector2(1170, 515),
		"scale": Vector2(0.43, 0.43),
	},
	{
		"id": &"malleiro",
		"name": "VAMPIRO MALLEIRO",
		"max_hp": 30,
		"damage": 7,
		"texture": preload("res://assets/enemies/vampiro_malleiro.png"),
		"position": Vector2(1585, 500),
		"scale": Vector2(0.33, 0.33),
	},
]

const INTERIOR_BACKGROUNDS: Array[Texture2D] = [
	preload("res://assets/concepts/combat/v1/bar_interior_01_v1.png"),
	preload("res://assets/concepts/combat/v1/bar_interior_02_v1.png"),
	preload("res://assets/concepts/combat/v1/bar_interior_03_v1.png"),
]
const CHARACTER_SHEETS := {
	&"juan": preload("res://assets/characters/combat/juan_combat_idle.png"),
	&"michu": preload("res://assets/characters/combat/michu_combat_idle.png"),
}
const CARD_TEXTURES := {
	&"guantazo": preload("res://assets/cards/juan/guantazo.png"),
	&"juan_guardia": preload("res://assets/cards/juan/guardia.png"),
	&"tiriviento": preload("res://assets/cards/juan/tiriviento.png"),
	&"fresquita": preload("res://assets/cards/juan/fresquita.png"),
	&"siempre_sale_bien": preload("res://assets/cards/juan/siempre_sale_bien.png"),
	&"el_oculto": preload("res://assets/cards/juan/el_oculto.png"),
	&"mojadita": preload("res://assets/cards/michu/mojadita.png"),
	&"michu_guardia": preload("res://assets/cards/michu/guardia.png"),
	&"bocanegra": preload("res://assets/cards/michu/bocanegra.png"),
	&"petardo": preload("res://assets/cards/michu/petardo.png"),
	&"trilita": preload("res://assets/cards/michu/trilita.png"),
	&"choriza_de_jabali": preload("res://assets/cards/michu/choriza.png"),
	&"katana_escondida": preload("res://assets/cards/neutral/katana.png"),
	&"el_camino_te_camela": preload("res://assets/cards/neutral/camino.png"),
	&"la_variz": preload("res://assets/cards/neutral/variz.png"),
}
const FULLSCREEN_TEXTURE := preload("res://assets/ui/generated/fullscreen.png")
const WINDOWED_TEXTURE := preload("res://assets/ui/generated/windowed.png")
const SOUND_ON_TEXTURE := preload("res://assets/ui/generated/sound_on.png")
const SOUND_OFF_TEXTURE := preload("res://assets/ui/generated/sound_off.png")
const ENERGY_STATES_TEXTURE := preload("res://assets/ui/combat/energy_states.png")
const HP_DEF_FRAME_TEXTURE := preload("res://assets/ui/combat/hp_def_frame_approved.png")

@onready var background: TextureRect = $Background
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var enemies_root: Node2D = $Enemies
@onready var character_root: Node2D = $CombatCharacter
@onready var character_sprite: AnimatedSprite2D = $CombatCharacter/Sprite
@onready var shadow: Polygon2D = $CombatCharacter/Shadow
@onready var interface: CanvasLayer = $Interface
@onready var curtain: ColorRect = $Interface/Curtain
@onready var fullscreen_button: TextureButton = $Interface/TopControls/FullscreenButton
@onready var sound_button: TextureButton = $Interface/TopControls/SoundButton
@onready var energy_counter: TextureRect = $Interface/EnergyCounter
@onready var modal_content: Control = $Presentation/ModalContent

var sound_enabled := true
var player: CombatantState
var deck: CombatDeck
var enemies: Array[Dictionary] = []
var card_buttons: Array[TextureButton] = []
var drag_card: TextureButton
var drag_card_id: StringName
var drag_origin := Vector2.ZERO
var drag_origin_rotation := 0.0
var drag_touch_position := Vector2.ZERO
var discard_window_open := true
var combat_finished := false

var player_hp_label: Label
var player_block_label: Label
var player_hp_fill: ColorRect
var player_block_fill: ColorRect
var player_status_label: Label
var deck_label: Label
var hint_label: Label
var turn_button: Button


func _ready() -> void:
	sound_enabled = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	if background_music.stream is AudioStreamWAV:
		background_music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

	var interior_index := clampi(
		GameState.selected_combat_interior,
		0,
		INTERIOR_BACKGROUNDS.size() - 1
	)
	background.texture = INTERIOR_BACKGROUNDS[interior_index]
	_prepare_character()
	_prepare_combat_state()
	_build_enemies()
	_build_runtime_ui()
	_begin_player_turn(true)

	fullscreen_button.pressed.connect(_toggle_fullscreen)
	sound_button.pressed.connect(_toggle_sound)
	_refresh_control_icons()
	_play_scene_intro()


func _prepare_combat_state() -> void:
	var character_id := GameState.selected_character
	if not PLAYER_HP.has(character_id):
		character_id = &"michu"
	GameState.ensure_run()
	player = CombatantStateScript.new(PLAYER_HP[character_id])
	player.hp = clampi(GameState.run_hp, 1, player.max_hp)
	deck = CombatDeckScript.new()
	deck.setup(GameState.run_deck)


func _build_enemies() -> void:
	for definition: Dictionary in ENEMY_DEFINITIONS:
		var state: CombatantState = CombatantStateScript.new(definition["max_hp"])
		var sprite := Sprite2D.new()
		sprite.texture = definition["texture"]
		sprite.material = _checker_transparency_material()
		sprite.position = definition["position"]
		sprite.scale = definition["scale"]
		enemies_root.add_child(sprite)

		var enemy := {
			"id": definition["id"],
			"name": definition["name"],
			"damage": definition["damage"],
			"state": state,
			"sprite": sprite,
			"bounds": Rect2(),
			"hp_label": null,
			"status_label": null,
		}
		enemies.append(enemy)
		_update_enemy_bounds(enemies.size() - 1)


func _checker_transparency_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
void fragment() {
    vec4 c = texture(TEXTURE, UV);
    float spread = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
    bool neutral_light = spread < 0.035 && c.r > 0.58;
    COLOR = neutral_light ? vec4(c.rgb, 0.0) : c;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _build_runtime_ui() -> void:
	player_hp_fill = ColorRect.new()
	player_hp_fill.position = Vector2(222, 255)
	player_hp_fill.size = Vector2(326, 38)
	player_hp_fill.color = Color(0.62, 0.015, 0.025, 0.96)
	player_hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(player_hp_fill)

	player_block_fill = ColorRect.new()
	player_block_fill.position = Vector2(222, 307)
	player_block_fill.size = Vector2(0, 36)
	player_block_fill.color = Color(0.08, 0.25, 0.43, 0.96)
	player_block_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(player_block_fill)

	var player_frame := TextureRect.new()
	player_frame.texture = HP_DEF_FRAME_TEXTURE
	player_frame.material = _checker_transparency_material()
	player_frame.position = Vector2(24, 120)
	player_frame.size = Vector2(600, 337)
	player_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	player_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(player_frame)

	player_hp_label = _make_label(Vector2(222, 255), Vector2(326, 38), 19, Color(1.0, 0.92, 0.82))
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interface.add_child(player_hp_label)
	player_block_label = _make_label(Vector2(222, 307), Vector2(326, 36), 18, Color(0.78, 0.9, 1.0))
	player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	interface.add_child(player_block_label)
	player_status_label = _make_label(Vector2(48, 454), Vector2(550, 38), 13, Color(0.96, 0.82, 0.56))
	interface.add_child(player_status_label)

	for enemy_index in enemies.size():
		var enemy: Dictionary = enemies[enemy_index]
		var pos: Vector2 = enemy["sprite"].position
		var hp_label := _make_label(Vector2(pos.x - 180, 112), Vector2(360, 42), 19, Color(1.0, 0.86, 0.72))
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interface.add_child(hp_label)
		enemy["hp_label"] = hp_label
		var status_label := _make_label(Vector2(pos.x - 180, 154), Vector2(360, 34), 14, Color(0.88, 0.72, 0.52))
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interface.add_child(status_label)
		enemy["status_label"] = status_label

	var line := ColorRect.new()
	line.position = Vector2(365, PLAY_LINE_Y)
	line.size = Vector2(1190, 3)
	line.color = Color(0.76, 0.47, 0.18, 0.62)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(line)

	hint_label = _make_label(Vector2(575, 658), Vector2(780, 40), 16, Color(0.95, 0.82, 0.58))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.text = "ARRASTRA UNA CARTA SOBRE UN ENEMIGO O HACIA EL CENTRO"
	interface.add_child(hint_label)

	deck_label = _make_label(Vector2(26, 1025), Vector2(480, 34), 13, Color(0.83, 0.78, 0.68))
	interface.add_child(deck_label)

	turn_button = Button.new()
	turn_button.text = "FIN DE TURNO"
	turn_button.position = Vector2(1590, 938)
	turn_button.size = Vector2(290, 86)
	turn_button.add_theme_font_size_override("font_size", 22)
	turn_button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.64))
	turn_button.add_theme_color_override("font_hover_color", Color.WHITE)
	turn_button.pressed.connect(_end_player_turn)
	interface.add_child(turn_button)

	interface.move_child(curtain, interface.get_child_count() - 1)


func _make_label(position: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _begin_player_turn(first_turn := false) -> void:
	if combat_finished:
		return
	player.begin_turn()
	deck.begin_turn()
	discard_window_open = true
	deck.draw(maxi(0, HAND_SIZE - deck.hand.size()))
	set_energy(deck.energy)
	_rebuild_hand()
	_refresh_all_ui()
	hint_label.text = (
		"PRIMER TURNO · ARRASTRA UNA CARTA PARA JUGAR"
		if first_turn
		else "NUEVO TURNO · ARRASTRA UNA CARTA PARA JUGAR"
	)


func _rebuild_hand() -> void:
	for button in card_buttons:
		if is_instance_valid(button):
			button.queue_free()
	card_buttons.clear()

	var count := deck.hand.size()
	if count == 0:
		return
	var step := CARD_SIZE.x + CARD_GAP
	var center := (count - 1) / 2.0
	var start_x := 960.0 - CARD_SIZE.x / 2.0 - center * step
	for card_index in count:
		var card_id: StringName = deck.hand[card_index]
		var offset := card_index - center
		var button := TextureButton.new()
		button.texture_normal = CARD_TEXTURES[card_id]
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.clip_contents = false
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.size = CARD_SIZE
		button.pivot_offset = CARD_SIZE / 2.0
		button.position = Vector2(start_x + card_index * step, CARD_Y + absf(offset) * CARD_FAN_LIFT)
		button.rotation = deg_to_rad(offset * CARD_FAN_ROTATION)
		button.z_index = card_index
		button.tooltip_text = "%s · Coste %d" % [CardCatalog.CARDS[card_id]["name"], CardCatalog.CARDS[card_id]["cost"]]
		button.set_meta("card_id", card_id)
		button.gui_input.connect(_on_card_input.bind(button))
		interface.add_child(button)
		card_buttons.append(button)


func _start_card_drag(button: TextureButton, card_id: StringName, pointer: Vector2) -> void:
	drag_card = button
	drag_card_id = card_id
	drag_origin = button.position
	drag_origin_rotation = button.rotation
	drag_touch_position = pointer
	button.rotation = 0.0
	button.z_index = 100
	button.modulate = Color(1.08, 1.08, 1.08)


func _move_card_drag(pointer: Vector2) -> void:
	if not is_instance_valid(drag_card):
		return
	var delta := pointer - drag_touch_position
	drag_card.position += delta
	drag_touch_position = pointer
	_refresh_enemy_highlight(pointer)


func _on_card_input(event: InputEvent, button: TextureButton) -> void:
	if combat_finished:
		return
	var card_id: StringName = button.get_meta("card_id")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_card_drag(button, card_id, get_viewport().get_mouse_position())
		elif drag_card == button:
			_finish_card_drag()
		button.accept_event()
	elif event is InputEventMouseMotion and drag_card == button:
		_move_card_drag(get_viewport().get_mouse_position())
		button.accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_start_card_drag(button, card_id, event.position)
		elif drag_card == button:
			_finish_card_drag()
		button.accept_event()
	elif event is InputEventScreenDrag and drag_card == button:
		_move_card_drag(event.position)
		button.accept_event()


func _finish_card_drag() -> void:
	if not is_instance_valid(drag_card):
		return
	var drop_position := get_viewport().get_mouse_position()
	var card_data: Dictionary = CardCatalog.CARDS[drag_card_id]
	var target_index := _enemy_at(drop_position)
	var valid_drop := false
	if card_data["target"] == CardCatalog.Target.ONE_ENEMY:
		valid_drop = target_index >= 0
	else:
		valid_drop = drop_position.y < PLAY_LINE_Y

	if valid_drop and _try_play_card(drag_card_id, target_index):
		drag_card = null
		drag_card_id = &""
		_clear_enemy_highlight()
		return

	drag_card.position = drag_origin
	drag_card.rotation = drag_origin_rotation
	drag_card.z_index = card_buttons.find(drag_card)
	drag_card.modulate = Color.WHITE
	drag_card = null
	drag_card_id = &""
	_clear_enemy_highlight()


func _try_play_card(card_id: StringName, target_index: int) -> bool:
	var card_data: Dictionary = CardCatalog.CARDS[card_id]
	var cost: int = card_data["cost"]
	if not deck.can_pay(cost):
		hint_label.text = "NO TIENES ENERGÍA SUFICIENTE"
		return false
	if target_index >= 0 and not _enemy_is_alive(target_index):
		return false

	deck.pay(cost)
	set_energy(deck.energy)
	discard_window_open = false
	_resolve_card(card_data, target_index)
	deck.discard(card_id)
	hint_label.text = "%s JUGADA" % card_data["name"]
	_remove_dead_enemies()
	if _all_enemies_dead():
		_finish_combat(true)
	else:
		_rebuild_hand()
		_refresh_all_ui()
	return true


func _resolve_card(card_data: Dictionary, target_index: int) -> void:
	for effect: Dictionary in card_data["effects"]:
		match effect["type"]:
			&"damage":
				if card_data["target"] == CardCatalog.Target.ALL_ENEMIES:
					for enemy_index in enemies.size():
						if _enemy_is_alive(enemy_index):
							_enemy_state(enemy_index).receive_attack(effect["amount"], player.strength)
				elif target_index >= 0:
					_enemy_state(target_index).receive_attack(effect["amount"], player.strength)
			&"block":
				player.block += effect["amount"]
			&"poison":
				if target_index >= 0:
					_enemy_state(target_index).poison += effect["amount"]
				else:
					player.poison += effect["amount"]
			&"vulnerable":
				_enemy_state(target_index).vulnerable += effect["amount"]
			&"heal":
				player.heal(effect["amount"])
			&"regeneration":
				player.regeneration += effect["amount"]
			&"strength":
				player.strength += effect["amount"]
			&"autodefense":
				player.autodefense += effect["amount"]
			&"double_poison":
				_enemy_state(target_index).poison *= 2
			&"self_damage":
				player.receive_blockable_damage(effect["amount"])


func _end_player_turn() -> void:
	if combat_finished or drag_card != null:
		return
	turn_button.disabled = true
	discard_window_open = false
	player.apply_end_of_turn_statuses()
	player.finish_turn()
	_refresh_all_ui()
	if player.hp <= 0:
		_finish_combat(false)
		return

	for enemy_index in enemies.size():
		if not _enemy_is_alive(enemy_index):
			continue
		var sprite: Sprite2D = enemies[enemy_index]["sprite"]
		var original_position := sprite.position
		var attack_tween := create_tween()
		attack_tween.tween_property(sprite, "position:x", original_position.x - 42.0, 0.10)
		attack_tween.tween_property(sprite, "position:x", original_position.x, 0.16)
		await attack_tween.finished
		player.receive_attack(enemies[enemy_index]["damage"])
		var state := _enemy_state(enemy_index)
		state.apply_end_of_turn_statuses()
		state.finish_turn()
		_refresh_all_ui()
		_remove_dead_enemies()
		if player.hp <= 0:
			_finish_combat(false)
			return
		if _all_enemies_dead():
			_finish_combat(true)
			return

	await get_tree().create_timer(0.25).timeout
	turn_button.disabled = false
	_begin_player_turn()


func _enemy_state(index: int) -> CombatantState:
	return enemies[index]["state"]


func _enemy_is_alive(index: int) -> bool:
	return _enemy_state(index).hp > 0


func _enemy_at(point: Vector2) -> int:
	for enemy_index in enemies.size():
		if _enemy_is_alive(enemy_index) and enemies[enemy_index]["bounds"].has_point(point):
			return enemy_index
	return -1


func _update_enemy_bounds(index: int) -> void:
	var sprite: Sprite2D = enemies[index]["sprite"]
	var rendered_size := Vector2(sprite.texture.get_size()) * sprite.scale
	enemies[index]["bounds"] = Rect2(sprite.position - rendered_size / 2.0, rendered_size)


func _refresh_enemy_highlight(point: Vector2) -> void:
	var selected := _enemy_at(point)
	for enemy_index in enemies.size():
		var sprite: Sprite2D = enemies[enemy_index]["sprite"]
		sprite.modulate = (
			Color(1.35, 1.14, 0.72)
			if enemy_index == selected
			else Color.WHITE
		)


func _clear_enemy_highlight() -> void:
	for enemy: Dictionary in enemies:
		var sprite: Sprite2D = enemy["sprite"]
		sprite.modulate = Color.WHITE


func _remove_dead_enemies() -> void:
	for enemy: Dictionary in enemies:
		var state: CombatantState = enemy["state"]
		if state.hp <= 0:
			var sprite: Sprite2D = enemy["sprite"]
			sprite.visible = false


func _all_enemies_dead() -> bool:
	for enemy_index in enemies.size():
		if _enemy_is_alive(enemy_index):
			return false
	return true


func _refresh_all_ui() -> void:
	player_hp_label.text = "HP  %d / %d" % [player.hp, player.max_hp]
	player_block_label.text = "DEF  %d" % player.block
	player_hp_fill.size.x = 326.0 * clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)
	player_block_fill.size.x = 326.0 * clampf(float(player.block) / 20.0, 0.0, 1.0)
	player_status_label.text = _status_text(player)
	deck_label.text = "MAZO %d   DESCARTE %d   MANO %d" % [
		deck.draw_pile.size(),
		deck.discard_pile.size(),
		deck.hand.size(),
	]
	for enemy: Dictionary in enemies:
		var state: CombatantState = enemy["state"]
		var hp_label: Label = enemy["hp_label"]
		var status_label: Label = enemy["status_label"]
		hp_label.text = "%s   HP %d/%d" % [enemy["name"], state.hp, state.max_hp]
		status_label.text = _status_text(state)


func _status_text(state: CombatantState) -> String:
	var parts: Array[String] = []
	if state.block > 0:
		parts.append("DEF %d" % state.block)
	if state.poison > 0:
		parts.append("VENENO %d" % state.poison)
	if state.regeneration > 0:
		parts.append("REGENERACIÓN %d" % state.regeneration)
	if state.vulnerable > 0:
		parts.append("VULNERABLE %d" % state.vulnerable)
	if state.strength > 0:
		parts.append("FUERZA %d" % state.strength)
	if state.autodefense > 0:
		parts.append("AUTODEFENSA %d" % state.autodefense)
	return " · ".join(parts) if not parts.is_empty() else "SIN ESTADOS"


func set_energy(value: int) -> void:
	deck.energy = clampi(value, 0, MAX_ENERGY)
	var atlas := AtlasTexture.new()
	atlas.atlas = ENERGY_STATES_TEXTURE
	atlas.region = Rect2i(
		(MAX_ENERGY - deck.energy) * ENERGY_FRAME_SIZE.x,
		ENERGY_FRAME_Y,
		ENERGY_FRAME_SIZE.x,
		ENERGY_FRAME_SIZE.y
	)
	energy_counter.texture = atlas
	energy_counter.visible = true


func _finish_combat(victory: bool) -> void:
	combat_finished = true
	if victory:
		GameState.run_hp = player.hp
	turn_button.disabled = true
	for button in card_buttons:
		button.disabled = true
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.015, 0.008, 0.02, 0.82)
	modal_content.add_child(shade)
	var result := _make_label(
		Vector2(420, 310), Vector2(1080, 150), 58,
		Color(0.95, 0.72, 0.32) if victory else Color(0.9, 0.22, 0.19)
	)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.text = "COMBATE GANADO" if victory else "HAS CAÍDO"
	modal_content.add_child(result)
	if victory:
		_build_reward_offer()
	else:
		var detail := _make_label(
			Vector2(500, 470), Vector2(920, 90), 19, Color(0.92, 0.86, 0.78)
		)
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.text = "VUELVE AL MAPA PARA INTENTARLO DE NUEVO"
		modal_content.add_child(detail)
		_add_return_button("VOLVER AL MAPA", Vector2(760, 610))


func _build_reward_offer() -> void:
	var reward_title := _make_label(
		Vector2(500, 452), Vector2(920, 45), 18, Color(0.92, 0.86, 0.78)
	)
	reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_title.text = "ELIGE UNA CARTA O RECHAZA LA RECOMPENSA"
	modal_content.add_child(reward_title)
	var reward := RewardGenerator.generate(GameState.selected_character)
	var start_x := 390.0
	for reward_index in reward.size():
		var card_id: StringName = reward[reward_index]
		var card_data: Dictionary = CardCatalog.CARDS[card_id]
		var choice := Button.new()
		choice.text = "%s\nCOSTE %d" % [card_data["name"], card_data["cost"]]
		choice.position = Vector2(start_x + reward_index * 390.0, 530)
		choice.size = Vector2(360, 150)
		choice.add_theme_font_size_override("font_size", 17)
		choice.add_theme_color_override("font_color", Color(0.98, 0.82, 0.57))
		choice.pressed.connect(_choose_reward.bind(card_id))
		modal_content.add_child(choice)
	_add_return_button("OMITIR", Vector2(760, 735))


func _choose_reward(card_id: StringName) -> void:
	GameState.add_reward_card(card_id)
	hint_label.text = "RECOMPENSA ELEGIDA: %s" % CardCatalog.CARDS[card_id]["name"]
	get_tree().change_scene_to_file("res://scenes/overworld.tscn")


func _add_return_button(text: String, position: Vector2) -> void:
	var continue_button := Button.new()
	continue_button.text = text
	continue_button.position = position
	continue_button.size = Vector2(400, 84)
	continue_button.add_theme_font_size_override("font_size", 22)
	continue_button.pressed.connect(
		func(): get_tree().change_scene_to_file("res://scenes/overworld.tscn")
	)
	modal_content.add_child(continue_button)


func _prepare_character() -> void:
	var character_id: StringName = GameState.selected_character
	if not CHARACTER_SHEETS.has(character_id):
		character_id = &"michu"
	var sheet: Texture2D = CHARACTER_SHEETS[character_id]
	character_sprite.sprite_frames = _build_idle_frames(sheet, character_id)
	character_sprite.position = Vector2(0, -COMBAT_FRAME_SIZE.y / 2.0)
	character_root.position = CHARACTER_POSITION
	character_root.scale = Vector2.ONE * (1.13 if character_id == &"michu" else 1.19)
	shadow.scale = Vector2(0.90, 0.82) if character_id == &"michu" else Vector2(1.12, 0.92)
	character_sprite.play(&"idle")


func _build_idle_frames(sheet: Texture2D, character_id: StringName) -> SpriteFrames:
	assert(sheet.get_width() == COMBAT_FRAME_SIZE.x * IDLE_FRAME_COUNT)
	assert(sheet.get_height() == COMBAT_FRAME_SIZE.y)
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 4.0 if character_id == &"michu" else 3.5)
	for frame_index in IDLE_FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2i(
			frame_index * COMBAT_FRAME_SIZE.x,
			0,
			COMBAT_FRAME_SIZE.x,
			COMBAT_FRAME_SIZE.y
		)
		frames.add_frame(&"idle", atlas)
	return frames


func _play_scene_intro() -> void:
	curtain.color.a = 1.0
	character_root.modulate.a = 0.0
	enemies_root.modulate.a = 0.0
	var reveal := create_tween().set_parallel(true)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(curtain, "color:a", 0.0, 0.65)
	reveal.tween_property(character_root, "modulate:a", 1.0, 0.48).set_delay(0.18)
	reveal.tween_property(enemies_root, "modulate:a", 1.0, 0.48).set_delay(0.28)


func _toggle_fullscreen() -> void:
	var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	await get_tree().process_frame
	_refresh_control_icons()


func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not sound_enabled)
	background_music.stream_paused = not sound_enabled
	if sound_enabled and not background_music.playing:
		background_music.play()
	_refresh_control_icons()


func _refresh_control_icons() -> void:
	var is_fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_button.texture_normal = WINDOWED_TEXTURE if is_fullscreen else FULLSCREEN_TEXTURE
	fullscreen_button.tooltip_text = (
		"SALIR DE PANTALLA COMPLETA" if is_fullscreen else "PANTALLA COMPLETA"
	)
	sound_button.texture_normal = SOUND_ON_TEXTURE if sound_enabled else SOUND_OFF_TEXTURE
	sound_button.tooltip_text = "DESACTIVAR SONIDO" if sound_enabled else "ACTIVAR SONIDO"
