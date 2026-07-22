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
const TAVERNS: Array[Texture2D] = [
	preload("res://assets/overworld/taberna_01.png"),
	preload("res://assets/overworld/taberna_02.png"),
	preload("res://assets/overworld/taberna_03.png"),
]
const PUB_MEIGAS := preload("res://assets/overworld/pub_meigas.png")
const SUPERMERCADOS_TRUJILLO := preload("res://assets/overworld/supermercados_trujillo.png")
const CHARACTER_SHEETS := {
	&"juan": preload("res://assets/characters/overworld/juan_overworld_animations.png"),
	&"michu": preload("res://assets/characters/overworld/michu_overworld_animations.png"),
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
	if background_music.stream is AudioStreamWAV:
		background_music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	sound_button.pressed.connect(_toggle_sound)
	_refresh_control_icons()
	camera.position = Vector2(960.0, CASTLE_CAMERA_Y)
	curtain.color.a = 1.0
	journey_label.modulate.a = 0.0
	_generate_route()
	_prepare_character()
	_play_map_intro()

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
	_draw_connections()
	route_locations.clear()

	var node_count := 0
	for step in STEP_POSITIONS:
		node_count += step.size()
	var special_nodes := range(node_count)
	special_nodes.shuffle()
	var meigas_node: int = special_nodes[0]
	var trujillo_node: int = special_nodes[1]

	var node_index := 0
	for step_index in STEP_POSITIONS.size():
		var step_locations: Array[Node2D] = []
		for branch_index in STEP_POSITIONS[step_index].size():
			var building_texture: Texture2D = TAVERNS.pick_random()
			var location_kind := "tavern"
			if node_index == meigas_node:
				building_texture = PUB_MEIGAS
				location_kind = "meigas"
			elif node_index == trujillo_node:
				building_texture = SUPERMERCADOS_TRUJILLO
				location_kind = "trujillo"

			var location := Node2D.new()
			location.name = "Step%02dNode%02d" % [step_index + 1, branch_index + 1]
			location.position = STEP_POSITIONS[step_index][branch_index]
			location.set_meta("location_kind", location_kind)
			$RouteBuildings.add_child(location)
			step_locations.append(location)

			if location_kind == "tavern" or location_kind == "trujillo":
				_add_glow(
					location.position + Vector2(0, 18),
					warm_glow_texture,
					Vector2(1.38, 1.08),
					0.0
				)
			elif location_kind == "meigas":
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
			node_index += 1
		route_locations.append(step_locations)

func _prepare_character() -> void:
	var character_id: StringName = GameState.selected_character
	if not CHARACTER_SHEETS.has(character_id):
		character_id = &"michu"
	var sheet: Texture2D = CHARACTER_SHEETS[character_id]
	character_sprite.sprite_frames = _build_character_frames(sheet, character_id)
	character_sprite.flip_h = false
	character_sprite.play(&"idle")
	character_root.position = START_POSITION
	var start_scale := _perspective_scale(START_POSITION.y)
	character_root.scale = Vector2.ONE * start_scale

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
	var closest_location: Node2D
	var closest_distance := INF
	for location: Node2D in route_locations[0]:
		var distance := world_position.distance_squared_to(location.position)
		if distance < closest_distance:
			closest_location = location
			closest_distance = distance

	if closest_location != null and closest_distance <= LOCATION_SELECTION_RADIUS * LOCATION_SELECTION_RADIUS:
		_travel_to_location(closest_location)

func _enable_first_destination_choice() -> void:
	if route_locations.is_empty():
		return
	route_choice_enabled = true
	for location: Node2D in route_locations[0]:
		var building: Sprite2D = location.get_node("Building")
		var pulse := create_tween().set_loops()
		pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(building, "scale", LOCATION_SCALE * 1.06, 0.72)
		pulse.parallel().tween_property(building, "modulate", Color(1.16, 1.12, 1.02, 1.0), 0.72)
		pulse.tween_property(building, "scale", LOCATION_SCALE, 0.72)
		pulse.parallel().tween_property(building, "modulate", Color.WHITE, 0.72)
		location.set_meta("choice_pulse", pulse)

func _disable_first_destination_choice() -> void:
	route_choice_enabled = false
	if route_locations.is_empty():
		return
	for location: Node2D in route_locations[0]:
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
	journey_label.text = "RUMBO AL PRIMER LOCAL..."
	journey_label.modulate.a = 1.0

	await _play_character_transition(&"volteo")
	character_sprite.play(&"caminar")
	var distance := character_root.position.distance_to(destination)
	var travel_duration := clampf(distance / 155.0, 1.9, 3.0)
	var destination_scale := _perspective_scale(destination.y)
	var travel := create_tween().set_parallel(true)
	travel.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(character_root, "position", destination, travel_duration)
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
	character_moving = false
	map_navigation_enabled = true
	journey_label.text = "DESTINO ALCANZADO"
	var finish_message := create_tween()
	finish_message.tween_interval(1.8)
	finish_message.tween_property(journey_label, "modulate:a", 0.0, 0.45)

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
	_connect_layers([START_POSITION], STEP_POSITIONS[0])
	for step_index in STEP_POSITIONS.size() - 1:
		_connect_layers(STEP_POSITIONS[step_index], STEP_POSITIONS[step_index + 1])
	_connect_layers(STEP_POSITIONS[-1], [CASTLE_POSITION])

func _connect_layers(from_nodes: Array, to_nodes: Array) -> void:
	var connections := {}
	for from_index in from_nodes.size():
		var nearest_to := _nearest_index(from_nodes[from_index], to_nodes)
		connections[Vector2i(from_index, nearest_to)] = true
	for to_index in to_nodes.size():
		var nearest_from := _nearest_index(to_nodes[to_index], from_nodes)
		connections[Vector2i(nearest_from, to_index)] = true

	# Una unión extra ocasional produce rutas menos simétricas sin crear callejones.
	if from_nodes.size() > 1 and to_nodes.size() > 1 and randf() < 0.7:
		connections[Vector2i(randi_range(0, from_nodes.size() - 1), randi_range(0, to_nodes.size() - 1))] = true

	for connection in connections:
		var path := Line2D.new()
		path.name = "Route"
		path.width = 12.0
		path.default_color = Color(0.94, 0.67, 0.34, 0.82)
		path.antialiased = false
		path.z_index = 1
		path.add_point(from_nodes[connection.x])
		path.add_point(to_nodes[connection.y])
		$RouteLines.add_child(path)

func _nearest_index(origin: Vector2, candidates: Array) -> int:
	var nearest := 0
	var nearest_distance := INF
	for candidate_index in candidates.size():
		var distance: float = origin.distance_squared_to(candidates[candidate_index])
		if distance < nearest_distance:
			nearest = candidate_index
			nearest_distance = distance
	return nearest

func _play_map_intro() -> void:
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(curtain, "color:a", 0.0, 0.8)
	reveal.tween_property(journey_label, "modulate:a", 1.0, 0.8).set_delay(0.25)
	await reveal.finished

	var pan := create_tween()
	pan.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pan.tween_property(camera, "position:y", DEPARTURE_CAMERA_Y, PAN_DURATION)
	await pan.finished

	var finish := create_tween()
	finish.tween_property(journey_label, "modulate:a", 0.0, 0.55)
	await finish.finished
	map_navigation_enabled = true
	_enable_first_destination_choice()
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
