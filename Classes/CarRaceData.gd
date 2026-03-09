extends Object
# Classe dati pura: non è un nodo e non vive nella scena.
# Serve solo a contenere e gestire informazioni sulla gara di una macchina.

class_name CarRaceData
# Permette di usare CarRaceData come tipo globale.


const DEFAULT_LAPTIME: float = 999.99
# Valore sentinella usato per indicare che non esiste ancora un giro valido.


var _car_number: int
var _car_name: String
# Identificativi della macchina associata a questi dati.


var _total_time: float = 0.0
# Tempo totale accumulato nella gara.


var _completed_laps: int
# Numero di giri completati.


var _partial_progress: float
# Avanzamento parziale dell’ultimo giro (usato quando la gara non è completata).


var _best_lap: float = DEFAULT_LAPTIME
# Miglior tempo sul giro registrato.


var _target_laps: int = 0
# Numero totale di giri richiesti per completare la gara.


var car_name: String:
	get: return _car_name
# Proprietà in sola lettura per il nome della macchina.


var car_number: int:
	get: return _car_number
# Proprietà in sola lettura per il numero della macchina.


var total_time: float:
	get: return _total_time
# Tempo totale leggibile dall’esterno.


var completed_laps: int:
	get: return _completed_laps
# Numero di giri completati leggibile dall’esterno.


var race_completed: bool:
	get: return _completed_laps == _target_laps
# Indica se la macchina ha terminato la gara.


var total_progress: float:
	get: return _completed_laps + _partial_progress
# Valore numerico che rappresenta l’avanzamento totale nella gara.
# Usato per confrontare macchine che non hanno finito.


func _init(car_name:String, car_number: int, target_laps: int ) -> void:
	# Costruttore della classe: inizializza i dati base della gara.
	_target_laps = target_laps
	_car_name = car_name
	_car_number = car_number
	
	
func add_lap_time(lap_time: float) -> void:
	# Registra un giro completato.
	_completed_laps += 1
	
	# Aggiorna il miglior tempo sul giro, se necessario.
	_best_lap = min(_best_lap, lap_time)
	
	
func set_total_time(p_total_time: float) -> void:
	# Imposta il tempo totale della gara.
	_total_time = p_total_time
	
	
func force_finish(p_total_time: float, progress: float) -> void:
	# Forza la fine gara anche se non è stata completata.
	# Usato probabilmente per DNF o fine anticipata.
	_partial_progress = progress
	_total_time = p_total_time	
	
	
func _to_string() -> String:
	# Rappresentazione testuale dei dati (debug / classifica).
	
	var total_str = "DNF"
	# Se la gara è completata, mostra il tempo totale in secondi.
	if race_completed: total_str = "%0.fs" % (_total_time / 1000)
		
	var best_lap_str: String = ""
	# Mostra il miglior giro solo se esiste.
	if _best_lap != DEFAULT_LAPTIME: best_lap_str = "%.1fs" % _best_lap
		
	# Formattazione finale della riga di classifica.
	return "%10s %6s %6s %5d" % [
	_car_name, total_str, best_lap_str, _completed_laps
	]
	

static func compare (a: CarRaceData, b: CarRaceData) -> bool:
	# Funzione di confronto usata per ordinare le macchine in classifica.
	
	# Prima priorità: numero di giri completati.
	if a.completed_laps == b.completed_laps:
		
		# Se entrambe hanno finito, vince chi ha il tempo minore.
		if a.race_completed:
			return a.total_time < b.total_time
		
		# Altrimenti vince chi è più avanti nel giro.
		return a.total_progress > b.total_progress
	
	# In caso di giri diversi, vince chi ne ha completati di più.
	return a.completed_laps > b.completed_laps
	
