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
const LEVEL_POSITIONS: Array[Array] = [
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
	_generate_route_buildings()
	_play_map_intro()

func _generate_route_buildings() -> void:
	var special_levels := range(LEVEL_POSITIONS.size())
	special_levels.shuffle()
	var meigas_level: int = special_levels[0]
	var trujillo_level: int = special_levels[1]

	for level_index in LEVEL_POSITIONS.size():
		var choices: Array = LEVEL_POSITIONS[level_index]
		var building_texture: Texture2D
		if level_index == meigas_level:
			building_texture = PUB_MEIGAS
		elif level_index == trujillo_level:
			building_texture = SUPERMERCADOS_TRUJILLO
		else:
			building_texture = TAVERNS.pick_random()

		var building := Sprite2D.new()
		building.name = "Level%02dBuilding" % (level_index + 1)
		building.texture = building_texture
		building.position = choices.pick_random()
		building.scale = Vector2(0.5, 0.5)
		building.z_index = 1
		$RouteBuildings.add_child(building)

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
