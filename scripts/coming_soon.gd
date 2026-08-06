extends Control


func _ready() -> void:
	$ReturnButton.pressed.connect(_return_to_title)
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property($VampirosLogo, "modulate:a", 1.0, 0.9)
	reveal.tween_property($ComingSoon, "modulate:a", 1.0, 0.9).set_delay(0.35)
	reveal.tween_property($ReturnButton, "modulate:a", 1.0, 0.55).set_delay(0.85)


func _return_to_title() -> void:
	GameState.abandon_run()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
