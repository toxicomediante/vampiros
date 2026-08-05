extends Node2D

const CASTLE_CAMERA_Y := 540.0
const DEPARTURE_CAMERA_Y := 3210.0
const PAN_DURATION := 8.0
const DRAG_SENSITIVITY := 0.38
const MIN_CAMERA_Y := CASTLE_CAMERA_Y
const MAX_CAMERA_Y := DEPARTURE_CAMERA_Y
const LOCATION_SCALE := Vector2(0.54, 0.54)
const GLOW_TEXTURE_SIZE := Vector2i(448, 288)
const WARM_GLOW_COLOR := Color(1.0, 0.47, 0.08, 0.72)
const MEIGAS_PINK_GLOW_COLOR := Color(1.0, 0.06, 0.62, 0.72)
const MEIGAS_BLUE_GLOW_COLOR := Color(0.0, 0.70, 1.0, 0.68)
const CHARACTER_FRAME_SIZE := Vector2i(96, 128)
const CHARACTER_SHEET_COLUMNS := 6
const CHARACTER_SHEET_ROWS := 4
const DESTINATION_OFFSET := Vector2(0, 112)
const LOCATION_SELECTION_RADIUS := 210.0
const CLICK_DRAG_THRESHOLD := 18.0
const MIN_CHARACTER_SCALE := 1.35
const MAX_CHARACTER_SCALE := 1.65

const FULLSCREEN_TEXTURE := preload("res://assets/ui/generated/fullscreen.png")
const WINDOWED_TEXTURE := preload("res://assets/ui/generated/windowed.png")
const SOUND_ON_TEXTURE := preload("res://assets/ui/generated/sound_on.png")
const SOUND_OFF_TEXTURE := preload("res://assets/ui/generated/sound_off.png")
const TAVERN_PATHS: Array[String] = [
	"res://assets/overworld/taberna_01.png",
	"res://assets/overworld/taberna_02.png",
	"res://assets/overworld/taberna_03.png",
]
const PUB_MEIGAS_PATH := "res://assets/overworld/pub_meigas.png"
const SUPERMERCADOS_TRUJILLO_PATH := "res://assets/overworld/supermercados_trujillo.png"
const CHARACTER_SHEET_PATHS := {
	&"juan": "res://assets/characters/overworld/juan_overworld_animations.png",
	&"michu": "res://assets/characters/overworld/michu_overworld_animations.png",
}
const START_POSITION := Vector2(960, 3460)
const CASTLE_POSITION := Vector2(960, 610)
const STEP_POSITIONS: Array[Array] = [
	[Vector2(775, 3025), Vector2(1125, 3025)],
	[Vector2(555, 2725), Vector2(1370, 2725)],
	[Vector2(650, 2405), Vector2(1260, 2405)],
	[Vector2(515, 2075), Vector2(955, 2075), Vector2(1420, 2075)],
	[Vector2(610, 1745), Vector2(1280, 1745)],
	[Vector2(520, 1420), Vector2(990, 1420), Vector2(1450, 1420)],
	[Vector2(655, 1100), Vector2(1280, 1100)],
	[Vector2(760, 795), Vector2(1160, 795)],
]

@onready var camera: Camera2D = $Camera2D
@onready var curtain: ColorRect = $Interface/Curtain
@onready var journey_label: Label = $Interface/JourneyLabel
@onready var background_music: AudioStreamPlayer = $BackgroundMusic
@onready var fullscreen_button: TextureButton = $Interface/TopControls/FullscreenButton
@onready var sound_button: TextureButton = $Interface/TopControls/SoundButton
@onready var character_root: Node2D = $RouteCharacter
@onready var character_sprite: AnimatedSprite2D = $RouteCharacter/Sprite

var map_navigation_enabled := false
var mouse_dragging := false
var mouse_drag_distance := 0.0
var touch_tracking := false
var touch_drag_distance := 0.0
var route_choice_enabled := false
var character_moving := false
var sound_enabled := true
var route_locations: Array = []
var warm_glow_texture: GradientTexture2D
var meigas_pink_glow_texture: GradientTexture2D
var meigas_blue_glow_texture: GradientTexture2D
var additive_glow_material: CanvasItemMaterial

func _ready() -> void:
	randomize()
	_prepare_location_glows()
	sound_enabled = not AudioServer.is_bus_mute(AudioServer.get_bus_index("Master"))
	_configure_music_loop()
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	sound_button.pressed.connect(_toggle_sound)
	_refresh_control_icons()
	camera.position = Vector2(960.0, CASTLE_CAMERA_Y)
	curtain.color.a = 1.0
	journey_label.modulate.a = 0.0
	_generate_route()
	_prepare_character()
	_play_map_intro()


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

func _unhandled_input(event: InputEvent) -> void:
	if not map_navigation_enabled:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			touch_tracking = true
			touch_drag_distance = 0.0
		else:
			var was_tap := touch_tracking and touch_drag_distance <= CLICK_DRAG_THRESHOLD
			touch_tracking = false
			if was_tap:
				_try_select_first_destination(event.position)
	elif event is InputEventScreenDrag:
		touch_drag_distance += event.relative.length()
		_move_camera_from_drag(event.relative.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_dragging = true
			mouse_drag_distance = 0.0
		else:
			var was_click := mouse_dragging and mouse_drag_distance <= CLICK_DRAG_THRESHOLD
			mouse_dragging = false
			if was_click:
				_try_select_first_destination(event.position)
	elif event is InputEventMouseMotion and mouse_dragging:
		mouse_drag_distance += event.relative.length()
		_move_camera_from_drag(event.relative.y)
		get_viewport().set_input_as_handled()

func _move_camera_from_drag(vertical_delta: float) -> void:
	camera.position.y = clampf(
		camera.position.y - vertical_delta * DRAG_SENSITIVITY,
		MIN_CAMERA_Y,
		MAX_CAMERA_Y
	)

func _generate_route() -> void:
	GameState.ensure_run()
	GameState.ensure_route(STEP_POSITIONS, START_POSITION, CASTLE_POSITION)
	_draw_connections()
	route_locations.clear()

	var tavern_textures: Array[Texture2D] = []
	for texture_path: String in TAVERN_PATHS:
		var texture := _load_texture(texture_path)
		if texture != null:
			tavern_textures.append(texture)
	if tavern_textures.size() != TAVERN_PATHS.size():
		push_error("No se pudieron cargar todas las tabernas del mapa")
		return

	var pub_meigas := _load_texture(PUB_MEIGAS_PATH)
	var supermercados_trujillo := _load_texture(
		SUPERMERCADOS_TRUJILLO_PATH
	)
	if pub_meigas == null or supermercados_trujillo == null:
		return

	for step_index in STEP_POSITIONS.size():
		var step_locations: Array[Node2D] = []
		var step_blueprint: Array = GameState.run_route_nodes[step_index]
		for branch_index in STEP_POSITIONS[step_index].size():
			var node_blueprint: Dictionary = step_blueprint[branch_index]
			var location_kind: StringName = node_blueprint["kind"]
			var tavern_variant := int(node_blueprint["tavern_variant"])
			var building_texture: Texture2D = tavern_textures[
				tavern_variant
			]
			if location_kind == &"meigas":
				building_texture = pub_meigas
			elif location_kind == &"trujillo":
				building_texture = supermercados_trujillo

			var location := Node2D.new()
			location.name = "Step%02dNode%02d" % [
				step_index + 1,
				branch_index + 1,
			]
			location.position = STEP_POSITIONS[step_index][branch_index]
			location.set_meta("route_step", step_index)
			location.set_meta("route_branch", branch_index)
			location.set_meta("location_kind", location_kind)
			location.set_meta("tavern_variant", tavern_variant)
			$RouteBuildings.add_child(location)
			step_locations.append(location)

			if location_kind == &"tavern" or location_kind == &"trujillo":
				_add_glow(
					location.position + Vector2(0, 18),
					warm_glow_texture,
					Vector2(1.38, 1.08),
					0.0
				)
			elif location_kind == &"meigas":
				_add_glow(
					location.position + Vector2(-64, 4),
					meigas_pink_glow_texture,
					Vector2(1.06, 1.04),
					0.0
				)
				_add_glow(
					location.position + Vector2(64, 4),
					meigas_blue_glow_texture,
					Vector2(1.06, 1.04),
					0.85
				)

			var building := Sprite2D.new()
			building.name = "Building"
			building.texture = building_texture
			building.scale = LOCATION_SCALE
			building.z_index = 2
			location.add_child(building)
		route_locations.append(step_locations)

func _prepare_character() -> void:
	var character_id: StringName = GameState.selected_character
	if not CHARACTER_SHEET_PATHS.has(character_id):
		character_id = &"michu"
	var sheet := _load_texture(CHARACTER_SHEET_PATHS[character_id])
	if sheet == null:
		return
	character_sprite.sprite_frames = _build_character_frames(
		sheet,
		character_id
	)
	character_sprite.flip_h = false
	character_sprite.play(&"idle")
	character_root.position = _current_character_position()
	var current_scale := _perspective_scale(character_root.position.y)
	character_root.scale = Vector2.ONE * current_scale


func _current_character_position() -> Vector2:
	var step_index := GameState.current_route_step
	var branch_index := GameState.current_route_branch
	if (
		step_index >= 0
		and step_index < route_locations.size()
		and branch_index >= 0
		and branch_index < route_locations[step_index].size()
	):
		return (
			route_locations[step_index][branch_index].position
			+ DESTINATION_OFFSET
		)
	if step_index >= route_locations.size() and not route_locations.is_empty():
		return CASTLE_POSITION + DESTINATION_OFFSET
	return START_POSITION

func _load_texture(resource_path: String) -> Texture2D:
	var texture := load(resource_path) as Texture2D
	if texture == null:
		push_error("No se pudo cargar la textura: %s" % resource_path)
	return texture

func _build_character_frames(sheet: Texture2D, character_id: StringName) -> SpriteFrames:
	assert(
		sheet.get_width() == CHARACTER_SHEET_COLUMNS * CHARACTER_FRAME_SIZE.x,
		"La hoja del overworld debe tener seis columnas exactas"
	)
	assert(
		sheet.get_height() == CHARACTER_SHEET_ROWS * CHARACTER_FRAME_SIZE.y,
		"La hoja del overworld debe tener cuatro filas exactas"
	)

	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var idle_speed := 5.0 if character_id == &"michu" else 4.2
	var walk_speed := 8.0 if character_id == &"michu" else 6.6
	_add_sheet_animation(frames, sheet, &"idle", 0, 6, idle_speed, true)
	_add_sheet_animation(frames, sheet, &"volteo", 1, 4, 8.0, false)
	_add_sheet_animation(frames, sheet, &"caminar", 2, 4, walk_speed, true)
	_add_sheet_animation(frames, sheet, &"volteo2", 3, 4, 8.0, false)
	return frames

func _add_sheet_animation(
	frames: SpriteFrames,
	sheet: Texture2D,
	animation_name: StringName,
	row: int,
	frame_count: int,
	speed: float,
	looping: bool
) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, looping)
	frames.set_animation_speed(animation_name, speed)
	for column in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2i(
			column * CHARACTER_FRAME_SIZE.x,
			row * CHARACTER_FRAME_SIZE.y,
			CHARACTER_FRAME_SIZE.x,
			CHARACTER_FRAME_SIZE.y
		)
		frames.add_frame(animation_name, atlas)

func _perspective_scale(world_y: float) -> float:
	var depth := inverse_lerp(CASTLE_POSITION.y, START_POSITION.y, world_y)
	return lerpf(MIN_CHARACTER_SCALE, MAX_CHARACTER_SCALE, clampf(depth, 0.0, 1.0))

func _try_select_first_destination(screen_position: Vector2) -> void:
	if not route_choice_enabled or character_moving or route_locations.is_empty():
		return

	var world_position := get_canvas_transform().affine_inverse() * screen_position
	if GameState.castle_is_next():
		if (
			world_position.distance_squared_to(CASTLE_POSITION)
			<= LOCATION_SELECTION_RADIUS * LOCATION_SELECTION_RADIUS
		):
			_travel_to_castle()
		return

	var closest_location: Node2D
	var closest_distance := INF
	for location: Node2D in _available_destination_nodes():
		var distance := world_position.distance_squared_to(location.position)
		if distance < closest_distance:
			closest_location = location
			closest_distance = distance

	if (
		closest_location != null
		and closest_distance
		<= LOCATION_SELECTION_RADIUS * LOCATION_SELECTION_RADIUS
	):
		_travel_to_location(closest_location)


func _available_destination_nodes() -> Array[Node2D]:
	var available: Array[Node2D] = []
	var step_index := GameState.next_route_step()
	if step_index < 0 or step_index >= route_locations.size():
		return available
	for branch_index: int in GameState.next_route_branches():
		if branch_index >= 0 and branch_index < route_locations[step_index].size():
			available.append(route_locations[step_index][branch_index])
	return available


func _enable_first_destination_choice() -> void:
	if route_locations.is_empty():
		return
	route_choice_enabled = true
	if GameState.castle_is_next():
		journey_label.text = "TOCA EL CASTILLO PARA CONTINUAR"
		journey_label.modulate.a = 1.0
		return

	for location: Node2D in _available_destination_nodes():
		var building: Sprite2D = location.get_node("Building")
		var pulse := create_tween().set_loops()
		pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(
			building,
			"scale",
			LOCATION_SCALE * 1.06,
			0.72
		)
		pulse.parallel().tween_property(
			building,
			"modulate",
			Color(1.16, 1.12, 1.02, 1.0),
			0.72
		)
		pulse.tween_property(building, "scale", LOCATION_SCALE, 0.72)
		pulse.parallel().tween_property(
			building,
			"modulate",
			Color.WHITE,
			0.72
		)
		location.set_meta("choice_pulse", pulse)


func _disable_first_destination_choice() -> void:
	route_choice_enabled = false
	if route_locations.is_empty() or GameState.castle_is_next():
		return
	for location: Node2D in _available_destination_nodes():
		var pulse = location.get_meta("choice_pulse", null)
		if pulse is Tween:
			pulse.kill()
		location.remove_meta("choice_pulse")
		var building: Sprite2D = location.get_node("Building")
		building.scale = LOCATION_SCALE
		building.modulate = Color.WHITE


func _travel_to_location(location: Node2D) -> void:
	character_moving = true
	map_navigation_enabled = false
	mouse_dragging = false
	touch_tracking = false
	_disable_first_destination_choice()

	var destination := location.position + DESTINATION_OFFSET
	character_sprite.flip_h = destination.x < character_root.position.x
	journey_label.text = "RUMBO AL SIGUIENTE LOCAL..."
	journey_label.modulate.a = 1.0

	await _play_character_transition(&"volteo")
	character_sprite.play(&"caminar")
	var distance := character_root.position.distance_to(destination)
	var travel_duration := clampf(distance / 155.0, 1.9, 3.0)
	var destination_scale := _perspective_scale(destination.y)
	var travel := create_tween().set_parallel(true)
	travel.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(
		character_root,
		"position",
		destination,
		travel_duration
	)
	travel.tween_property(
		character_root,
		"scale",
		Vector2.ONE * destination_scale,
		travel_duration
	)
	await travel.finished

	await _play_character_transition(&"volteo2")
	character_sprite.flip_h = false
	character_sprite.play(&"idle")

	var location_kind: StringName = location.get_meta(
		"location_kind",
		&"tavern"
	)
	var step_index := int(location.get_meta("route_step", -1))
	var branch_index := int(location.get_meta("route_branch", -1))
	var tavern_variant := int(location.get_meta("tavern_variant", 0))
	GameState.begin_route_destination(
		step_index,
		branch_index,
		location_kind,
		tavern_variant
	)

	journey_label.text = (
		"ENTRANDO EN SUPERMERCADOS TRUJILLO..."
		if location_kind == &"trujillo"
		else "ENTRANDO EN EL LOCAL..."
	)
	journey_label.modulate.a = 1.0

	var enter_interior := create_tween()
	enter_interior.tween_interval(0.35)
	enter_interior.tween_property(curtain, "color:a", 1.0, 0.55)
	await enter_interior.finished

	# La escena específica de Trujillo se conectará cuando incorporemos su
	# paquete definitivo. Mientras la actualización está en su rama de trabajo,
	# la navegación conserva el destino pendiente sin reiniciar la ruta.
	var change_error := get_tree().change_scene_to_file(
		"res://scenes/combat_loader.tscn"
	)
	if change_error != OK:
		push_error("No se pudo abrir el siguiente local: %d" % change_error)
		journey_label.text = "NO SE PUDO ENTRAR EN EL LOCAL"
		var recover := create_tween()
		recover.tween_property(curtain, "color:a", 0.0, 0.35)
		await recover.finished
		character_moving = false
		map_navigation_enabled = true
		_enable_first_destination_choice()


func _travel_to_castle() -> void:
	character_moving = true
	map_navigation_enabled = false
	mouse_dragging = false
	touch_tracking = false
	_disable_first_destination_choice()

	var destination := CASTLE_POSITION + DESTINATION_OFFSET
	character_sprite.flip_h = destination.x < character_root.position.x
	journey_label.text = "EL CASTILLO AGUARDA..."
	journey_label.modulate.a = 1.0

	await _play_character_transition(&"volteo")
	character_sprite.play(&"caminar")
	var travel := create_tween().set_parallel(true)
	travel.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(character_root, "position", destination, 2.2)
	travel.tween_property(
		character_root,
		"scale",
		Vector2.ONE * _perspective_scale(destination.y),
		2.2
	)
	await travel.finished
	GameState.complete_castle_destination()

	var fade := create_tween()
	fade.tween_property(curtain, "color:a", 1.0, 0.65)
	await fade.finished
	var change_error := get_tree().change_scene_to_file(
		"res://scenes/coming_soon.tscn"
	)
	if change_error != OK:
		push_error("No se pudo abrir la escena Próximamente: %d" % change_error)

func _play_character_transition(animation_name: StringName) -> void:
	character_sprite.play(animation_name)
	await character_sprite.animation_finished

func _prepare_location_glows() -> void:
	warm_glow_texture = _create_glow_texture(WARM_GLOW_COLOR)
	meigas_pink_glow_texture = _create_glow_texture(MEIGAS_PINK_GLOW_COLOR)
	meigas_blue_glow_texture = _create_glow_texture(MEIGAS_BLUE_GLOW_COLOR)
	additive_glow_material = CanvasItemMaterial.new()
	additive_glow_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

func _create_glow_texture(glow_color: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.44, 0.76, 1.0])
	gradient.colors = PackedColorArray([
		glow_color,
		Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 0.62),
		Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * 0.18),
		Color(glow_color.r, glow_color.g, glow_color.b, 0.0),
	])

	var texture := GradientTexture2D.new()
	texture.width = GLOW_TEXTURE_SIZE.x
	texture.height = GLOW_TEXTURE_SIZE.y
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	return texture

func _add_glow(
	world_position: Vector2,
	glow_texture: GradientTexture2D,
	base_scale: Vector2,
	phase_delay: float
) -> void:
	var glow := Sprite2D.new()
	glow.texture = glow_texture
	glow.position = world_position
	glow.scale = base_scale * 0.93
	glow.material = additive_glow_material
	glow.modulate.a = 0.86
	$RouteGlows.add_child(glow)

	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if phase_delay > 0.0:
		pulse.tween_interval(phase_delay)
	pulse.tween_property(glow, "scale", base_scale * 1.10, 1.65)
	pulse.parallel().tween_property(glow, "modulate:a", 1.0, 1.65)
	pulse.tween_property(glow, "scale", base_scale * 0.93, 1.65)
	pulse.parallel().tween_property(glow, "modulate:a", 0.86, 1.65)

func _draw_connections() -> void:
	var layer_positions: Array = []
	layer_positions.append([START_POSITION])
	for step: Array in STEP_POSITIONS:
		layer_positions.append(step)
	layer_positions.append([CASTLE_POSITION])

	for layer_index in GameState.run_route_connections.size():
		var from_nodes: Array = layer_positions[layer_index]
		var to_nodes: Array = layer_positions[layer_index + 1]
		var layer: Dictionary = GameState.run_route_connections[layer_index]
		for from_index in layer:
			for to_index: int in layer[from_index]:
				_draw_connection(
					from_nodes[int(from_index)],
					to_nodes[to_index]
				)


func _draw_connection(from_position: Vector2, to_position: Vector2) -> void:
	var path := Line2D.new()
	path.name = "Route"
	path.width = 12.0
	path.default_color = Color(0.94, 0.67, 0.34, 0.82)
	path.antialiased = false
	path.z_index = 1
	path.add_point(from_position)
	path.add_point(to_position)
	$RouteLines.add_child(path)

func _play_map_intro() -> void:
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(curtain, "color:a", 0.0, 0.8)
	reveal.tween_property(
		journey_label,
		"modulate:a",
		1.0,
		0.8
	).set_delay(0.25)
	await reveal.finished

	if GameState.current_route_step < 0:
		var pan := create_tween()
		pan.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pan.tween_property(
			camera,
			"position:y",
			DEPARTURE_CAMERA_Y,
			PAN_DURATION
		)
		await pan.finished
	else:
		camera.position.y = clampf(
			character_root.position.y,
			MIN_CAMERA_Y,
			MAX_CAMERA_Y
		)

	var finish := create_tween()
	finish.tween_property(journey_label, "modulate:a", 0.0, 0.35)
	await finish.finished
	map_navigation_enabled = true
	_enable_first_destination_choice()
	if not GameState.castle_is_next():
		journey_label.text = "TOCA UN LOCAL PARA CAMINAR"
	var hint := create_tween()
	hint.tween_property(journey_label, "modulate:a", 1.0, 0.35)
	hint.tween_interval(3.2)
	hint.tween_property(journey_label, "modulate:a", 0.62, 0.45)

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
	fullscreen_button.tooltip_text = "SALIR DE PANTALLA COMPLETA" if is_fullscreen else "PANTALLA COMPLETA"
	sound_button.texture_normal = SOUND_ON_TEXTURE if sound_enabled else SOUND_OFF_TEXTURE
	sound_button.tooltip_text = "DESACTIVAR SONIDO" if sound_enabled else "ACTIVAR SONIDO"
