extends "res://scripts/combat.gd"

const COMPACT_UI_POSITION := Vector2(24.0, 126.0)
const COMPACT_UI_SIZE := Vector2(520.0, 199.0)
const COMPACT_HP_BAR_POSITION := Vector2(82.0, 28.0)
const COMPACT_HP_BAR_SIZE := Vector2(337.0, 49.0)
const COMPACT_DEF_BAR_POSITION := Vector2(82.0, 108.0)
const COMPACT_DEF_BAR_SIZE := Vector2(337.0, 49.0)
const COMPACT_STATUS_POSITION := Vector2(0.0, 205.0)
const COMPACT_STATUS_SIZE := Vector2(520.0, 38.0)
const COMPACT_STATUS_ICON_SIZE := Vector2(32.0, 32.0)
const COMPACT_STATUS_FRAME_SIZE := Vector2i(32, 32)
const COMPACT_FRAME_PATH := "res://assets/ui/combat/hp_def_frame_compact.png"
const COMPACT_STATUS_ATLAS_PATH := "res://assets/ui/combat/status/status_atlas.png"
const COMPACT_FRAME_OVERLAY_SHADER := preload(
	"res://shaders/hud_frame_overlay.gdshader"
)
const COMPACT_HUD_VERTICAL_OFFSETS := [0.0, -3.0, -1.0, 4.0, 2.0, -2.0]
const COMPACT_STATUS_DEFINITIONS := [
	{
		"property": &"poison",
		"frame": 0,
		"color": Color(0.38, 1.0, 0.34),
	},
	{
		"property": &"strength",
		"frame": 1,
		"color": Color(1.0, 0.27, 0.20),
	},
	{
		"property": &"regeneration",
		"frame": 2,
		"color": Color(0.38, 1.0, 0.34),
	},
	{
		"property": &"autodefense",
		"frame": 3,
		"color": Color(0.82, 0.84, 0.88),
	},
	{
		"property": &"vulnerable",
		"frame": 4,
		"color": Color(1.0, 0.27, 0.20),
	},
]

var compact_status_atlas_texture: Texture2D
var player_status_row: HBoxContainer
var player_status_signature := ""
var enemy_status_signatures: Array[String] = []


func _ready() -> void:
	super()
	_apply_compact_ui()
	_refresh_all_ui()


func _process(delta: float) -> void:
	_sync_player_hud_motion(delta)
	_sync_compact_bar_widths()
	_refresh_compact_status_rows()


func _apply_compact_ui() -> void:
	if not is_instance_valid(player_hud):
		return

	var compact_frame := _load_texture(COMPACT_FRAME_PATH)
	compact_status_atlas_texture = _load_texture(COMPACT_STATUS_ATLAS_PATH)
	if compact_frame == null or compact_status_atlas_texture == null:
		push_error("No se pudo cargar la interfaz compacta de combate")
		return

	player_hud_base_position = COMPACT_UI_POSITION
	player_hud.position = player_hud_base_position
	player_hud.size = COMPACT_UI_SIZE

	var direct_textures: Array[TextureRect] = []
	for child: Node in player_hud.get_children():
		if child is TextureRect:
			direct_textures.append(child as TextureRect)
	if direct_textures.size() != 1:
		push_error("La interfaz HP/DEF base no contiene su marco esperado")
		return

	_configure_color_rect(
		player_hp_background,
		COMPACT_HP_BAR_POSITION,
		COMPACT_HP_BAR_SIZE
	)
	_configure_color_rect(
		player_block_background,
		COMPACT_DEF_BAR_POSITION,
		COMPACT_DEF_BAR_SIZE
	)
	direct_textures[0].texture = compact_frame
	_configure_texture_rect(direct_textures[0], Vector2.ZERO, COMPACT_UI_SIZE)
	_configure_compact_bar_layers(direct_textures[0])

	_configure_bar_clip(
		player_hp_clip,
		COMPACT_HP_BAR_POSITION,
		COMPACT_HP_BAR_SIZE
	)
	_configure_bar_clip(
		player_block_clip,
		COMPACT_DEF_BAR_POSITION,
		COMPACT_DEF_BAR_SIZE
	)
	_configure_label(
		player_hp_label,
		COMPACT_HP_BAR_POSITION,
		COMPACT_HP_BAR_SIZE
	)
	_configure_label(
		player_block_label,
		COMPACT_DEF_BAR_POSITION,
		COMPACT_DEF_BAR_SIZE
	)

	player_status_label.visible = false
	player_status_row = _make_compact_status_row(
		"PlayerStatusRow",
		COMPACT_STATUS_POSITION,
		COMPACT_STATUS_SIZE
	)
	player_hud.add_child(player_status_row)

	enemy_status_signatures.clear()
	for enemy_index in enemies.size():
		var enemy: Dictionary = enemies[enemy_index]
		var old_status: Label = enemy["status_label"]
		old_status.visible = false
		var position: Vector2 = enemy["sprite"].position
		var status_row := _make_compact_status_row(
			"EnemyStatusRow%d" % enemy_index,
			Vector2(position.x - 180.0, 154.0),
			Vector2(360.0, 38.0)
		)
		interface.add_child(status_row)
		enemy["status_row"] = status_row
		enemy_status_signatures.append("")

	interface.move_child(curtain, interface.get_child_count() - 1)


func _configure_compact_bar_layers(base_frame: TextureRect) -> void:
	base_frame.name = "PlayerHUDFrame"
	base_frame.z_index = 1
	var frame_material := ShaderMaterial.new()
	frame_material.shader = COMPACT_FRAME_OVERLAY_SHADER
	base_frame.material = frame_material
	player_hp_background.z_index = -1
	player_block_background.z_index = -1
	player_hp_clip.z_index = 0
	player_block_clip.z_index = 0
	player_hp_label.z_index = 2
	player_block_label.z_index = 2


func _configure_texture_rect(
	texture_rect: TextureRect,
	position: Vector2,
	size: Vector2
) -> void:
	texture_rect.position = position
	texture_rect.size = size


func _configure_color_rect(
	color_rect: ColorRect,
	position: Vector2,
	size: Vector2
) -> void:
	if not is_instance_valid(color_rect):
		return
	color_rect.position = position
	color_rect.size = size


func _configure_bar_clip(clip: Control, position: Vector2, size: Vector2) -> void:
	clip.position = position
	clip.size = size
	var fill := clip.get_node_or_null("Fill") as ColorRect
	if is_instance_valid(fill):
		fill.size = size
	var highlight := clip.get_node_or_null("Highlight") as ColorRect
	if is_instance_valid(highlight):
		highlight.size = Vector2(size.x, maxf(2.0, floorf(size.y * 0.18)))


func _configure_label(label: Label, position: Vector2, size: Vector2) -> void:
	label.position = position
	label.size = size
	_configure_bar_value_label(label)


func _make_compact_status_row(
	row_name: String,
	position: Vector2,
	size: Vector2
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = row_name
	row.position = position
	row.size = size
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.visible = false
	return row


func _populate_compact_status_row(
	row: HBoxContainer,
	state: CombatantState
) -> void:
	if not is_instance_valid(row):
		return
	for child: Node in row.get_children():
		child.free()

	for definition: Dictionary in COMPACT_STATUS_DEFINITIONS:
		var amount := int(state.get(definition["property"]))
		if amount <= 0:
			continue

		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 2)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(item)

		var atlas := AtlasTexture.new()
		atlas.atlas = compact_status_atlas_texture
		atlas.region = Rect2i(
			int(definition["frame"]) * COMPACT_STATUS_FRAME_SIZE.x,
			0,
			COMPACT_STATUS_FRAME_SIZE.x,
			COMPACT_STATUS_FRAME_SIZE.y
		)
		var icon := TextureRect.new()
		icon.texture = atlas
		icon.custom_minimum_size = COMPACT_STATUS_ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_child(icon)

		var value_label := _make_label(
			Vector2.ZERO,
			Vector2(28.0, COMPACT_STATUS_ICON_SIZE.y),
			18,
			definition["color"]
		)
		value_label.custom_minimum_size = Vector2(
			28.0,
			COMPACT_STATUS_ICON_SIZE.y
		)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.text = str(amount)
		item.add_child(value_label)

	row.visible = row.get_child_count() > 0


func _status_signature(state: CombatantState) -> String:
	return "%d:%d:%d:%d:%d:%d" % [
		state.hp,
		state.poison,
		state.strength,
		state.regeneration,
		state.autodefense,
		state.vulnerable,
	]


func _refresh_compact_status_rows(force := false) -> void:
	if not is_instance_valid(player_status_row):
		return

	var current_player_signature := _status_signature(player)
	if force or current_player_signature != player_status_signature:
		player_status_signature = current_player_signature
		_populate_compact_status_row(player_status_row, player)

	for enemy_index in enemies.size():
		var enemy: Dictionary = enemies[enemy_index]
		var state: CombatantState = enemy["state"]
		var status_row := enemy.get("status_row") as HBoxContainer
		if state.hp <= 0:
			var hp_label: Label = enemy["hp_label"]
			if is_instance_valid(hp_label):
				hp_label.visible = false
			if is_instance_valid(status_row):
				status_row.visible = false
			continue

		while enemy_status_signatures.size() <= enemy_index:
			enemy_status_signatures.append("")
		var current_enemy_signature := _status_signature(state)
		if force or current_enemy_signature != enemy_status_signatures[enemy_index]:
			enemy_status_signatures[enemy_index] = current_enemy_signature
			_populate_compact_status_row(status_row, state)


func _sync_player_hud_motion(delta: float) -> void:
	if not is_instance_valid(player_hud) or not is_instance_valid(character_sprite):
		return
	var vertical_offset := _interpolated_hud_vertical_offset(
		COMPACT_HUD_VERTICAL_OFFSETS
	)
	var smoothing := 1.0 - exp(-delta * 20.0)
	player_hud.position.x = player_hud_base_position.x
	player_hud.position.y = lerpf(
		player_hud.position.y,
		player_hud_base_position.y + vertical_offset,
		smoothing
	)


func _sync_compact_bar_widths() -> void:
	if (
		player == null
		or not is_instance_valid(player_hp_clip)
		or not is_instance_valid(player_block_clip)
	):
		return
	player_hp_clip.size.x = (
		COMPACT_HP_BAR_SIZE.x
		* clampf(float(player.hp) / float(player.max_hp), 0.0, 1.0)
	)
	player_block_clip.size.x = (
		COMPACT_DEF_BAR_SIZE.x
		* clampf(float(player.block) / 20.0, 0.0, 1.0)
	)


func _refresh_all_ui() -> void:
	super()
	_sync_compact_bar_widths()
	_refresh_compact_status_rows(true)


func _remove_dead_enemies() -> void:
	super()
	_refresh_compact_status_rows(true)
