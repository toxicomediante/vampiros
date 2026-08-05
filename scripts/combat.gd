extends Control

const CombatantStateScript = preload("res://scripts/combat/combatant_state.gd")
const CombatDeckScript = preload("res://scripts/combat/combat_deck.gd")
const EnemyCatalogScript = preload("res://scripts/enemies/enemy_catalog.gd")

const COMBAT_FRAME_SIZE := Vector2i(362, 644)
const IDLE_FRAME_COUNT := 6
const BACKGROUND_SOURCE_SIZE := Vector2(1672, 941)
const COMBAT_VIEWPORT_SIZE := Vector2(1920, 1080)
const COMBAT_NUMBER_FONT := preload(
	"res://assets/fonts/press-start-2p-latin-400-normal.woff2"
)
const COMBAT_NUMBER_NORMAL_COLOR := Color(1.0, 1.0, 1.0)
const COMBAT_NUMBER_STATUS_COLOR := Color(0.38, 1.0, 0.34)
const COMBAT_NUMBER_SIZE := Vector2(280.0, 104.0)
const COMBAT_NUMBER_FONT_SIZE := 52
const MAX_ENERGY := 3
const HAND_SIZE := 5
const ENERGY_FRAME_SIZE := Vector2i(256, 373)
const ENERGY_FRAME_Y := 0
const CARD_SIZE := Vector2(210, 315)
const CARD_GAP := -78.0
const CARD_Y := 748.0
const CARD_FAN_ROTATION := 6.0
const CARD_FAN_LIFT := 17.0
const CARD_FOCUS_SCALE := Vector2(1.62, 1.62)
const CARD_FOCUS_LIFT := 18.0
const CARD_FOCUS_DURATION := 0.16
const CARD_RETURN_DURATION := 0.13
const CARD_FOCUS_Z_INDEX := 90
const CARD_DRAG_THRESHOLD := 14.0
const CARD_DRAG_SCALE := Vector2(1.12, 1.12)
const PLAY_LINE_Y := 700.0
const MAX_BLOCK_DISPLAY := 20.0
const PLAYER_UI_POSITION := Vector2(24.0, 140.0)
const PLAYER_UI_SIZE := Vector2(560.0, 112.0)
const PLAYER_HP_BAR_POSITION := Vector2(42.0, 13.0)
const PLAYER_HP_BAR_SIZE := Vector2(480.0, 36.0)
const PLAYER_DEF_BAR_POSITION := Vector2(42.0, 62.0)
const PLAYER_DEF_BAR_SIZE := Vector2(480.0, 36.0)
const PLAYER_HUD_VERTICAL_OFFSETS := [0.0, -1.0, 0.0, 3.0, 1.5, -0.5]
const PLAYER_HP_BAR_COLOR := Color(0.78, 0.08, 0.12, 1.0)
const PLAYER_BLOCK_BAR_COLOR := Color(0.34, 0.47, 0.60, 1.0)
const PLAYER_BAR_BACKGROUND_COLOR := Color(0.035, 0.03, 0.045, 0.96)
const PLAYER_BAR_HIGHLIGHT_COLOR := Color(1.0, 1.0, 1.0, 0.16)
const DISCARD_BUTTON_POSITION := Vector2(1497.0, 976.0)
const DISCARD_BUTTON_SIZE := Vector2(420.0, 104.0)
const TURN_BUTTON_POSITION := Vector2(1653.0, 721.0)
const TURN_BUTTON_SIZE := Vector2(256.0, 256.0)
const ACTION_BUTTON_HOVER_SCALE := Vector2(1.035, 1.035)
const ACTION_BUTTON_PRESSED_SCALE := Vector2(0.955, 0.955)
const REWARD_MAT_PATH := "res://assets/ui/combat/reward_mat.png"
const REWARD_MAT_POSITION := Vector2(128.0, 72.0)
const REWARD_MAT_SIZE := Vector2(1664.0, 936.0)
const REWARD_CARD_SIZE := Vector2(296.0, 444.0)
const REWARD_CARD_Y := 320.0
const REWARD_CARD_X_POSITIONS := [405.0, 812.0, 1219.0]
const REWARD_CARD_HOVER_SCALE := Vector2(1.065, 1.065)
const REWARD_SKIP_BUTTON_POSITION := Vector2(750.0, 790.0)
const REWARD_SKIP_BUTTON_SIZE := Vector2(420.0, 104.0)

const PLAYER_HP := {
	&"juan": 72,
	&"michu": 60,
}
const ENEMY_DEFINITIONS := EnemyCatalogScript.ENEMIES


const INTERIOR_BACKGROUND_PATHS: Array[String] = [
	"res://assets/backgrounds/combat/bar_interior_01.png",
	"res://assets/backgrounds/combat/bar_interior_02.png",
	"res://assets/backgrounds/combat/bar_interior_03.png",
]
const INTERIOR_LAYOUTS := [
	{
		"player_feet": Vector2(560, 960),
		"solo_enemy_feet": Vector2(1350, 720),
		"pair_enemy_feet": [Vector2(1120, 690), Vector2(1570, 760)],
		"enemy_feet": {
			&"tarantula": Vector2(1120, 690),
			&"malleiro": Vector2(1570, 760),
		},
		"foreground_path": "res://assets/backgrounds/combat/bar_foreground_01.png",
		"foreground_source_rect": Rect2(0, 542, 430, 399),
	},
	{
		"player_feet": Vector2(530, 975),
		"solo_enemy_feet": Vector2(1300, 800),
		"pair_enemy_feet": [Vector2(1080, 800), Vector2(1500, 800)],
		"enemy_feet": {
			&"tarantula": Vector2(1080, 800),
			&"malleiro": Vector2(1500, 800),
		},
		"foreground_path": "res://assets/backgrounds/combat/bar_foreground_02.png",
		"foreground_source_rect": Rect2(0, 692, 349, 249),
	},
	{
		"player_feet": Vector2(650, 950),
		"solo_enemy_feet": Vector2(1270, 690),
		"pair_enemy_feet": [Vector2(1050, 650), Vector2(1450, 690)],
		"enemy_feet": {
			&"tarantula": Vector2(1050, 650),
			&"malleiro": Vector2(1450, 690),
		},
		"foreground_path": "",
		"foreground_source_rect": Rect2(),
	},
]
const CHARACTER_SHEET_PATHS := {
	&"juan": "res://assets/characters/combat/juan_combat_idle.png",
	&"michu": "res://assets/characters/combat/michu_combat_idle.png",
}
const CARD_TEXTURE_PATHS := {
	&"guantazo": "res://assets/cards/juan/guantazo.png",
	&"juan_guardia": "res://assets/cards/juan/guardia.png",
	&"tiriviento": "res://assets/cards/juan/tiriviento.png",
	&"fresquita": "res://assets/cards/juan/fresquita.png",
	&"siempre_sale_bien": "res://assets/cards/juan/siempre_sale_bien.png",
	&"el_oculto": "res://assets/cards/juan/el_oculto.png",
	&"mojadita": "res://assets/cards/michu/mojadita.png",
	&"michu_guardia": "res://assets/cards/michu/guardia.png",
	&"bocanegra": "res://assets/cards/michu/bocanegra.png",
	&"petardo": "res://assets/cards/michu/petardo.png",
	&"trilita": "res://assets/cards/michu/trilita.png",
	&"choriza_de_jabali": "res://assets/cards/michu/choriza.png",
	&"katana_escondida": "res://assets/cards/neutral/katana.png",
	&"el_camino_te_camela": "res://assets/cards/neutral/camino.png",
	&"la_variz": "res://assets/cards/neutral/variz.png",
}
const FULLSCREEN_TEXTURE := preload("res://assets/ui/generated/fullscreen.png")
const WINDOWED_TEXTURE := preload("res://assets/ui/generated/windowed.png")
const SOUND_ON_TEXTURE := preload("res://assets/ui/generated/sound_on.png")
const SOUND_OFF_TEXTURE := preload("res://assets/ui/generated/sound_off.png")
const ENERGY_STATES_PATH := "res://assets/ui/combat/energy_states.png"
const HP_DEF_FRAME_PATH := "res://assets/ui/combat/hp_def_frame.png"
const DISCARD_BUTTON_TEXTURE := preload(
	"res://assets/ui/combat/boton_descartar.png"
)
const TURN_BUTTON_TEXTURE := preload(
	"res://assets/ui/combat/boton_fin_turno.png"
)
const REWARD_SKIP_BUTTON_TEXTURE := preload(
	"res://assets/ui/combat/boton_omitir.png"
)

@onready var background: TextureRect = $Background
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var enemies_root: Node2D = $Enemies
@onready var character_root: Node2D = $CombatCharacter
@onready var character_sprite: AnimatedSprite2D = $CombatCharacter/Sprite
@onready var shadow: Polygon2D = $CombatCharacter/Shadow
@onready var foreground: TextureRect = $Foreground
@onready var interface: CanvasLayer = $Interface
@onready var curtain: ColorRect = $Interface/Curtain
@onready var fullscreen_button: TextureButton = $Interface/TopControls/FullscreenButton
@onready var sound_button: TextureButton = $Interface/TopControls/SoundButton
@onready var energy_counter: TextureRect = $Interface/EnergyCounter
@onready var combat_numbers: Control = $Interface/CombatNumbers
@onready var modal_content: Control = $Presentation/ModalContent

var sound_enabled := true
var player: CombatantState
var deck: CombatDeck
var enemies: Array[Dictionary] = []
var card_buttons: Array[TextureButton] = []
var card_texture_cache := {}
var card_motion_tweens := {}
var action_button_tweens := {}
var reward_card_tweens := {}
var energy_states_texture: Texture2D
var drag_card: TextureButton
var drag_card_id: StringName
var drag_pointer_position := Vector2.ZERO
var drag_grab_local := Vector2.ZERO
var pressed_card: TextureButton
var pressed_card_id: StringName
var pressed_pointer_position := Vector2.ZERO
var pressed_pointer_index := -1
var hovered_card: TextureButton
var selected_card: TextureButton
var discard_window_open := true
var discard_mode := false
var combat_finished := false
var interior_index := 0

var player_hp_label: Label
var player_block_label: Label
var player_hp_background: ColorRect
var player_block_background: ColorRect
var player_hp_clip: Control
var player_block_clip: Control
var player_status_label: Label
var player_hud: Control
var player_hud_base_position := PLAYER_UI_POSITION
var deck_label: Label
var hint_label: Label
var discard_button: TextureButton
var turn_button: TextureButton


func _ready() -> void:
	sound_enabled = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	_configure_music_loop()
	if not background_music.playing:
		background_music.play()

	interior_index = clampi(
		GameState.selected_combat_interior,
		0,
		INTERIOR_BACKGROUND_PATHS.size() - 1
	)
	background.texture = _load_texture(INTERIOR_BACKGROUND_PATHS[interior_index])
	_configure_foreground()
	_prepare_character()
	_prepare_combat_state()
	_build_enemies()
	_build_runtime_ui()
	_begin_player_turn(true)

	fullscreen_button.pressed.connect(_toggle_fullscreen)
	sound_button.pressed.connect(_toggle_sound)
	_refresh_control_icons()
	_play_scene_intro()


func _process(delta: float) -> void:
	_sync_player_hud_motion(delta)


func _exit_tree() -> void:
	if background_music != null:
		background_music.stop()
		background_music.stream = null
	for enemy: Dictionary in enemies:
		var sprite := enemy.get("sprite") as Sprite2D
		if is_instance_valid(sprite):
			sprite.texture = null
	card_texture_cache.clear()
	energy_states_texture = null


func _configure_music_loop() -> void:
	var ogg_stream := background_music.stream as AudioStreamOggVorbis
	if ogg_stream != null:
		ogg_stream.loop = true
		return
	var wav_stream := background_music.stream as AudioStreamWAV
	if wav_stream != null:
		wav_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD


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
	var selected_enemy_ids: Array[StringName] = (
		GameState.pending_encounter.duplicate()
	)
	if selected_enemy_ids.is_empty():
		selected_enemy_ids = EnemyCatalogScript.generate_encounter(
			maxi(GameState.current_route_step + 1, 0),
			GameState.run_seed,
			GameState.route_node_id(
				maxi(GameState.current_route_step + 1, 0),
				maxi(GameState.pending_route_branch, 0)
			)
		)
		GameState.set_pending_encounter(selected_enemy_ids)

	var layout: Dictionary = INTERIOR_LAYOUTS[interior_index]
	for enemy_index in selected_enemy_ids.size():
		var enemy_id: StringName = selected_enemy_ids[enemy_index]
		if not ENEMY_DEFINITIONS.has(enemy_id):
			push_error("Enemigo desconocido: %s" % enemy_id)
			continue

		var definition: Dictionary = ENEMY_DEFINITIONS[enemy_id]
		var state: CombatantState = CombatantStateScript.new(
			definition["max_hp"]
		)
		var sprite := Sprite2D.new()
		sprite.texture = _load_texture(definition["texture_path"])
		if sprite.texture == null:
			continue
		sprite.scale = definition["scale"]

		var feet_position: Vector2 = layout["solo_enemy_feet"]
		if selected_enemy_ids.size() > 1:
			var pair_slots: Array = layout["pair_enemy_feet"]
			feet_position = pair_slots[
				mini(enemy_index, pair_slots.size() - 1)
			]
		sprite.position = _center_sprite_on_feet(
			sprite.texture,
			sprite.scale,
			definition["visible_bottom"],
			feet_position
		)
		enemies_root.add_child(sprite)

		var enemy := {
			"id": definition["id"],
			"name": definition["name"],
			"damage": definition["damage"],
			"currency": definition["currency"],
			"state": state,
			"sprite": sprite,
			"bounds": Rect2(),
			"hp_label": null,
			"status_label": null,
		}
		enemies.append(enemy)
		_update_enemy_bounds(enemies.size() - 1)

	if enemies.is_empty():
		push_error("El encuentro no contiene enemigos cargables")
func _configure_foreground() -> void:
	var layout: Dictionary = INTERIOR_LAYOUTS[interior_index]
	var foreground_path: String = layout["foreground_path"]
	if foreground_path.is_empty():
		foreground.texture = null
		foreground.visible = false
		return
	var source_rect: Rect2 = layout["foreground_source_rect"]
	var source_to_viewport := COMBAT_VIEWPORT_SIZE / BACKGROUND_SOURCE_SIZE
	foreground.position = source_rect.position * source_to_viewport
	foreground.size = source_rect.size * source_to_viewport
	foreground.texture = _load_texture(foreground_path)
	foreground.visible = foreground.texture != null


func _center_sprite_on_feet(
	texture: Texture2D,
	sprite_scale: Vector2,
	visible_bottom: float,
	feet_position: Vector2
) -> Vector2:
	return feet_position - Vector2(
		0.0,
		(visible_bottom - texture.get_height() * 0.5) * sprite_scale.y
	)


func _build_runtime_ui() -> void:
	var hp_def_frame := _load_texture(HP_DEF_FRAME_PATH)
	energy_states_texture = _load_texture(ENERGY_STATES_PATH)
	if (
		hp_def_frame == null
		or energy_states_texture == null
	):
		push_error("No se pudo cargar la interfaz de combate")
		return

	player_hud = Control.new()
	player_hud.name = "PlayerHUD"
	player_hud_base_position = PLAYER_UI_POSITION
	player_hud.position = player_hud_base_position
	player_hud.size = PLAYER_UI_SIZE
	player_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(player_hud)

	player_hp_background = _make_bar_background(
		"PlayerHPBackground",
		PLAYER_HP_BAR_POSITION,
		PLAYER_HP_BAR_SIZE
	)
	player_hud.add_child(player_hp_background)
	player_block_background = _make_bar_background(
		"PlayerBlockBackground",
		PLAYER_DEF_BAR_POSITION,
		PLAYER_DEF_BAR_SIZE
	)
	player_hud.add_child(player_block_background)

	player_hp_clip = _make_color_bar_clip(
		"PlayerHPBar",
		PLAYER_HP_BAR_POSITION,
		PLAYER_HP_BAR_SIZE,
		PLAYER_HP_BAR_COLOR
	)
	player_hud.add_child(player_hp_clip)
	player_block_clip = _make_color_bar_clip(
		"PlayerBlockBar",
		PLAYER_DEF_BAR_POSITION,
		PLAYER_DEF_BAR_SIZE,
		PLAYER_BLOCK_BAR_COLOR
	)
	player_hud.add_child(player_block_clip)

	var player_frame := _make_texture_rect(
		hp_def_frame,
		Vector2.ZERO,
		PLAYER_UI_SIZE
	)
	player_hud.add_child(player_frame)

	player_hp_label = _make_label(
		PLAYER_HP_BAR_POSITION,
		PLAYER_HP_BAR_SIZE,
		16,
		Color(1.0, 0.92, 0.82)
	)
	player_hp_label.name = "PlayerHPValue"
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_configure_bar_value_label(player_hp_label)
	player_hud.add_child(player_hp_label)
	player_block_label = _make_label(
		PLAYER_DEF_BAR_POSITION,
		PLAYER_DEF_BAR_SIZE,
		16,
		Color(0.78, 0.9, 1.0)
	)
	player_block_label.name = "PlayerBlockValue"
	player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_configure_bar_value_label(player_block_label)
	player_hud.add_child(player_block_label)
	player_status_label = _make_label(
		Vector2(28, PLAYER_UI_SIZE.y + 6),
		Vector2(PLAYER_UI_SIZE.x, 30),
		12,
		Color(0.96, 0.82, 0.56)
	)
	player_hud.add_child(player_status_label)

	for enemy_index in enemies.size():
		var enemy: Dictionary = enemies[enemy_index]
		var pos: Vector2 = enemy["sprite"].position
		var hp_label := _make_label(
			Vector2(pos.x - 180, 112),
			Vector2(360, 42),
			19,
			Color(1.0, 0.86, 0.72)
		)
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interface.add_child(hp_label)
		enemy["hp_label"] = hp_label
		var status_label := _make_label(
			Vector2(pos.x - 180, 154),
			Vector2(360, 34),
			14,
			Color(0.88, 0.72, 0.52)
		)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		interface.add_child(status_label)
		enemy["status_label"] = status_label

	var line := ColorRect.new()
	line.position = Vector2(365, PLAY_LINE_Y)
	line.size = Vector2(1190, 3)
	line.color = Color(0.76, 0.47, 0.18, 0.62)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(line)

	hint_label = _make_label(
		Vector2(575, 658), Vector2(780, 40), 16, Color(0.95, 0.82, 0.58)
	)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.text = "ARRASTRA UNA CARTA SOBRE UN ENEMIGO O HACIA EL CENTRO"
	interface.add_child(hint_label)

	deck_label = _make_label(
		Vector2(26, 1025), Vector2(480, 34), 13, Color(0.83, 0.78, 0.68)
	)
	interface.add_child(deck_label)

	discard_button = _make_action_texture_button(
		"DiscardButton",
		DISCARD_BUTTON_TEXTURE,
		DISCARD_BUTTON_POSITION,
		DISCARD_BUTTON_SIZE,
		"DESCARTAR CARTA"
	)
	discard_button.toggle_mode = true
	discard_button.toggled.connect(_toggle_discard_mode)
	interface.add_child(discard_button)

	turn_button = _make_action_texture_button(
		"EndTurnButton",
		TURN_BUTTON_TEXTURE,
		TURN_BUTTON_POSITION,
		TURN_BUTTON_SIZE,
		"FIN DE TURNO"
	)
	turn_button.pressed.connect(_end_player_turn)
	interface.add_child(turn_button)

	interface.move_child(curtain, interface.get_child_count() - 1)


func _make_action_texture_button(
	node_name: String,
	texture: Texture2D,
	position: Vector2,
	size: Vector2,
	tooltip: String
) -> TextureButton:
	var button := TextureButton.new()
	button.name = node_name
	button.position = position
	button.size = size
	button.pivot_offset = size * 0.5
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.texture_disabled = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = tooltip
	button.set_meta("pointer_hovered", false)
	button.set_meta("pointer_down", false)
	button.mouse_entered.connect(_set_action_button_hovered.bind(button, true))
	button.mouse_exited.connect(_set_action_button_hovered.bind(button, false))
	button.button_down.connect(_set_action_button_pressed.bind(button, true))
	button.button_up.connect(_set_action_button_pressed.bind(button, false))
	return button


func _set_action_button_hovered(button: TextureButton, hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	button.set_meta("pointer_hovered", hovered)
	_refresh_action_button_visual(button)


func _set_action_button_pressed(button: TextureButton, pressed: bool) -> void:
	if not is_instance_valid(button):
		return
	button.set_meta("pointer_down", pressed)
	_refresh_action_button_visual(button)


func _refresh_action_button_visual(button: TextureButton) -> void:
	if not is_instance_valid(button):
		return
	var target_scale := Vector2.ONE
	var target_modulate := Color.WHITE
	if button.disabled:
		target_scale = Vector2(0.98, 0.98)
		target_modulate = Color(0.48, 0.48, 0.48, 0.72)
	elif bool(button.get_meta("pointer_down", false)):
		target_scale = ACTION_BUTTON_PRESSED_SCALE
		target_modulate = Color(1.15, 0.86, 0.72)
	elif button.toggle_mode and button.button_pressed:
		target_scale = ACTION_BUTTON_HOVER_SCALE
		target_modulate = Color(1.18, 0.80, 0.68)
	elif bool(button.get_meta("pointer_hovered", false)):
		target_scale = ACTION_BUTTON_HOVER_SCALE
		target_modulate = Color(1.12, 1.06, 0.94)

	var motion_key := button.get_instance_id()
	var previous := action_button_tweens.get(motion_key) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	var motion := create_tween().set_parallel(true)
	motion.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	motion.tween_property(button, "scale", target_scale, 0.10)
	motion.tween_property(button, "modulate", target_modulate, 0.10)
	action_button_tweens[motion_key] = motion


func _sync_player_hud_motion(delta: float) -> void:
	if not is_instance_valid(player_hud) or not is_instance_valid(character_sprite):
		return
	var vertical_offset := _interpolated_hud_vertical_offset(
		PLAYER_HUD_VERTICAL_OFFSETS
	)
	var smoothing := 1.0 - exp(-delta * 18.0)
	player_hud.position.x = player_hud_base_position.x
	player_hud.position.y = lerpf(
		player_hud.position.y,
		player_hud_base_position.y + vertical_offset,
		smoothing
	)


func _interpolated_hud_vertical_offset(offsets: Array) -> float:
	if offsets.is_empty() or not is_instance_valid(character_sprite):
		return 0.0
	var frame_index := posmod(character_sprite.frame, offsets.size())
	var next_frame_index := (frame_index + 1) % offsets.size()
	var progress := clampf(character_sprite.get_frame_progress(), 0.0, 1.0)
	var eased_progress := progress * progress * (3.0 - 2.0 * progress)
	return lerpf(
		float(offsets[frame_index]),
		float(offsets[next_frame_index]),
		eased_progress
	)


func _make_texture_rect(
	texture: Texture2D,
	position: Vector2,
	size: Vector2,
	stretch_mode := TextureRect.STRETCH_SCALE
) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = texture
	texture_rect.position = position
	texture_rect.size = size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = stretch_mode
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _make_bar_background(
	node_name: String,
	position: Vector2,
	size: Vector2
) -> ColorRect:
	var background := ColorRect.new()
	background.name = node_name
	background.position = position
	background.size = size
	background.color = PLAYER_BAR_BACKGROUND_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return background


func _make_color_bar_clip(
	node_name: String,
	position: Vector2,
	size: Vector2,
	fill_color: Color
) -> Control:
	var clip := Control.new()
	clip.name = node_name
	clip.position = position
	clip.size = size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.size = size
	fill.color = fill_color
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(fill)
	var highlight := ColorRect.new()
	highlight.name = "Highlight"
	highlight.position = Vector2(0.0, 2.0)
	highlight.size = Vector2(size.x, maxf(2.0, floorf(size.y * 0.18)))
	highlight.color = PLAYER_BAR_HIGHLIGHT_COLOR
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(highlight)
	return clip


func _load_texture(resource_path: String) -> Texture2D:
	var texture := load(resource_path) as Texture2D
	if texture == null:
		push_error("No se pudo cargar la textura: %s" % resource_path)
	return texture


func _card_texture(card_id: StringName) -> Texture2D:
	if card_texture_cache.has(card_id):
		return card_texture_cache[card_id]
	if not CARD_TEXTURE_PATHS.has(card_id):
		push_error("La carta no tiene textura registrada: %s" % card_id)
		return null
	var texture := _load_texture(CARD_TEXTURE_PATHS[card_id])
	if texture != null:
		card_texture_cache[card_id] = texture
	return texture


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


func _configure_bar_value_label(label: Label) -> void:
	label.add_theme_font_override("font", COMBAT_NUMBER_FONT)
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.01, 0.02, 0.98))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 3)


func _spawn_combat_number(
	amount: int,
	anchor_position: Vector2,
	is_healing := false,
	is_status := false,
	start_offset := Vector2.ZERO
) -> Label:
	if amount <= 0 or not is_instance_valid(combat_numbers):
		return null

	var label := Label.new()
	label.name = "CombatNumber"
	label.text = "%s%d" % ["+" if is_healing else "-", amount]
	label.position = anchor_position - COMBAT_NUMBER_SIZE / 2.0 + start_offset
	label.size = COMBAT_NUMBER_SIZE
	label.pivot_offset = COMBAT_NUMBER_SIZE / 2.0
	label.scale = Vector2.ONE * 0.48
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", COMBAT_NUMBER_FONT)
	label.add_theme_font_size_override("font_size", COMBAT_NUMBER_FONT_SIZE)
	label.add_theme_color_override(
		"font_color",
		COMBAT_NUMBER_STATUS_COLOR if is_status or is_healing else COMBAT_NUMBER_NORMAL_COLOR
	)
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.01, 0.02, 0.96))
	label.add_theme_constant_override("outline_size", 12)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 5)
	label.add_theme_constant_override("shadow_offset_y", 7)
	combat_numbers.add_child(label)

	var origin := label.position
	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2.ONE * 1.28, 0.11).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		label, "position", origin + Vector2(12.0, -22.0), 0.11
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.14).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		label, "position", origin + Vector2(-8.0, -50.0), 0.14
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.28)
	tween.tween_property(
		label, "position", origin + Vector2(16.0, -132.0), 0.40
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.40)
	tween.finished.connect(label.queue_free)
	return label


func _player_combat_number_position() -> Vector2:
	return character_root.position + Vector2(0.0, -400.0)


func _enemy_combat_number_position(enemy_index: int) -> Vector2:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return COMBAT_VIEWPORT_SIZE / 2.0
	var sprite: Sprite2D = enemies[enemy_index]["sprite"]
	var rise := maxf(145.0, sprite.texture.get_height() * sprite.scale.y * 0.31)
	return sprite.position - Vector2(0.0, rise)


func _show_status_result(
	result: Dictionary,
	anchor_position: Vector2
) -> void:
	var poison_damage := int(result.get("poison_damage", 0))
	var regenerated_hp := int(result.get("regenerated_hp", 0))
	if poison_damage > 0:
		_spawn_combat_number(
			poison_damage,
			anchor_position,
			false,
			true,
			Vector2(-48.0, 0.0) if regenerated_hp > 0 else Vector2.ZERO
		)
	if regenerated_hp > 0:
		_spawn_combat_number(
			regenerated_hp,
			anchor_position,
			true,
			true,
			Vector2(48.0, -34.0) if poison_damage > 0 else Vector2.ZERO
		)


func _begin_player_turn(first_turn := false) -> void:
	if combat_finished:
		return
	player.begin_turn()
	deck.begin_turn()
	discard_window_open = true
	discard_mode = false
	discard_button.button_pressed = false
	discard_button.disabled = false
	_refresh_action_button_visual(discard_button)
	deck.draw(maxi(0, HAND_SIZE - deck.hand.size()))
	set_energy(deck.energy)
	_rebuild_hand()
	_refresh_all_ui()
	hint_label.text = (
		"PRIMER TURNO · CLIC DERECHO PARA DESCARTAR · ARRASTRA PARA JUGAR"
		if first_turn
		else "NUEVO TURNO · CLIC DERECHO PARA DESCARTAR · ARRASTRA PARA JUGAR"
	)


func _rebuild_hand() -> void:
	_reset_card_interaction()
	for button in card_buttons:
		if is_instance_valid(button):
			button.queue_free()
	card_buttons.clear()

	var count: int = deck.hand.size()
	if count == 0:
		return
	var step := CARD_SIZE.x + CARD_GAP
	var center := (count - 1) / 2.0
	var start_x := 960.0 - CARD_SIZE.x / 2.0 - center * step
	for card_index in count:
		var card_id: StringName = deck.hand[card_index]
		var offset := card_index - center
		var button := TextureButton.new()
		button.texture_normal = _card_texture(card_id)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.clip_contents = false
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.size = CARD_SIZE
		# The pivot sits just below the card. Scaling therefore reveals more of
		# the same card upwards without making the pointer leave it immediately.
		button.pivot_offset = Vector2(CARD_SIZE.x / 2.0, CARD_SIZE.y + 15.0)
		button.position = Vector2(
			start_x + card_index * step,
			CARD_Y + absf(offset) * CARD_FAN_LIFT
		)
		button.rotation = deg_to_rad(offset * CARD_FAN_ROTATION)
		button.z_index = card_index
		button.tooltip_text = "%s · Coste %d" % [
			CardCatalog.CARDS[card_id]["name"],
			CardCatalog.CARDS[card_id]["cost"],
		]
		button.set_meta("card_id", card_id)
		button.set_meta("home_position", button.position)
		button.set_meta("home_rotation", button.rotation)
		button.set_meta("home_scale", Vector2.ONE)
		button.set_meta("home_z_index", card_index)
		button.gui_input.connect(_on_card_input.bind(button))
		button.mouse_entered.connect(_on_card_hovered.bind(button))
		button.mouse_exited.connect(_on_card_unhovered.bind(button))
		interface.add_child(button)
		card_buttons.append(button)


func _start_card_drag(
	button: TextureButton,
	card_id: StringName,
	pointer: Vector2
) -> void:
	_stop_card_motion(button)
	drag_card = button
	drag_card_id = card_id
	drag_pointer_position = pointer
	drag_grab_local = button.get_global_transform().affine_inverse() * pointer
	if selected_card == button:
		selected_card = null
	if hovered_card == button:
		hovered_card = null
	button.rotation = 0.0
	button.scale = CARD_DRAG_SCALE
	button.z_index = 100
	button.modulate = Color(1.08, 1.08, 1.08)
	button.global_position += (
		pointer - button.get_global_transform() * drag_grab_local
	)


func _move_card_drag(pointer: Vector2) -> void:
	if not is_instance_valid(drag_card):
		return
	drag_card.global_position += pointer - drag_pointer_position
	drag_pointer_position = pointer
	_refresh_enemy_highlight(pointer)


func _discard_card(card_id: StringName) -> void:
	if not discard_window_open or not deck.discard(card_id):
		return
	hint_label.text = "%s DESCARTADA · CONSERVA O DESCARTA OTRA" % (
		CardCatalog.CARDS[card_id]["name"]
	)
	_rebuild_hand()
	_refresh_all_ui()


func _toggle_discard_mode(enabled: bool) -> void:
	discard_mode = enabled and discard_window_open
	_refresh_action_button_visual(discard_button)
	if discard_mode:
		hint_label.text = "TOCA UNA CARTA PARA DESCARTARLA"
	else:
		hint_label.text = "ARRASTRA UNA CARTA PARA JUGAR"


func _on_card_input(event: InputEvent, button: TextureButton) -> void:
	if combat_finished:
		return
	var card_id: StringName = button.get_meta("card_id")
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_discard_card(card_id)
			button.accept_event()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if discard_mode:
					_discard_card(card_id)
					button.accept_event()
					return
				_begin_card_press(
					button,
					card_id,
					_card_event_canvas_position(button, event),
					-1
				)
			else:
				_finish_card_press(
					button,
					_card_event_canvas_position(button, event),
					-1
				)
			button.accept_event()
	elif event is InputEventMouseMotion and pressed_card == button:
		_update_card_press(
			button,
			_card_event_canvas_position(button, event),
			-1
		)
		button.accept_event()
	elif event is InputEventScreenTouch:
		if event.pressed:
			if discard_mode:
				_discard_card(card_id)
				button.accept_event()
				return
			_begin_card_press(
				button,
				card_id,
				_card_event_canvas_position(button, event),
				event.index
			)
		else:
			_finish_card_press(
				button,
				_card_event_canvas_position(button, event),
				event.index
			)
		button.accept_event()
	elif event is InputEventScreenDrag and pressed_card == button:
		_update_card_press(
			button,
			_card_event_canvas_position(button, event),
			event.index
		)
		button.accept_event()


func _card_event_canvas_position(
	button: TextureButton,
	event: InputEvent
) -> Vector2:
	# GUI input positions are local to the Control. Converting through the
	# card transform keeps mouse and touch in the same CanvasLayer coordinates.
	var local_position := Vector2.ZERO
	if event is InputEventMouse:
		local_position = (event as InputEventMouse).position
	elif event is InputEventScreenTouch:
		local_position = (event as InputEventScreenTouch).position
	elif event is InputEventScreenDrag:
		local_position = (event as InputEventScreenDrag).position
	return button.get_global_transform() * local_position


func _begin_card_press(
	button: TextureButton,
	card_id: StringName,
	pointer: Vector2,
	pointer_index: int
) -> void:
	if pressed_card != null:
		return
	pressed_card = button
	pressed_card_id = card_id
	pressed_pointer_position = pointer
	pressed_pointer_index = pointer_index


func _update_card_press(
	button: TextureButton,
	pointer: Vector2,
	pointer_index: int
) -> void:
	if pressed_card != button or pressed_pointer_index != pointer_index:
		return
	if drag_card == null:
		if pointer.distance_to(pressed_pointer_position) < CARD_DRAG_THRESHOLD:
			return
		_start_card_drag(
			button,
			pressed_card_id,
			pressed_pointer_position
		)
	_move_card_drag(pointer)


func _finish_card_press(
	button: TextureButton,
	pointer: Vector2,
	pointer_index: int
) -> void:
	if pressed_card != button or pressed_pointer_index != pointer_index:
		return
	if drag_card == button:
		_finish_card_drag(pointer)
	else:
		_select_card(button)
	pressed_card = null
	pressed_card_id = &""
	pressed_pointer_index = -1


func _on_card_hovered(button: TextureButton) -> void:
	if drag_card != null or pressed_card != null:
		return
	hovered_card = button
	_refresh_card_focus()


func _on_card_unhovered(button: TextureButton) -> void:
	if hovered_card != button:
		return
	# Moving and scaling a Control can briefly emit mouse_exited. The short
	# grace period keeps the hover stable while the card grows.
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(button) or hovered_card != button:
		return
	var pointer_local := (
		button.get_global_transform().affine_inverse()
		* get_viewport().get_mouse_position()
	)
	if Rect2(Vector2.ZERO, button.size).has_point(pointer_local):
		return
	hovered_card = null
	_refresh_card_focus()


func _select_card(button: TextureButton) -> void:
	selected_card = null if selected_card == button else button
	_refresh_card_focus()


func _refresh_card_focus() -> void:
	for button: TextureButton in card_buttons:
		if not is_instance_valid(button) or button == drag_card:
			continue
		_animate_card_focus(
			button,
			button == hovered_card or button == selected_card
		)


func _animate_card_focus(button: TextureButton, focused: bool) -> void:
	if not button.has_meta("home_position"):
		return
	_stop_card_motion(button)
	var home_position: Vector2 = button.get_meta("home_position")
	var target_position := (
		home_position + Vector2(0.0, -CARD_FOCUS_LIFT)
		if focused
		else home_position
	)
	var target_rotation := (
		0.0 if focused else float(button.get_meta("home_rotation"))
	)
	var target_scale: Vector2 = CARD_FOCUS_SCALE
	if not focused:
		target_scale = button.get_meta("home_scale")
	button.z_index = (
		CARD_FOCUS_Z_INDEX
		if focused
		else int(button.get_meta("home_z_index"))
	)
	var target_modulate := Color(1.06, 1.06, 1.06) if focused else Color.WHITE
	var duration := CARD_FOCUS_DURATION if focused else CARD_RETURN_DURATION
	var motion := create_tween().set_parallel(true)
	motion.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_property(button, "position", target_position, duration)
	motion.tween_property(button, "rotation", target_rotation, duration)
	motion.tween_property(button, "scale", target_scale, duration)
	motion.tween_property(button, "modulate", target_modulate, duration)
	var motion_key := button.get_instance_id()
	card_motion_tweens[motion_key] = motion
	motion.finished.connect(_on_card_motion_finished.bind(motion_key, motion))


func _stop_card_motion(button: TextureButton) -> void:
	var motion_key := button.get_instance_id()
	var motion := card_motion_tweens.get(motion_key) as Tween
	if motion != null and motion.is_valid():
		motion.kill()
	card_motion_tweens.erase(motion_key)


func _on_card_motion_finished(motion_key: int, motion: Tween) -> void:
	if card_motion_tweens.get(motion_key) == motion:
		card_motion_tweens.erase(motion_key)


func _restore_card_home(button: TextureButton) -> void:
	if not is_instance_valid(button) or not button.has_meta("home_position"):
		return
	button.position = button.get_meta("home_position")
	button.rotation = button.get_meta("home_rotation")
	button.scale = button.get_meta("home_scale")
	button.z_index = int(button.get_meta("home_z_index"))
	button.modulate = Color.WHITE


func _reset_card_interaction() -> void:
	for button: TextureButton in card_buttons:
		if is_instance_valid(button):
			_stop_card_motion(button)
			_restore_card_home(button)
	pressed_card = null
	pressed_card_id = &""
	pressed_pointer_index = -1
	drag_card = null
	drag_card_id = &""
	hovered_card = null
	selected_card = null
	_clear_enemy_highlight()


func _finish_card_drag(drop_position: Vector2) -> void:
	if not is_instance_valid(drag_card):
		return
	var card_data: Dictionary = CardCatalog.CARDS[drag_card_id]
	var target_index := _enemy_at(drop_position)
	var valid_drop := false
	if card_data["target"] == CardCatalog.Target.ONE_ENEMY:
		valid_drop = target_index >= 0
	else:
		valid_drop = drop_position.y < PLAY_LINE_Y

	if valid_drop and _try_play_card(drag_card_id, target_index):
		if is_instance_valid(drag_card):
			drag_card.visible = false
		drag_card = null
		drag_card_id = &""
		_clear_enemy_highlight()
		return

	var returning_card := drag_card
	drag_card = null
	drag_card_id = &""
	_clear_enemy_highlight()
	_animate_card_focus(returning_card, false)


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
	discard_mode = false
	discard_button.button_pressed = false
	discard_button.disabled = true
	_refresh_action_button_visual(discard_button)
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
							var damage := _enemy_state(enemy_index).receive_attack(
								effect["amount"], player.strength
							)
							_spawn_combat_number(
								damage, _enemy_combat_number_position(enemy_index)
							)
				elif target_index >= 0:
					var damage := _enemy_state(target_index).receive_attack(
						effect["amount"], player.strength
					)
					_spawn_combat_number(
						damage, _enemy_combat_number_position(target_index)
					)
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
				var healed_hp := player.heal(effect["amount"])
				_spawn_combat_number(
					healed_hp, _player_combat_number_position(), true, true
				)
			&"regeneration":
				player.regeneration += effect["amount"]
			&"strength":
				player.strength += effect["amount"]
			&"autodefense":
				player.autodefense += effect["amount"]
			&"double_poison":
				_enemy_state(target_index).poison *= 2
			&"self_damage":
				var self_damage := player.receive_blockable_damage(effect["amount"])
				_spawn_combat_number(
					self_damage, _player_combat_number_position()
				)


func _end_player_turn() -> void:
	if combat_finished or drag_card != null or pressed_card != null:
		return
	turn_button.disabled = true
	_refresh_action_button_visual(turn_button)
	discard_window_open = false
	var player_status_result := player.apply_end_of_turn_statuses()
	_show_status_result(player_status_result, _player_combat_number_position())
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
		var attack_damage := player.receive_attack(enemies[enemy_index]["damage"])
		_spawn_combat_number(
			attack_damage, _player_combat_number_position()
		)
		var state := _enemy_state(enemy_index)
		var enemy_status_result := state.apply_end_of_turn_statuses()
		_show_status_result(
			enemy_status_result, _enemy_combat_number_position(enemy_index)
		)
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
	_refresh_action_button_visual(turn_button)
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
	player_hp_clip.size.x = (
		PLAYER_HP_BAR_SIZE.x
		* clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)
	)
	player_block_clip.size.x = (
		PLAYER_DEF_BAR_SIZE.x
		* clampf(float(player.block) / MAX_BLOCK_DISPLAY, 0.0, 1.0)
	)
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
	if energy_states_texture == null:
		energy_states_texture = _load_texture(ENERGY_STATES_PATH)
	if energy_states_texture == null:
		energy_counter.visible = false
		return
	atlas.atlas = energy_states_texture
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
	_reset_card_interaction()
	if not victory:
		GameState.reset_run()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return

	GameState.run_hp = player.hp
	GameState.add_currency(
		EnemyCatalogScript.encounter_currency(
			GameState.pending_encounter
		)
	)
	GameState.complete_pending_destination()
	turn_button.disabled = true
	_refresh_action_button_visual(turn_button)
	discard_button.disabled = true
	_refresh_action_button_visual(discard_button)
	for button in card_buttons:
		button.disabled = true
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(
		0.015, 0.008, 0.02, 0.46 if victory else 0.82
	)
	modal_content.add_child(shade)
	_build_reward_offer()


func _build_reward_offer() -> void:
	var reward_mat := TextureRect.new()
	reward_mat.name = "RewardMat"
	reward_mat.position = REWARD_MAT_POSITION
	reward_mat.size = REWARD_MAT_SIZE
	reward_mat.texture = _load_texture(REWARD_MAT_PATH)
	reward_mat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	reward_mat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	reward_mat.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	reward_mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal_content.add_child(reward_mat)

	var reward_title := _make_label(
		Vector2(657, 169), Vector2(607, 80), 22, Color(0.98, 0.88, 0.69)
	)
	reward_title.name = "RewardTitle"
	reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reward_title.add_theme_font_override("font", COMBAT_NUMBER_FONT)
	reward_title.add_theme_color_override(
		"font_outline_color", Color(0.02, 0.01, 0.015, 0.98)
	)
	reward_title.add_theme_constant_override("outline_size", 7)
	reward_title.text = "ELIGE UNA CARTA"
	modal_content.add_child(reward_title)
	var reward := RewardGenerator.generate(GameState.selected_character)
	for reward_index in reward.size():
		var card_id: StringName = reward[reward_index]
		var card_data: Dictionary = CardCatalog.CARDS[card_id]
		var choice := TextureButton.new()
		choice.name = "RewardCard%d" % reward_index
		choice.texture_normal = _card_texture(card_id)
		choice.texture_hover = choice.texture_normal
		choice.texture_pressed = choice.texture_normal
		choice.ignore_texture_size = true
		choice.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		choice.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		choice.position = Vector2(
			REWARD_CARD_X_POSITIONS[reward_index], REWARD_CARD_Y
		)
		choice.size = REWARD_CARD_SIZE
		choice.pivot_offset = REWARD_CARD_SIZE / 2.0
		choice.focus_mode = Control.FOCUS_NONE
		choice.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		choice.tooltip_text = "%s · Coste %d" % [
			card_data["name"], card_data["cost"]
		]
		choice.set_meta("card_id", card_id)
		choice.mouse_entered.connect(_animate_reward_card.bind(choice, true))
		choice.mouse_exited.connect(_animate_reward_card.bind(choice, false))
		choice.pressed.connect(_choose_reward.bind(card_id))
		modal_content.add_child(choice)
	_add_reward_skip_button()


func _animate_reward_card(button: TextureButton, hovered: bool) -> void:
	if not is_instance_valid(button):
		return
	var motion_key := button.get_instance_id()
	var previous := reward_card_tweens.get(motion_key) as Tween
	if previous != null and previous.is_valid():
		previous.kill()
	button.z_index = 20 if hovered else 0
	var motion := create_tween().set_parallel(true)
	motion.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion.tween_property(
		button,
		"scale",
		REWARD_CARD_HOVER_SCALE if hovered else Vector2.ONE,
		0.14
	)
	motion.tween_property(
		button,
		"modulate",
		Color(1.08, 1.05, 1.02) if hovered else Color.WHITE,
		0.14
	)
	reward_card_tweens[motion_key] = motion


func _choose_reward(card_id: StringName) -> void:
	GameState.add_reward_card(card_id)
	hint_label.text = "RECOMPENSA ELEGIDA: %s" % CardCatalog.CARDS[card_id]["name"]
	get_tree().change_scene_to_file("res://scenes/overworld.tscn")


func _add_reward_skip_button() -> void:
	var skip_button := _make_action_texture_button(
		"RewardSkipButton",
		REWARD_SKIP_BUTTON_TEXTURE,
		REWARD_SKIP_BUTTON_POSITION,
		REWARD_SKIP_BUTTON_SIZE,
		"OMITIR RECOMPENSA"
	)
	skip_button.pressed.connect(
		func(): get_tree().change_scene_to_file("res://scenes/overworld.tscn")
	)
	modal_content.add_child(skip_button)


func _add_return_button(
	text: String,
	position: Vector2,
	node_name := "ReturnButton"
) -> void:
	var continue_button := Button.new()
	continue_button.name = node_name
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
	if not CHARACTER_SHEET_PATHS.has(character_id):
		character_id = &"michu"
	var sheet := _load_texture(CHARACTER_SHEET_PATHS[character_id])
	if sheet == null:
		return
	character_sprite.sprite_frames = _build_idle_frames(sheet, character_id)
	character_sprite.position = Vector2(0, -COMBAT_FRAME_SIZE.y / 2.0)
	character_root.position = INTERIOR_LAYOUTS[interior_index]["player_feet"]
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
