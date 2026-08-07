extends CanvasLayer

@export var show_currency := true

@onready var currency: Control = $Currency
@onready var gold_value: Label = $Currency/GoldValue
@onready var overlay: ColorRect = $Overlay
@onready var gear_button: TextureButton = $GearButton
@onready var fullscreen_checkbox: TextureButton = $Overlay/FullscreenCheckbox
@onready var slider_area: Control = $Overlay/SliderArea
@onready var volume_knob: TextureRect = $Overlay/SliderArea/VolumeKnob

const CHECKBOX_EMPTY := preload("res://assets/ui/options/checkbox_empty.png")
const CHECKBOX_CHECKED := preload("res://assets/ui/options/checkbox_checked.png")

var slider_dragging := false


func _ready() -> void:
	currency.visible = show_currency
	overlay.visible = false
	gear_button.pressed.connect(_toggle_options)
	fullscreen_checkbox.pressed.connect(_toggle_fullscreen)
	slider_area.gui_input.connect(_on_slider_gui_input)
	if not GameState.gold_changed.is_connected(_refresh_gold):
		GameState.gold_changed.connect(_refresh_gold)
	_refresh_gold(GameState.run_gold)
	_refresh_fullscreen_checkbox()
	_update_volume_knob()


func _exit_tree() -> void:
	if get_tree() != null and overlay.visible:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if overlay.visible and event.is_action_pressed(&"ui_cancel"):
		_close_options()
		get_viewport().set_input_as_handled()


func _toggle_options() -> void:
	if overlay.visible:
		_close_options()
		return
	overlay.visible = true
	_refresh_fullscreen_checkbox()
	_update_volume_knob()
	get_tree().paused = true


func _close_options() -> void:
	overlay.visible = false
	slider_dragging = false
	get_tree().paused = false


func _toggle_fullscreen() -> void:
	var is_fullscreen := (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED
		if is_fullscreen
		else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	await get_tree().process_frame
	_refresh_fullscreen_checkbox()


func _refresh_fullscreen_checkbox() -> void:
	var is_fullscreen := (
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	fullscreen_checkbox.texture_normal = (
		CHECKBOX_CHECKED if is_fullscreen else CHECKBOX_EMPTY
	)
	fullscreen_checkbox.tooltip_text = (
		"DESACTIVAR PANTALLA COMPLETA"
		if is_fullscreen
		else "ACTIVAR PANTALLA COMPLETA"
	)


func _on_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		slider_dragging = event.pressed
		if event.pressed:
			_set_volume_from_x(event.position.x)
		slider_area.accept_event()
	elif event is InputEventMouseMotion and slider_dragging:
		_set_volume_from_x(event.position.x)
		slider_area.accept_event()
	elif event is InputEventScreenTouch:
		slider_dragging = event.pressed
		_set_volume_from_x(event.position.x)
		slider_area.accept_event()
	elif event is InputEventScreenDrag and slider_dragging:
		_set_volume_from_x(event.position.x)
		slider_area.accept_event()


func _set_volume_from_x(pointer_x: float) -> void:
	var travel := slider_area.size.x - volume_knob.size.x
	var knob_x := clampf(pointer_x - volume_knob.size.x * 0.5, 0.0, travel)
	var value := knob_x / travel if travel > 0.0 else 0.0
	GameState.set_music_volume(value)
	_update_volume_knob()


func _update_volume_knob() -> void:
	var travel := slider_area.size.x - volume_knob.size.x
	volume_knob.position.x = roundf(GameState.music_volume * travel)


func _refresh_gold(value: int) -> void:
	gold_value.text = str(value)
