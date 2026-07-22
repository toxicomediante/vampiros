extends Control

const MICHU_SHEET := preload("res://assets/characters/michu_idle.png")
const JUAN_SHEET := preload("res://assets/characters/juan_idle.png")
const IDLE_FPS := 5.0

@onready var logo: TextureRect = $Logo
@onready var michu_sprite: AnimatedSprite2D = $MichuSprite
@onready var juan_sprite: AnimatedSprite2D = $JuanSprite
@onready var michu_button: Button = $MichuButton
@onready var juan_button: Button = $JuanButton
@onready var michu_name: Label = $MichuName
@onready var juan_name: Label = $JuanName
@onready var start_button: TextureButton = $StartButton
@onready var status: Label = $Status
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var selected_character := ""

func _ready() -> void:
	if background_music.stream is AudioStreamOggVorbis:
		background_music.stream.loop = true
	if not background_music.playing:
		background_music.play()
	michu_sprite.sprite_frames = _build_idle_frames(MICHU_SHEET, 6)
	juan_sprite.sprite_frames = _build_idle_frames(JUAN_SHEET, 6)
	michu_sprite.play("idle")
	juan_sprite.play("idle")
	michu_button.pressed.connect(_select_character.bind("michu"))
	juan_button.pressed.connect(_select_character.bind("juan"))
	start_button.pressed.connect(_start_night)
	start_button.disabled = true
	_play_intro()

func _build_idle_frames(sheet: Texture2D, frame_count: int) -> SpriteFrames:
	assert(sheet.get_width() % frame_count == 0, "La hoja debe contener celdas de igual anchura")
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", IDLE_FPS)
	var frame_width: int = sheet.get_width() / frame_count
	for index in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2i(index * frame_width, 0, frame_width, sheet.get_height())
		frames.add_frame("idle", atlas)
	return frames

func _play_intro() -> void:
	logo.modulate.a = 0.0
	logo.scale = Vector2(0.72, 0.72)
	logo.position.y = -300.0
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(logo, "position:y", 20.0, 1.05)
	tween.tween_property(logo, "scale", Vector2.ONE, 1.05)
	tween.tween_property(logo, "modulate:a", 1.0, 0.55)

func _select_character(character_id: String) -> void:
	_ensure_music_started()
	selected_character = character_id
	start_button.disabled = false
	if character_id == "michu":
		status.text = "Trilita pura"
		_set_selected(michu_sprite, michu_name, true)
		_set_selected(juan_sprite, juan_name, false)
	else:
		status.text = "Ya dormirás en la caja"
		_set_selected(michu_sprite, michu_name, false)
		_set_selected(juan_sprite, juan_name, true)

func _set_selected(sprite: AnimatedSprite2D, label: Label, selected: bool) -> void:
	var target_scale := Vector2(1.92, 1.92) if selected else Vector2(1.72, 1.72)
	var target_color := Color.WHITE if selected else Color(0.55, 0.6, 0.72, 0.72)
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", target_scale, 0.18)
	tween.tween_property(sprite, "modulate", target_color, 0.18)
	tween.tween_property(label, "modulate", Color.WHITE if selected else Color(0.65, 0.65, 0.72, 0.75), 0.18)

func _start_night() -> void:
	_ensure_music_started()
	status.text = "%s ESTÁ LISTO" % selected_character.to_upper()
	start_button.disabled = true

func _ensure_music_started() -> void:
	# Web browsers may defer autoplay until the player's first interaction.
	if not background_music.playing:
		background_music.play()
