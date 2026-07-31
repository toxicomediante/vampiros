extends Node

const HUD_BASE := Vector2(24.0, 126.0)
const HUD_SIZE := Vector2(520.0, 199.0)
const HP_POS := Vector2(82.0, 28.0)
const HP_SIZE := Vector2(337.0, 49.0)
const DEF_POS := Vector2(82.0, 108.0)
const DEF_SIZE := Vector2(337.0, 49.0)
const MOTION := [Vector2(0, 0), Vector2(3, -4), Vector2(1, 4), Vector2(-4, 11), Vector2(0, 5), Vector2(4, -3)]
const STATUS_DATA := [
	["poison", 0, Color(0.35, 1.0, 0.35)],
	["strength", 1, Color(1.0, 0.28, 0.24)],
	["regeneration", 2, Color(0.35, 1.0, 0.35)],
	["autodefense", 3, Color(0.78, 0.78, 0.82)],
	["vulnerable", 4, Color(1.0, 0.28, 0.24)],
]

var combat: Node
var hud: Control
var player_row: HBoxContainer
var enemy_rows: Array[HBoxContainer] = []
var last_player_signature := ""
var last_enemy_signatures: Array[String] = []
var status_atlas: Texture2D

func _ready() -> void:
	process_priority = 100
	status_atlas = load("res://assets/ui/combat/status/status_atlas.png")

func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.name != "Combat":
		_reset()
		return
	if combat != scene:
		combat = scene
		call_deferred("_setup")
		return
	if not is_instance_valid(hud):
		return
	_animate_hud(delta)
	_refresh_statuses()

func _reset() -> void:
	combat = null
	hud = null
	player_row = null
	enemy_rows.clear()
	last_enemy_signatures.clear()
	last_player_signature = ""

func _setup() -> void:
	if combat == null:
		return
	hud = combat.get_node_or_null("Interface/PlayerHUD")
	if hud == null or hud.get_child_count() < 7:
		return
	hud.position = HUD_BASE
	hud.size = HUD_SIZE
	var frame := hud.get_child(4) as TextureRect
	if frame:
		frame.texture = load("res://assets/ui/combat/hp_def_frame.png")
		_resize(frame, Vector2.ZERO, HUD_SIZE)
	_resize(hud.get_child(0), HP_POS, HP_SIZE)
	_resize(hud.get_child(1), DEF_POS, DEF_SIZE)
	_resize_clip(hud.get_child(2), HP_POS, HP_SIZE)
	_resize_clip(hud.get_child(3), DEF_POS, DEF_SIZE)
	_resize(hud.get_child(5), HP_POS, HP_SIZE)
	_resize(hud.get_child(6), DEF_POS, DEF_SIZE)
	var old_status := combat.get("player_status_label") as Label
	if old_status:
		old_status.visible = false
	player_row = _make_row(hud, Vector2(10, 205), Vector2(540, 38))
	var enemies: Array = combat.get("enemies")
	for enemy in enemies:
		var old_enemy_status := enemy.get("status_label") as Label
		if old_enemy_status:
			old_enemy_status.visible = false
			var row := _make_row(combat.get_node("Interface"), old_enemy_status.position, old_enemy_status.size)
			enemy_rows.append(row)
			last_enemy_signatures.append("")
	_refresh_statuses(true)

func _resize(node: Node, pos: Vector2, size: Vector2) -> void:
	if node is Control:
		node.position = pos
		node.size = size

func _resize_clip(node: Node, pos: Vector2, size: Vector2) -> void:
	_resize(node, pos, size)
	if node.get_child_count() > 0:
		_resize(node.get_child(0), Vector2.ZERO, size)

func _make_row(parent: Node, pos: Vector2, size: Vector2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.position = pos
	row.size = size
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	return row

func _animate_hud(delta: float) -> void:
	var sprite := combat.get_node_or_null("CombatCharacter/Sprite") as AnimatedSprite2D
	if sprite == null:
		return
	var index := clampi(sprite.frame, 0, MOTION.size() - 1)
	var target := HUD_BASE + MOTION[index]
	hud.position = hud.position.lerp(target, 1.0 - exp(-delta * 15.0))

func _refresh_statuses(force := false) -> void:
	var player = combat.get("player")
	if player != null and player_row != null:
		var signature := _signature(player)
		if force or signature != last_player_signature:
			last_player_signature = signature
			_populate_row(player_row, player)
	var enemies: Array = combat.get("enemies")
	for i in mini(enemies.size(), enemy_rows.size()):
		var state = enemies[i].get("state")
		var signature := _signature(state)
		if force or signature != last_enemy_signatures[i]:
			last_enemy_signatures[i] = signature
			_populate_row(enemy_rows[i], state)

func _signature(state) -> String:
	var values: Array[String] = []
	for entry in STATUS_DATA:
		values.append(str(int(state.get(entry[0]))))
	return ":".join(values)

func _populate_row(row: HBoxContainer, state) -> void:
	for child in row.get_children():
		child.queue_free()
	for entry in STATUS_DATA:
		var amount := int(state.get(entry[0]))
		if amount <= 0:
			continue
		var atlas := AtlasTexture.new()
		atlas.atlas = status_atlas
		atlas.region = Rect2i(int(entry[1]) * 32, 0, 32, 32)
		var icon := TextureRect.new()
		icon.texture = atlas
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var number := Label.new()
		number.text = str(amount)
		number.custom_minimum_size = Vector2(27, 32)
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 18)
		number.add_theme_color_override("font_color", entry[2])
		number.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		number.add_theme_constant_override("shadow_offset_x", 2)
		number.add_theme_constant_override("shadow_offset_y", 2)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(number)
