extends Control
# Nodo principale della scena Main, gestisce l'inizializzazione della UI.

func _ready() -> void:
	# Assicura che la scena non sia in pausa all’avvio
	get_tree().paused = false
	# Aggiunge il pulsante per tornare alle impostazioni
	_add_back_button()

func _add_back_button() -> void:
	# Crea un pulsante “◀ IMPOSTAZIONI” in alto a sinistra
	var btn = Button.new()
	btn.text = "◀  IMPOSTAZIONI"
	btn.position = Vector2(20, 20)
	btn.custom_minimum_size = Vector2(180, 45)
	
	# Stile visivo del pulsante
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#f5a623")  # colore di sfondo arancione accentuato
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", Color("#0d0d0d"))  # colore del testo
	btn.add_theme_font_size_override("font_size", 16)               # dimensione font
	
	# Collega il pulsante alla funzione che gestisce il ritorno alle impostazioni
	btn.pressed.connect(_on_back_pressed)
	
	# Aggiunge il pulsante alla scena
	add_child(btn)

func _on_back_pressed() -> void:
	# Cambia scena tornando al menu principale
	get_tree().change_scene_to_file("res://Scenes/Ui/MainMenu/MainMenu.tscn")
