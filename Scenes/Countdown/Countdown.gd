extends Control
# Nodo UI per il countdown di partenza della gara (visuale e interazione).

class_name Countdown
# Permette di usare Countdown come tipo globale.

@export var wait_time: float = 1.0
# Tempo tra un numero e l'altro del countdown.

@onready var label: Label = $Label
# Label principale che mostra il numero del countdown.

@onready var timer: Timer = $Timer
# Timer per gestire l’aggiornamento automatico del countdown.

@onready var beep: AudioStreamPlayer = $Beep
# Suono beep per ogni numero del countdown.

var _started: bool = false
# Indica se il countdown è già partito.

var _count: int = 3
# Numero corrente del countdown (parte da 3).

var _press_label: Label
# Label che mostra il messaggio “premi S per iniziare”.


func _ready() -> void:
	# Configura timer e label all’avvio.
	timer.wait_time = wait_time
	
	label.add_theme_font_size_override("font_size", 120)
	label.add_theme_color_override("font_color", Color("#f5a623"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.hide()  # la label principale è nascosta finché non si parte
	
	show()
	_setup_press_label()
	# crea il messaggio “premi S” e la sua animazione


func _setup_press_label() -> void:
	# Crea e configura la label con istruzioni all’avvio
	_press_label = Label.new()
	_press_label.text = "🏁  premi  [ S ]  per iniziare  🏁"
	_press_label.add_theme_font_size_override("font_size", 38)
	_press_label.add_theme_color_override("font_color", Color("#ffffff"))
	_press_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_press_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_press_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_press_label)
	
	# Animazione pulsante: lampeggia continuamente
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(_press_label, "modulate:a", 0.2, 0.8)
	tween.tween_property(_press_label, "modulate:a", 1.0, 0.8)


func _unhandled_input(event: InputEvent) -> void:
	# Gestisce input globale (tasti non catturati da altri nodi)
	if !_started and event.is_action_pressed("Start"):
		# Parte la gara quando si preme il tasto Start
		_press_label.hide()
		label.show()
		start_race()


func update_label() -> void:
	# Aggiorna il numero mostrato nel countdown
	label.text = "%d" % _count
	_animate_label()


func _animate_label() -> void:
	# Animazione della label: ingrandimento + dissolvenza
	label.scale = Vector2(2.0, 2.0)
	label.modulate.a = 1.0
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)


func start_race() -> void:
	# Fa partire il countdown
	beep.play()
	_started = true
	update_label()
	timer.start()


func _on_timer_timeout() -> void:
	# Viene chiamato ad ogni tick del timer
	_count -= 1
	
	if _count == 0:
		# Fine del countdown: mostra “VIA!” e cambia colore
		label.modulate.a = 1.0
		label.text = "VIA!"
		label.add_theme_color_override("font_color", Color("#00ff88"))
		_animate_label()
		
		# Aspetta mezzo secondo prima di emettere l’evento di partenza
		await get_tree().create_timer(0.5).timeout
		
		# Qui emette l’inizio della gara tramite EventHub
		EventHub.emit_on_race_start()
		
		queue_free()  # elimina il nodo Countdown
	else:
		# Ancora numeri del countdown
		beep.play()
		update_label()
