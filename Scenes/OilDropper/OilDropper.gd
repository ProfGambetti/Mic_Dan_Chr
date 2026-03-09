extends PathFollow2D

class_name OilDropper

# Riferimento alla scena/macro di olio da generare
const OIL = preload("uid://dh7hlequnhe22")

# Velocità con cui il droplet si muove lungo il Path
@export var speed: float = 100.0

# Flag per mostrare debug (un puntino che segue il percorso)
@export var debug: bool = true

# Nodo dove vengono aggiunte le macchie d'olio generate
@export var oil_container: Node

# Intervallo di tempo casuale per la caduta dell'olio (min, max)
@export var drop_time_var: Vector2 = Vector2(3.0, 8.0)

# Margine casuale intorno alla posizione per spawnare la macchia
@export var drop_margin: float = 25.0

# Sprite di debug visibile se 'debug' è true
@onready var debug_dot: Sprite2D = $DebugDot

# Timer che regola quando far cadere la prossima macchia
@onready var drop_timer: Timer = $DropTimer


func _enter_tree() -> void:
	# Connette l'evento di inizio gara per partire a droppare olio
	EventHub.on_race_start.connect(start_timer)


func _ready() -> void:
	# Mostra o nasconde il puntino di debug
	debug_dot.visible = debug
	
	# Randomizza la posizione iniziale lungo il Path
	progress_ratio = randf()


func _process(delta: float) -> void:
	# Avanza lungo il Path in base alla velocità e al delta time
	progress += delta * speed
	

func start_timer() -> void:
	# Imposta un intervallo casuale per il timer della caduta dell'olio
	drop_timer.wait_time = randf_range(
		drop_time_var.x, drop_time_var.y
	)
	drop_timer.start()


func drop_oil() -> void:
	if !oil_container: 
		push_error("drop_oil oil_container not assigned")
	
	# Istanzia una nuova macchia d'olio e la aggiunge al contenitore
	var oil_hazard: OilHazard = OIL.instantiate()
	oil_container.add_child(oil_hazard)
	
	# Imposta una posizione casuale vicino al droplet
	oil_hazard.global_position = Vector2(
		global_position.x + randf_range(-drop_margin, drop_margin),
		global_position.y + randf_range(-drop_margin, drop_margin)
	)
	
	# Riavvia il timer per far cadere la prossima macchia
	start_timer()
	

func _on_drop_timer_timeout() -> void:
	# Callback del Timer: genera la macchia d'olio
	drop_oil()
