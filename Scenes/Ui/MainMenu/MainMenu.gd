extends Control
# Nodo principale della scena MainMenu.
# Gestisce la UI per impostazioni di gara:
# nome del giocatore, numero di giri, difficoltà e frenata assistita.

# Riferimenti ai controlli principali (creati dinamicamente)
var difficulty_option: OptionButton
var braking_check: CheckButton
var laps_option: OptionButton
var start_button: Button

# Palette colori
const BG_COLOR = Color("#0d0d0d")
const ACCENT = Color("#f5a623")
const TEXT_COLOR = Color("#ffffff")
const PANEL_COLOR = Color("#1a1a2e")

func _ready() -> void:
	# Costruisce tutta la UI quando la scena è pronta
	_build_ui()

func _build_ui() -> void:
	# Sfondo principale
	var bg = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Linee laterali decorative
	var line_left = ColorRect.new()
	line_left.color = ACCENT
	line_left.size = Vector2(4, 400)
	line_left.position = Vector2(80, 100)
	add_child(line_left)

	var line_right = ColorRect.new()
	line_right.color = ACCENT
	line_right.size = Vector2(4, 400)
	line_right.position = Vector2(916, 100)
	add_child(line_right)

	# Pannello principale centrale
	var panel = PanelContainer.new()
	panel.size = Vector2(700, 520)
	panel.position = Vector2(160, 60)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = PANEL_COLOR
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.border_color = ACCENT
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# Margini interni e VBox per disposizione verticale dei controlli
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_child(vbox)
	panel.add_child(margin)

	# Titolo principale
	var title = Label.new()
	title.text = "RACE SETTINGS"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separatore grafico
	var sep = ColorRect.new()
	sep.color = ACCENT
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)

	# Input per il nome del giocatore
	vbox.add_child(_make_label("IL TUO NOME"))
	var name_input = LineEdit.new()
	name_input.placeholder_text = "Inserisci il tuo nome..."
	name_input.custom_minimum_size = Vector2(0, 42)
	name_input.add_theme_color_override("font_color", TEXT_COLOR)
	name_input.text = GameManager.player_name
	name_input.text_changed.connect(func(new_text):
		# Aggiorna il nome del giocatore in GameManager
		GameManager.player_name = new_text if new_text.length() > 0 else "Player"
	)
	vbox.add_child(name_input)

	# Opzione numero di giri
	vbox.add_child(_make_label("NUMERO DI GIRI"))
	laps_option = _make_option()
	for i in range(1, 11):
		laps_option.add_item("%d" % i)
	laps_option.select(GameManager.data.preferred_laps - 1)
	vbox.add_child(laps_option)

	# Opzione difficoltà
	vbox.add_child(_make_label("DIFFICOLTÀ"))
	difficulty_option = _make_option()
	difficulty_option.add_item("🟢  Facile")
	difficulty_option.add_item("🟡  Normale")
	difficulty_option.add_item("🔴  Difficile")
	difficulty_option.select(GameManager.data.preferred_difficulty)
	vbox.add_child(difficulty_option)

	# Check per frenata assistita
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	var brake_label = _make_label("FRENATA ASSISTITA")
	brake_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(brake_label)
	braking_check = CheckButton.new()
	braking_check.button_pressed = GameManager.data.preferred_braking
	braking_check.add_theme_color_override("font_color", TEXT_COLOR)
	hbox.add_child(braking_check)
	vbox.add_child(hbox)

	# Bottone per iniziare la gara
	start_button = Button.new()
	start_button.text = "INIZIA GARA  ▶"
	start_button.custom_minimum_size = Vector2(0, 55)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = ACCENT
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	start_button.add_theme_stylebox_override("normal", btn_style)
	start_button.add_theme_color_override("font_color", Color("#0d0d0d"))
	start_button.add_theme_font_size_override("font_size", 20)
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

# Funzione helper per creare label stilizzate
func _make_label(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", ACCENT)
	l.add_theme_font_size_override("font_size", 13)
	return l

# Funzione helper per creare OptionButton stilizzati
func _make_option() -> OptionButton:
	var o = OptionButton.new()
	o.custom_minimum_size = Vector2(0, 42)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#0d0d0d")
	style.border_color = ACCENT
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	o.add_theme_stylebox_override("normal", style)
	o.add_theme_color_override("font_color", TEXT_COLOR)
	return o

# Gestione dell’avvio della gara
func _on_start_pressed() -> void:
	GameManager.difficulty = difficulty_option.selected
	GameManager.assisted_braking = braking_check.button_pressed
	GameManager.total_laps = laps_option.selected + 1
	GameManager.save_preferences()     # Salva le preferenze dell’utente
	GameManager.change_to_main()       # Passa alla scena principale della gara
