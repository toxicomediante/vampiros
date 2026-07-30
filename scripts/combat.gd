extends Control

const CombatantStateScript = preload("res://scripts/combat/combatant_state.gd")
const CombatDeckScript = preload("res://scripts/combat/combat_deck.gd")

const COMBAT_FRAME_SIZE := Vector2i(362, 644)
const IDLE_FRAME_COUNT := 6
const CHARACTER_POSITION := Vector2(520, 900)
const MAX_ENERGY := 3
const HAND_SIZE := 5
const ENERGY_FRAME_SIZE := Vector2i(256, 373)
const ENERGY_FRAME_Y := 0
const CARD_SIZE := Vector2(210, 315)
const CARD_GAP := -78.0
const CARD_Y := 748.0
const CARD_FAN_ROTATION := 6.0
const CARD_FAN_LIFT := 17.0
const CARD_PREVIEW_SIZE := Vector2(360.0, 540.0)
const CARD_PREVIEW_Y := 385.0
const CARD_DRAG_THRESHOLD := 14.0
const CARD_DRAG_SCALE := Vector2(1.12, 1.12)
const PLAY_LINE_Y := 700.0
const MAX_BLOCK_DISPLAY := 20.0
const PLAYER_UI_POSITION := Vector2(24.0, 140.0)
const PLAYER_UI_SIZE := Vector2(640.0, 128.0)
const PLAYER_HP_BAR_POSITION := Vector2(48.0, 15.0)
const PLAYER_HP_BAR_SIZE := Vector2(548.0, 41.0)
const PLAYER_DEF_BAR_POSITION := Vector2(48.0, 71.0)
const PLAYER_DEF_BAR_SIZE := Vector2(548.0, 41.0)

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
		"texture_path": "res://assets/enemies/tarantula.png",
		"position": Vector2(1170, 515),
		"scale": Vector2(0.86, 0.86),
	},
	{
		"id": &"malleiro",
		"name": "VAMPIRO MALLEIRO",
		"max_hp": 30,
		"damage": 7,
		"texture_path": "res://assets/enemies/vampiro_malleiro.png",
		"position": Vector2(1585, 500),
		"scale": Vector2(0.66, 0.66),
	},
]

const INTERIOR_BACKGROUND_PATHS: Array[String] = [
	"res://assets/backgrounds/combat/bar_interior_01.png",
	"res://assets/backgrounds/combat/bar_interior_02.png",
	"res://assets/backgrounds/combat/bar_interior_03.png",
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
const HP_BAR_BASE_PATH := "res://assets/ui/combat/hp_bar_base.png"
const HP_BAR_FILL_PATH := "res://assets/ui/combat/hp_bar_fill.png"
const DEF_BAR_BASE_PATH := "res://assets/ui/combat/def_bar_base.png"
const DEF_BAR_FILL_PATH := "res://assets/ui/combat/def_bar_fill.png"

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
var card_texture_cache := {}
var energy_states_texture: Texture2D
var drag_card: TextureButton
var drag_card_id: StringName
var drag_origin := Vector2.ZERO
var drag_origin_rotation := 0.0
var drag_origin_scale := Vector2.ONE
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

var player_hp_label: Label
var player_block_label: Label
var player_hp_clip: Control
var player_block_clip: Control
var player_status_label: Label
var deck_label: Label
var hint_label: Label
var discard_button: Button
var turn_button: Button
var card_preview: TextureRect


func _ready() -> void:
	sound_enabled = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	_configure_music_loop()
	if not background_music.playing:
		background_music.play()

	var interior_index := clampi(
		GameState.selected_combat_interior,
		0,
		INTERIOR_BACKGROUND_PATHS.size() - 1
	)
	background.texture = _load_texture(INTERIOR_BACKGROUND_PATHS[interior_index])
	_prepare_character()
	_prepare_combat_state()
	_build_enemies()
	_build_runtime_ui()
	_begin_player_turn(true)

	fullscreen_button.pressed.connect(_toggle_fullscreen)
	sound_button.pressed.connect(_toggle_sound)
	_refresh_control_icons()
	_play_scene_intro()


func _exit_tree() -> void:
	if background_music != null:
		background_music.stop()
		background_music.stream = null


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
	for definition: Dictionary in ENEMY_DEFINITIONS:
		var state: CombatantState = CombatantStateScript.new(definition["max_hp"])
		var sprite := Sprite2D.new()
		sprite.texture = _load_texture(definition["texture_path"])
		if sprite.texture == null:
			continue
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


func _build_runtime_ui() -> void:
	var hp_bar_base := _load_texture(HP_BAR_BASE_PATH)
	var def_bar_base := _load_texture(DEF_BAR_BASE_PATH)
	var hp_bar_fill := _load_texture(HP_BAR_FILL_PATH)
	var def_bar_fill := _load_texture(DEF_BAR_FILL_PATH)
	var hp_def_frame := _load_texture(HP_DEF_FRAME_PATH)
	energy_states_texture = _load_texture(ENERGY_STATES_PATH)
	if (
		hp_bar_base == null
		or def_bar_base == null
		or hp_bar_fill == null
		or def_bar_fill == null
		or hp_def_frame == null
		or energy_states_texture == null
	):
		push_error("No se pudo cargar la interfaz de combate")
		return

	var player_ui := Control.new()
	player_ui.name = "PlayerHUD"
	player_ui.position = PLAYER_UI_POSITION
	player_ui.size = PLAYER_UI_SIZE
	player_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interface.add_child(player_ui)

	player_ui.add_child(
		_make_texture_rect(
			hp_bar_base,
			PLAYER_HP_BAR_POSITION,
			PLAYER_HP_BAR_SIZE
		)
	)
	player_ui.add_child(
		_make_texture_rect(
			def_bar_base,
			PLAYER_DEF_BAR_POSITION,
			PLAYER_DEF_BAR_SIZE
		)
	)

	player_hp_clip = _make_bar_clip(
		hp_bar_fill,
		PLAYER_HP_BAR_POSITION,
		PLAYER_HP_BAR_SIZE
	)
	player_ui.add_child(player_hp_clip)
	player_block_clip = _make_bar_clip(
		def_bar_fill,
		PLAYER_DEF_BAR_POSITION,
		PLAYER_DEF_BAR_SIZE
	)
	player_ui.add_child(player_block_clip)

	var player_frame := _make_texture_rect(
		hp_def_frame,
		Vector2.ZERO,
		PLAYER_UI_SIZE
	)
	player_ui.add_child(player_frame)

	player_hp_label = _make_label(
		PLAYER_HP_BAR_POSITION,
		PLAYER_HP_BAR_SIZE,
		16,
		Color(1.0, 0.92, 0.82)
	)
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_ui.add_child(player_hp_label)
	player_block_label = _make_label(
		PLAYER_DEF_BAR_POSITION,
		PLAYER_DEF_BAR_SIZE,
		16,
		Color(0.78, 0.9, 1.0)
	)
	player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_block_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	player_ui.add_child(player_block_label)
	player_status_label = _make_label(
		Vector2(38, 278), Vector2(640, 34), 13, Color(0.96, 0.82, 0.56)
	)
	interface.add_child(player_status_label)

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

	discard_button = Button.new()
	discard_button.text = "DESCARTAR CARTA"
	discard_button.position = Vector2(1590, 848)
	discard_button.size = Vector2(290, 70)
	discard_button.toggle_mode = true
	discard_button.add_theme_font_size_override("font_size", 18)
	discard_button.add_theme_color_override("font_color", Color(0.9, 0.72, 0.55))
	discard_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	discard_button.toggled.connect(_toggle_discard_mode)
	interface.add_child(discard_button)

	turn_button = Button.new()
	turn_button.text = "FIN DE TURNO"
	turn_button.position = Vector2(1590, 938)
	turn_button.size = Vector2(290, 86)
	turn_button.add_theme_font_size_override("font_size", 22)
	turn_button.add_theme_color_override("font_color", Color(1.0, 0.86, 0.64))
	turn_button.add_theme_color_override("font_hover_color", Color.WHITE)
	turn_button.pressed.connect(_end_player_turn)
	interface.add_child(turn_button)

	card_preview = TextureRect.new()
	card_preview.name = "CardPreview"
	card_preview.size = CARD_PREVIEW_SIZE
	card_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_preview.z_index = 90
	card_preview.visible = false
	interface.add_child(card_preview)

	interface.move_child(curtain, interface.get_child_count() - 1)


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


func _make_bar_clip(
	texture: Texture2D,
	position: Vector2,
	size: Vector2
) -> Control:
	var clip := Control.new()
	clip.name = "BarClip"
	clip.position = position
	clip.size = size
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := _make_texture_rect(texture, Vector2.ZERO, size)
	clip.add_child(fill)
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


func _begin_player_turn(first_turn := false) -> void:
	if combat_finished:
		return
	player.begin_turn()
	deck.begin_turn()
	discard_window_open = true
	discard_mode = false
	discard_button.button_pressed = false
	discard_button.disabled = false
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
		button.pivot_offset = CARD_SIZE / 2.0
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
	drag_card = button
	drag_card_id = card_id
	drag_origin = button.position
	drag_origin_rotation = button.rotation
	drag_origin_scale = button.scale
	drag_pointer_position = pointer
	drag_grab_local = button.get_global_transform().affine_inverse() * pointer
	button.rotation = 0.0
	button.scale = CARD_DRAG_SCALE
	button.z_index = 100
	button.modulate = Color(1.08, 1.08, 1.08)
	button.global_position += (
		pointer - button.get_global_transform() * drag_grab_local
	)
	_hide_card_preview()


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
	_show_card_preview(button)


func _on_card_unhovered(button: TextureButton) -> void:
	if hovered_card == button:
		hovered_card = null
	_restore_card_preview()


func _select_card(button: TextureButton) -> void:
	selected_card = null if selected_card == button else button
	_restore_card_preview()


func _show_card_preview(button: TextureButton) -> void:
	if not is_instance_valid(card_preview) or not is_instance_valid(button):
		return
	card_preview.texture = button.texture_normal
	var card_center := button.get_global_transform() * button.pivot_offset
	card_preview.global_position = Vector2(
		clampf(
			card_center.x - CARD_PREVIEW_SIZE.x / 2.0,
			280.0,
			1920.0 - 280.0 - CARD_PREVIEW_SIZE.x
		),
		CARD_PREVIEW_Y
	)
	card_preview.visible = true


func _restore_card_preview() -> void:
	if drag_card != null:
		_hide_card_preview()
	elif is_instance_valid(hovered_card):
		_show_card_preview(hovered_card)
	elif is_instance_valid(selected_card):
		_show_card_preview(selected_card)
	else:
		_hide_card_preview()


func _hide_card_preview() -> void:
	if is_instance_valid(card_preview):
		card_preview.visible = false


func _reset_card_interaction() -> void:
	if is_instance_valid(drag_card):
		drag_card.position = drag_origin
		drag_card.rotation = drag_origin_rotation
		drag_card.scale = drag_origin_scale
		drag_card.modulate = Color.WHITE
	pressed_card = null
	pressed_card_id = &""
	pressed_pointer_index = -1
	drag_card = null
	drag_card_id = &""
	hovered_card = null
	selected_card = null
	_clear_enemy_highlight()
	_hide_card_preview()


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

	drag_card.position = drag_origin
	drag_card.rotation = drag_origin_rotation
	drag_card.scale = drag_origin_scale
	drag_card.z_index = card_buttons.find(drag_card)
	drag_card.modulate = Color.WHITE
	drag_card = null
	drag_card_id = &""
	_clear_enemy_highlight()
	_restore_card_preview()


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
	if combat_finished or drag_card != null or pressed_card != null:
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
	if not CHARACTER_SHEET_PATHS.has(character_id):
		character_id = &"michu"
	var sheet := _load_texture(CHARACTER_SHEET_PATHS[character_id])
	if sheet == null:
		return
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
