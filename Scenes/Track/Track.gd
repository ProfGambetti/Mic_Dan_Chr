extends Node
class_name Track

# --- NODI PRINCIPALI ---
@onready var track_path: Path2D = $TrackPath                  # Path2D che definisce la pista
@onready var verifications_holder: Node = $VerificationsHolder # Nodo che contiene i punti di verifica
@onready var cars_holder: Node = $CarsHolder                  # Nodo che contiene tutte le macchine
@onready var track_processor: TrackProcessor = $TrackPath/TrackProcessor
@onready var waypoint_holder: Node = $WaypointHolder          # Nodo che contiene i waypoint
@onready var race_controller: RaceController = $RaceController
@onready var game_ui: GameUi = $UiCanvas/GameUi              # UI di gioco

# --- CURVA DELLA PISTA ---
var _track_curve: Curve2D                                   # Curve2D della pista, usata per calcoli di distanza e direzione

# --- READY ---
func _ready() -> void:
	# Setup asincrono della pista
	await setup()

# --- SETUP DELLA PISTA E DELLE MACCHINE ---
func setup() -> void:
	var cars: Array[Car] = []
	
	# Salva la curva della pista
	_track_curve = track_path.curve
	
	# Costruisce i dati dei waypoint nella scena
	track_processor.build_waypoint_data(waypoint_holder)
	await track_processor.build_completed
	
	# Configura le macchine presenti nel holder
	for car in cars_holder.get_children():
		cars.append(car)
		if car is Car:
			car.setup(verifications_holder.get_children().size())  # Passa il numero dei punti di verifica
		if car is CpuCar:
			car.set_next_waypoint(track_processor.first_waypoint)  # Setta il primo waypoint per le CPU
	
	# Setup controller e UI
	race_controller.setup(cars, _track_curve)
	game_ui.setup(cars)

# --- CALCOLA DIREZIONE VERSO LA PISTA ---
func get_direction_to_path(from_pos: Vector2) -> Vector2:
	# Restituisce un vettore direzionale da from_pos verso il punto più vicino sulla curva
	var closest_offset: float = _track_curve.get_closest_offset(from_pos)
	var nearest_point: Vector2 = _track_curve.sample_baked(closest_offset)
	return from_pos.direction_to(nearest_point)

# --- GESTIONE COLLISIONI CON BORDI DELLA PISTA ---
func _on_track_collision_area_entered(area: Area2D) -> void:
	# Se l'area è una macchina, chiama hit_boundary passando la direzione correttiva
	if area is Car: area.hit_boundary(get_direction_to_path(area.position))

# --- RILEVAMENTO PASSAGGIO SULLA LINEA DI PARTENZA/ARRIVO ---
func _on_start_line_area_entered(area: Area2D) -> void:
	# Segnala completamento giro per la macchina
	if area is Car: area.lap_completed()
