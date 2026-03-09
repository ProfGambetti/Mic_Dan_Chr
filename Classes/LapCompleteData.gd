extends Object

class_name LapCompleteData
# Classe dati che rappresenta il completamento di un giro per una macchina.
# Contiene riferimenti alla macchina e al tempo del giro.

# Tempo impiegato per completare il giro, in secondi
var lap_time: float

# Riferimento alla macchina che ha completato il giro
var car: Car

# Costruttore della classe
func _init(p_car: Car, lt: float) -> void:
	car = p_car      # Imposta la macchina
	lap_time = lt    # Imposta il tempo del giro

# Ritorna una stringa utile per debug o log
func _to_string() -> String:
	return "LapCompleteData %s (%d) lap: %.2f" % [
		car.car_name, car.car_number, lap_time
	]
