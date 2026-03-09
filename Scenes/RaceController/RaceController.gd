extends Node
class_name RaceController

# --- SIGNALS ---
signal on_standings_update(standings: Array[Car])  # Emesso quando cambiano le posizioni in gara

# --- PARAMETRI EDITOR ---
@export var total_laps: int = 5        # Numero di giri totali della gara
@onready var race_over_timer: Timer = $RaceOverTimer  # Timer per ritardo fine gara

# --- VARIABILI INTERNE ---
var _cars: Array[Car] = []                     # Array delle macchine partecipanti
var _track_curve: Curve2D                       # Curva della pista (usata per calcolo posizione)
var _race_data: Dictionary[Car,CarRaceData] = {} # Dati gara per ogni macchina
var _started: bool = false                      # Flag se la gara è iniziata
var _finished: bool = false                     # Flag se la gara è terminata
var _start_time: float                           # Timestamp di inizio gara (ms)

# --- INIZIALIZZAZIONE GARA ---
func setup(cars: Array[Car], track_curve: Curve2D) -> void:
	_cars = cars
	_track_curve = track_curve
	for c in cars:
		_race_data[c] = CarRaceData.new(
			c.car_name, c.car_number, total_laps
		)

# --- CONNESSIONE SIGNALS ---
func _enter_tree() -> void:
	EventHub.on_lap_completed.connect(on_lap_completed)
	EventHub.on_race_start.connect(on_race_start)
	add_to_group("race_controller")
	total_laps = GameManager.total_laps

# --- INIZIO GARA ---
func on_race_start() -> void:
	if _started: return
	_started = true
	_finished = false
	_start_time = Time.get_ticks_msec()  # Salva il timestamp di inizio gara

# --- CALCOLA TEMPO TRASCORSO ---
func get_elapsed_time() -> float:
	return Time.get_ticks_msec() - _start_time

# --- GESTIONE COMPLETAMENTO GIRO ---
func on_lap_completed(info: LapCompleteData) -> void:
	if not _started or _finished: return
	
	var car: Car = info.car
	var rd: CarRaceData = _race_data[car]
	rd.add_lap_time(info.lap_time)  # Aggiorna i tempi della macchina
	EventHub.emit_on_lap_update(
		car,
		rd.completed_laps,
		info.lap_time
	)
	
	# Salva miglior giro del giocatore
	if car is PlayerCar:
		GameManager.save_best_lap(info.lap_time)
	
	# Controlla se la macchina ha finito la gara
	if rd.race_completed:
		car.change_state(Car.CarState.RACEOVER)
		rd.set_total_time(get_elapsed_time())
		
		# Se tutte le macchine hanno finito, avvia il timer per la fine gara
		var all_finished = true
		for c in _cars:
			if not _race_data[c].race_completed:
				all_finished = false
				break
		
		if all_finished:
			if race_over_timer.is_stopped(): race_over_timer.start()
	
	# Aggiorna le posizioni in tempo reale
	emit_signal("on_standings_update", get_standings())

# --- CALCOLO POSIZIONI ---
func get_standings() -> Array[Car]:
	var cars_copy: Array[Car] = _cars.duplicate()
	cars_copy.sort_custom(func(a: Car, b: Car) -> bool:
		var ra: CarRaceData = _race_data[a]
		var rb: CarRaceData = _race_data[b]
		
		# Priorità: giri completati
		if ra.completed_laps != rb.completed_laps:
			return ra.completed_laps > rb.completed_laps
		
		# Se stessi giri, confronta posizione sulla curva della pista
		var offset_a = _track_curve.get_closest_offset(a.global_position)
		var offset_b = _track_curve.get_closest_offset(b.global_position)
		return offset_a > offset_b
	)
	return cars_copy

# --- EMISSIONE STANDINGS AD OGNI FRAME ---
func _process(delta: float) -> void:
	if not _started or _finished: return
	emit_signal("on_standings_update", get_standings())

# --- TERMINA GARA ---
func finish_race() -> void:
	if _finished: return
	_finished = true
	
	var total_len: float = _track_curve.get_baked_length()
	var elapsed: float = get_elapsed_time()
	
	# Completa i dati di tutte le macchine rimaste in pista
	for c in _cars:
		var rd: CarRaceData = _race_data[c]
		if not rd.race_completed:
			var offset: float = _track_curve.get_closest_offset(c.global_position)
			var progress: float = offset / total_len
			rd.force_finish(elapsed, progress)
			c.change_state(Car.CarState.RACEOVER)
	
	# Ordina risultati finali e li invia tramite EventHub
	var results: Array[CarRaceData] = _race_data.values()
	results.sort_custom(CarRaceData.compare)
	EventHub.emit_on_race_over(results)

# --- CALLBACK TIMER FINE GARA ---
func _on_race_over_timer_timeout() -> void:
	finish_race()
