extends Control

func _ready() -> void:
	get_tree().paused = false
	_add_back_button()

func _add_back_button() -> void:
	var btn = Button.new()
	btn.text = "◀  IMPOSTAZIONI"
	btn.position = Vector2(20, 20)
	btn.custom_minimum_size = Vector2(180, 45)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#f5a623")
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#0d0d0d"))
	btn.add_theme_font_size_override("font_size", 16)
	
	btn.pressed.connect(_on_back_pressed)
	add_child(btn)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Ui/MainMenu/MainMenu.tscn")
