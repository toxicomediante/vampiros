extends Control

@onready var status: Label = $Margin/Panel/Content/Status
@onready var start_button: Button = $Margin/Panel/Content/StartButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	status.text = "El prototipo está vivo."
	start_button.text = "CONTINUAR"
