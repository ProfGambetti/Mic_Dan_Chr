extends Control
class_name GameUi
# Nodo principale della UI di gara.
# Mostra informazioni sul giocatore, lap, boost, posizione e risultati finali.

# Colori principali della UI
const BG_COLOR = Color("#0d0d0d")
const ACCENT = Color("#f5a623")
const TEXT_COLOR = Color("#ffffff")
const PANEL_COLOR = Color("#1a1a2e")

# Riferimenti ai nodi della UI preesistenti nella scena
@onready var margin_container: MarginContainer = $MarginContainer
@onready var panel_container: PanelContainer = $PanelContainer
@onready var race_over_label: Label = $PanelContainer/RaceOverLabel

# Dizionario per collegare ogni Car alla sua CarUi
var _car_ui_dict: Dictionary[Car, CarUi] = {}
var _position_label: Label
var _player_car: Car
var _pause_panel: Control
var _boost_bar: ColorRect
var _boost_bar_bg: ColorRect
var _boost_label: Label

# Gestione input per pausa
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

# Collegamento ai segnali globali tramite EventHub
func _enter_tree() -> void:
	EventHub.on_lap_update.connect(on_lap_update)
	EventHub.on_race_over.connect(on_race_over)

# Setup iniziale della UI per tutte le macchine
func setup(cars: Array[Car]) -> void:
	var ui_nodes: Array[Node] = margin_container.get_children()
	for i in range(ui_nodes.size()):
		if i >= cars.size(): break
		var ui: CarUi = ui_nodes[i]
		var car: Car = cars[i]
		ui.update_values(car, 0, 0.0)
		ui.show()
		_car_ui_dict[car] = ui
		if car is PlayerCar:
			_player_car = car
	
	_setup_position_label()  # Mostra posizione del giocatore
	_setup_pause_panel()     # Setup menu pausa
	_setup_boost_bar()       # Setup barra boost
	
	# Collegamento al controller di gara per aggiornamenti classifica
	var rc = get_tree().get_first_node_in_group("race_controller")
	if rc:
		rc.on_standings_update.connect(_on_standings_update)

# Setup della label della posizione del giocatore
func _setup_position_label() -> void:
	_position_label = Label.new()
	var font = load("res://Assets/Fonts/PressStart2P-Regular.ttf")
	_position_label.add_theme_font_override("font", font)
	_position_label.add_theme_font_size_override("font_size", 25)
	_position_label.add_theme_color_override("font_color", Color.WHITE)
	_position_label.add_theme_constant_override("outline_size", 4)
	_position_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_position_label.position = Vector2(20, 120)
	_position_label.text = "POS: --"
	add_child(_position_label)

# Aggiornamento della posizione del giocatore in classifica
func _on_standings_update(standings: Array[Car]) -> void:
	if not _player_car or not _position_label: return
	var pos = standings.find(_player_car) + 1
	_position_label.text = "POS: %d/%d" % [pos, standings.size()]

# Setup barra boost e label relativa
func _setup_boost_bar() -> void:
	var screen_size = get_viewport_rect().size
	var bar_width = 200
	var container = VBoxContainer.new()
	container.position = Vector2(screen_size.x / 2 - bar_width / 2, screen_size.y - 60)
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(container)
	
	# Label sopra barra boost
	_boost_label = Label.new()
	_boost_label.text = "BOOST ✓"
	_boost_label.add_theme_font_size_override("font_size", 14)
	_boost_label.add_theme_color_override("font_color", ACCENT)
	_boost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boost_label.custom_minimum_size = Vector2(bar_width, 0)
	container.add_child(_boost_label)
	
	# Sfondo barra boost
	_boost_bar_bg = ColorRect.new()
	_boost_bar_bg.color = Color("#333333")
	_boost_bar_bg.custom_minimum_size = Vector2(bar_width, 14)
	container.add_child(_boost_bar_bg)
	
	# Barra boost reale
	_boost_bar = ColorRect.new()
	_boost_bar.color = ACCENT
	_boost_bar.size = Vector2(bar_width, 14)
	_boost_bar_bg.add_child(_boost_bar)

# Aggiornamento continuo della barra boost del giocatore
func _process(_delta: float) -> void:
	if not _player_car or not _boost_bar: return
	var pc: PlayerCar = _player_car as PlayerCar
	if not pc: return
	
	var factor = pc.get_boost_factor()
	_boost_bar.size.x = 200 * clampf(factor, 0.0, 1.0)
	
	# Aggiornamento colore e testo a seconda dello stato del boost
	if pc.boost_ready():
		_boost_bar.color = ACCENT
		_boost_label.text = "BOOST ✓"
		_boost_label.add_theme_color_override("font_color", ACCENT)
	elif pc.is_boosting():
		_boost_bar.color = Color("#00ff88")
		_boost_label.text = "BOOST!"
		_boost_label.add_theme_color_override("font_color", Color("#00ff88"))
	else:
		_boost_bar.color = Color("#666666")
		_boost_label.text = "BOOST..."
		_boost_label.add_theme_color_override("font_color", Color("#666666"))

# Setup del pannello pausa
func _setup_pause_panel() -> void:
	_pause_panel = Control.new()
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.hide()
	add_child(_pause_panel)
	
	# Overlay scuro semi-trasparente
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(overlay)
	
	# Pannello centrale
	var panel = PanelContainer.new()
	panel.size = Vector2(400, 300)
	panel.position = Vector2(
		get_viewport_rect().size.x / 2 - 200,
		get_viewport_rect().size.y / 2 - 150
	)
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
	_pause_panel.add_child(panel)
	
	# Contenitore margin per padding
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	panel.add_child(margin)
	
	# VBox con pulsanti
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)
	
	# Titolo pausa
	var title = Label.new()
	title.text = "PAUSA"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Linea separatrice
	var sep = ColorRect.new()
	sep.color = ACCENT
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)
	
	# Pulsanti pausa
	var resume_btn = _make_button("▶  RIPRENDI")
	resume_btn.pressed.connect(_toggle_pause)
	vbox.add_child(resume_btn)
	
	var menu_btn = _make_button("◀  TORNA AL MENÙ")
	menu_btn.pressed.connect(func():
		get_tree().paused = false
		GameManager.change_to_main()
	)
	vbox.add_child(menu_btn)

# Funzione di utilità per creare pulsanti standard
func _make_button(txt: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 50)
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = ACCENT
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", btn_style)
	btn.add_theme_color_override("font_color", Color("#0d0d0d"))
	btn.add_theme_font_size_override("font_size", 18)
	return btn

# Mostra/nasconde pannello pausa
func _toggle_pause() -> void:
	if get_tree().paused:
		get_tree().paused = false
		_pause_panel.hide()
	else:
		get_tree().paused = true
		_pause_panel.show()

# Mostra risultati finale gara
func on_race_over(data: Array[CarRaceData]) -> void:
	panel_container.hide()
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = PanelContainer.new()
	panel.size = Vector2(600, 80 + data.size() * 60 + 120)
	panel.position = Vector2(
		get_viewport_rect().size.x / 2 - 300,
		get_viewport_rect().size.y / 2 - panel.size.y / 2
	)
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
	
	# Margin e VBox per lista dei risultati
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "RISULTATI GARA"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var sep = ColorRect.new()
	sep.color = ACCENT
	sep.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep)
	
	# Aggiunge riga per ogni CarRaceData
	var medals = ["🥇", "🥈", "🥉"]
	for i in range(data.size()):
		var d: CarRaceData = data[i]
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 16)
		
		var medal_label = Label.new()
		medal_label.text = medals[i] if i < 3 else "%d." % (i + 1)
		medal_label.add_theme_font_size_override("font_size", 20)
		medal_label.add_theme_color_override("font_color", ACCENT)
		medal_label.custom_minimum_size = Vector2(40, 0)
		row.add_child(medal_label)
		
		var name_label = Label.new()
		name_label.text = d.car_name
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", TEXT_COLOR)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)
		
		var time_label = Label.new()
		time_label.text = "%.2fs" % (d.total_time / 1000.0)
		time_label.add_theme_font_size_override("font_size", 18)
		time_label.add_theme_color_override("font_color", TEXT_COLOR)
		time_label.custom_minimum_size = Vector2(100, 0)
		time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(time_label)
		
		vbox.add_child(row)
	
	var sep2 = ColorRect.new()
	sep2.color = ACCENT
	sep2.custom_minimum_size = Vector2(0, 2)
	vbox.add_child(sep2)
	
	# Pulsanti finale
	var restart_btn = _make_button("🔄  RIVINCITA")
	restart_btn.pressed.connect(func():
		get_tree().paused = false
		GameManager.restart_track()
	)
	vbox.add_child(restart_btn)
	
	var btn = _make_button("◀  TORNA AL MENÙ")
	btn.pressed.connect(func():
		get_tree().paused = false
		GameManager.change_to_main()
	)
	vbox.add_child(btn)
	
	get_tree().paused = true  # Pausa automatica per mostrare risultati

# Aggiorna la CarUi di una macchina specifica dopo un lap
func on_lap_update(car: Car, lap_count: int, lap_time: float) -> void:
	if car in _car_ui_dict:
		_car_ui_dict[car].update_values(car, lap_count, lap_time)
		
		
