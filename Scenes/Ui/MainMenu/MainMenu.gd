extends Control

var color_option: OptionButton
var difficulty_option: OptionButton
var braking_check: CheckButton
var start_button: Button

const BG_COLOR = Color("#0d0d0d")
const ACCENT = Color("#f5a623")
const TEXT_COLOR = Color("#ffffff")
const PANEL_COLOR = Color("#1a1a2e")
const BUTTON_COLOR = Color("#f5a623")
const BUTTON_TEXT = Color("#0d0d0d")

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Sfondo
	var bg = ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Linea decorativa sinistra
	var line_left = ColorRect.new()
	line_left.color = ACCENT
	line_left.size = Vector2(4, 400)
	line_left.position = Vector2(80, 100)
	add_child(line_left)

	# Linea decorativa destra
	var line_right = ColorRect.new()
	line_right.color = ACCENT
	line_right.size = Vector2(4, 400)
	line_right.position = Vector2(916, 100)
	add_child(line_right)

	# Pannello centrale
	var panel = PanelContainer.new()
	panel.size = Vector2(700, 480)
	panel.position = Vector2(160, 90)
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

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 24)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	margin.add_child(vbox)
	panel.add_child(margin)

	# Titolo
	var title = Label.new()
	title.text = "RACE SETTINGS"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Separatore
	var sep = ColorRect.new()
	sep.color = ACCENT
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)

	# Colore macchina
	vbox.add_child(_make_label("COLORE MACCHINA"))
	color_option = _make_option()
	color_option.add_item("❤️  Rosso")
	color_option.add_item("🧡  Arancione")
	color_option.add_item("💛  Giallo")
	color_option.add_item("🩷  Rosa")
	color_option.add_item("🤍  Bianco")
	color_option.add_item("🩵  Ciano")
	vbox.add_child(color_option)

	# Difficoltà
	vbox.add_child(_make_label("DIFFICOLTÀ"))
	difficulty_option = _make_option()
	difficulty_option.add_item("🟢  Facile")
	difficulty_option.add_item("🟡  Normale")
	difficulty_option.add_item("🔴  Difficile")
	difficulty_option.select(1)
	vbox.add_child(difficulty_option)

	# Frenata assistita
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	var brake_label = _make_label("FRENATA ASSISTITA")
	brake_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(brake_label)
	braking_check = CheckButton.new()
	braking_check.add_theme_color_override("font_color", TEXT_COLOR)
	hbox.add_child(braking_check)
	vbox.add_child(hbox)

	# Bottone start
	start_button = Button.new()
	start_button.text = "INIZIA GARA  ▶"
	start_button.custom_minimum_size = Vector2(0, 55)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = BUTTON_COLOR
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	start_button.add_theme_stylebox_override("normal", btn_style)
	start_button.add_theme_color_override("font_color", BUTTON_TEXT)
	start_button.add_theme_font_size_override("font_size", 20)
	start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(start_button)

func _make_label(txt: String) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_color_override("font_color", ACCENT)
	l.add_theme_font_size_override("font_size", 13)
	return l

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

func _on_start_pressed() -> void:
	match color_option.selected:
		0: GameManager.car_color = Color.RED
		1: GameManager.car_color = Color.ORANGE
		2: GameManager.car_color = Color.YELLOW
		3: GameManager.car_color = Color.PINK
		4: GameManager.car_color = Color.WHITE
		5: GameManager.car_color = Color.CYAN

	GameManager.difficulty = difficulty_option.selected
	GameManager.assisted_braking = braking_check.button_pressed

	GameManager.change_to_main()
