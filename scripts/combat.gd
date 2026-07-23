extends Control

const COMBAT_FRAME_SIZE := Vector2i(362, 644)
const IDLE_FRAME_COUNT := 6
const CHARACTER_POSITION := Vector2(620, 1020)

const INTERIOR_BACKGROUNDS: Array[Texture2D] = [
	preload("res://assets/concepts/combat/v1/bar_interior_01_v1.png"),
	preload("res://assets/concepts/combat/v1/bar_interior_02_v1.png"),
	preload("res://assets/concepts/combat/v1/bar_interior_03_v1.png"),
]
const CHARACTER_SHEETS := {
	&"juan": preload("res://assets/characters/combat/juan_combat_idle.png"),
	&"michu": preload("res://assets/characters/combat/michu_combat_idle.png"),
}
const FULLSCREEN_TEXTURE := preload("res://assets/ui/generated/fullscreen.png")
const WINDOWED_TEXTURE := preload("res://assets/ui/generated/windowed.png")
const SOUND_ON_TEXTURE := preload("res://assets/ui/generated/sound_on.png")
const SOUND_OFF_TEXTURE := preload("res://assets/ui/generated/sound_off.png")

@onready var background: TextureRect = $Background
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var character_root: Node2D = $CombatCharacter
@onready var character_sprite: AnimatedSprite2D = $CombatCharacter/Sprite
@onready var shadow: Polygon2D = $CombatCharacter/Shadow
@onready var curtain: ColorRect = $Interface/Curtain
@onready var fullscreen_button: TextureButton = $Interface/TopControls/FullscreenButton
@onready var sound_button: TextureButton = $Interface/TopControls/SoundButton

var sound_enabled := true


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

	fullscreen_button.pressed.connect(_toggle_fullscreen)
	sound_button.pressed.connect(_toggle_sound)
	_refresh_control_icons()
	_play_scene_intro()


func _prepare_character() -> void:
	var character_id: StringName = GameState.selected_character
	if not CHARACTER_SHEETS.has(character_id):
		character_id = &"michu"

	var sheet: Texture2D = CHARACTER_SHEETS[character_id]
	character_sprite.sprite_frames = _build_idle_frames(sheet, character_id)
	character_sprite.position = Vector2(0, -COMBAT_FRAME_SIZE.y / 2.0)
	character_root.position = CHARACTER_POSITION
	character_root.scale = Vector2.ONE * (1.13 if character_id == &"michu" else 1.10)
	shadow.scale = Vector2(0.90, 0.82) if character_id == &"michu" else Vector2(1.12, 0.92)
	character_sprite.play(&"idle")


func _build_idle_frames(sheet: Texture2D, character_id: StringName) -> SpriteFrames:
	assert(
		sheet.get_width() == COMBAT_FRAME_SIZE.x * IDLE_FRAME_COUNT,
		"La hoja de combate debe contener seis columnas exactas"
	)
	assert(
		sheet.get_height() == COMBAT_FRAME_SIZE.y,
		"La hoja de combate debe tener una fila de 644 px"
	)

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
	var reveal := create_tween().set_parallel(true)
	reveal.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(curtain, "color:a", 0.0, 0.65)
	reveal.tween_property(character_root, "modulate:a", 1.0, 0.48).set_delay(0.18)


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
