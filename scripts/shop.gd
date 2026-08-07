extends Control

const NPC_FRAME_SIZE := Vector2i(512, 768)
const NPC_ATLAS_COLUMNS := 4
const NPC_FRAME_COUNT := 8
const NPC_IDLE_PATH := "res://assets/npcs/trujillo/idle_atlas.png"
const NPC_DIALOGUE_PATH := "res://assets/npcs/trujillo/dialogue_atlas.png"
const COIN_TEXTURE_PATH := "res://assets/ui/currency/coins.png"
const FONT := preload("res://assets/fonts/press-start-2p-latin-400-normal.woff2")
const CARD_SIZE := Vector2(250, 375)
const CARD_POSITIONS := [Vector2(185, 260), Vector2(515, 260), Vector2(845, 260)]
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

@onready var npc_sprite: AnimatedSprite2D = $Interface/Shopkeeper/Sprite
@onready var speech_label: Label = $Interface/SpeechLabel
@onready var offers_root: Control = $Interface/Offers
@onready var exit_button: TextureButton = $Interface/ExitButton
@onready var curtain: ColorRect = $Interface/Curtain
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var offer_buttons: Array[TextureButton] = []
var sold_cards: Array[StringName] = []
var dialogue_playing := false


func _ready() -> void:
	_configure_music_loop()
	GameState.apply_music_volume(background_music)
	_prepare_shopkeeper()
	_build_offers()
	exit_button.pressed.connect(_leave_shop)
	speech_label.text = "¡Pasa, pasa! Tengo género del bueno."
	var reveal := create_tween()
	reveal.tween_property(curtain, "color:a", 0.0, 0.65)


func _exit_tree() -> void:
	if background_music != null:
		background_music.stop()
		background_music.stream = null


func _configure_music_loop() -> void:
	var ogg_stream := background_music.stream as AudioStreamOggVorbis
	if ogg_stream != null:
		ogg_stream.loop = true


func _prepare_shopkeeper() -> void:
	var idle_atlas := load(NPC_IDLE_PATH) as Texture2D
	var dialogue_atlas := load(NPC_DIALOGUE_PATH) as Texture2D
	if idle_atlas == null or dialogue_atlas == null:
		push_error("No se pudieron cargar las animaciones del tendero")
		return
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_npc_animation(frames, &"idle", idle_atlas, 6.0, true)
	_add_npc_animation(frames, &"dialogue", dialogue_atlas, 9.0, false)
	npc_sprite.sprite_frames = frames
	npc_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	npc_sprite.play(&"idle")


func _add_npc_animation(
	frames: SpriteFrames,
	animation_name: StringName,
	atlas_texture: Texture2D,
	fps: float,
	looping: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, fps)
	for frame_index in NPC_FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = atlas_texture
		atlas.region = Rect2i(
			(frame_index % NPC_ATLAS_COLUMNS) * NPC_FRAME_SIZE.x,
			floori(float(frame_index) / float(NPC_ATLAS_COLUMNS)) * NPC_FRAME_SIZE.y,
			NPC_FRAME_SIZE.x,
			NPC_FRAME_SIZE.y
		)
		frames.add_frame(animation_name, atlas)


func _build_offers() -> void:
	var inventory := GameState.prepare_shop_inventory()
	for offer_index in inventory.size():
		var card_id: StringName = inventory[offer_index]
		if not CARD_TEXTURE_PATHS.has(card_id):
			continue
		var texture := load(CARD_TEXTURE_PATHS[card_id]) as Texture2D
		if texture == null:
			continue
		var button := TextureButton.new()
		button.name = "ShopCard%d" % offer_index
		button.position = CARD_POSITIONS[offer_index]
		button.size = CARD_SIZE
		button.pivot_offset = CARD_SIZE / 2.0
		button.texture_normal = texture
		button.texture_hover = texture
		button.texture_pressed = texture
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.set_meta("card_id", card_id)
		button.pressed.connect(_buy_card.bind(button, card_id))
		button.mouse_entered.connect(_focus_offer.bind(button, true))
		button.mouse_exited.connect(_focus_offer.bind(button, false))
		offers_root.add_child(button)
		offer_buttons.append(button)

		var price := _card_price(card_id)
		var price_row := HBoxContainer.new()
		price_row.name = "Price%d" % offer_index
		price_row.position = CARD_POSITIONS[offer_index] + Vector2(40, 387)
		price_row.size = Vector2(170, 60)
		price_row.alignment = BoxContainer.ALIGNMENT_CENTER
		price_row.add_theme_constant_override("separation", 2)
		offers_root.add_child(price_row)
		var coin := TextureRect.new()
		coin.custom_minimum_size = Vector2(52, 52)
		coin.texture = load(COIN_TEXTURE_PATH) as Texture2D
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		price_row.add_child(coin)
		var price_label := Label.new()
		price_label.name = "Value"
		price_label.custom_minimum_size = Vector2(90, 52)
		price_label.text = str(price)
		price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price_label.add_theme_font_override("font", FONT)
		price_label.add_theme_font_size_override("font_size", 20)
		price_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38))
		price_label.add_theme_color_override("font_outline_color", Color(0.02, 0.01, 0.015))
		price_label.add_theme_constant_override("outline_size", 5)
		price_row.add_child(price_label)


func _card_price(card_id: StringName) -> int:
	var card_data: Dictionary = CardCatalog.CARDS[card_id]
	return 15 + int(card_data["cost"]) * 5


func _buy_card(button: TextureButton, card_id: StringName) -> void:
	if card_id in sold_cards:
		return
	var price := _card_price(card_id)
	if not GameState.spend_gold(price):
		speech_label.text = "Eso cuesta %d. Vuelve con más monedas." % price
		return
	GameState.add_reward_card(card_id)
	sold_cards.append(card_id)
	button.disabled = true
	button.modulate = Color(0.30, 0.30, 0.30, 0.62)
	var price_row := offers_root.get_node_or_null(
		"Price%d" % offer_buttons.find(button)
	) as HBoxContainer
	if price_row != null:
		var price_label := price_row.get_node_or_null("Value") as Label
		if price_label != null:
			price_label.text = "VENDIDA"
	speech_label.text = "¡Buena compra! Esa carta tiene mucho xeito."
	_play_dialogue()


func _play_dialogue() -> void:
	if dialogue_playing or npc_sprite.sprite_frames == null:
		return
	dialogue_playing = true
	npc_sprite.play(&"dialogue")
	await npc_sprite.animation_finished
	npc_sprite.play(&"idle")
	dialogue_playing = false


func _focus_offer(button: TextureButton, focused: bool) -> void:
	if button.disabled:
		return
	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		button, "scale", Vector2(1.055, 1.055) if focused else Vector2.ONE, 0.12
	)
	tween.tween_property(
		button,
		"modulate",
		Color(1.08, 1.04, 1.0) if focused else Color.WHITE,
		0.12
	)


func _leave_shop() -> void:
	exit_button.disabled = true
	GameState.complete_location()
	var fade := create_tween()
	fade.tween_property(curtain, "color:a", 1.0, 0.55)
	await fade.finished
	get_tree().change_scene_to_file("res://scenes/overworld.tscn")
