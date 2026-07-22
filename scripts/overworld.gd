extends Node2D

const CASTLE_CAMERA_Y := 540.0
const DEPARTURE_CAMERA_Y := 3210.0
const PAN_DURATION := 8.0
const TAVERNS: Array[Texture2D] = [
	preload("res://assets/overworld/taberna_01.png"),
	preload("res://assets/overworld/taberna_02.png"),
	preload("res://assets/overworld/taberna_03.png"),
]
const PUB_MEIGAS := preload("res://assets/overworld/pub_meigas.png")
const SUPERMERCADOS_TRUJILLO := preload("res://assets/overworld/supermercados_trujillo.png")
const START_POSITION := Vector2(960, 3460)
const CASTLE_POSITION := Vector2(960, 610)
const STEP_POSITIONS: Array[Array] = [
	[Vector2(785, 3025), Vector2(1115, 3025)],
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

func _ready() -> void:
	randomize()
	if background_music.stream is AudioStreamWAV:
		background_music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	camera.position = Vector2(960.0, CASTLE_CAMERA_Y)
	curtain.color.a = 1.0
	journey_label.modulate.a = 0.0
	_generate_route()
	_play_map_intro()

func _generate_route() -> void:
	_draw_connections()

	var node_count := 0
	for step in STEP_POSITIONS:
		node_count += step.size()
	var special_nodes := range(node_count)
	special_nodes.shuffle()
	var meigas_node: int = special_nodes[0]
	var trujillo_node: int = special_nodes[1]

	var node_index := 0
	for step_index in STEP_POSITIONS.size():
		for branch_index in STEP_POSITIONS[step_index].size():
			var building_texture: Texture2D = TAVERNS.pick_random()
			if node_index == meigas_node:
				building_texture = PUB_MEIGAS
			elif node_index == trujillo_node:
				building_texture = SUPERMERCADOS_TRUJILLO

			var building := Sprite2D.new()
			building.name = "Step%02dNode%02d" % [step_index + 1, branch_index + 1]
			building.texture = building_texture
			building.position = STEP_POSITIONS[step_index][branch_index]
			building.scale = Vector2(0.42, 0.42)
			building.z_index = 2
			$RouteBuildings.add_child(building)
			node_index += 1

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
