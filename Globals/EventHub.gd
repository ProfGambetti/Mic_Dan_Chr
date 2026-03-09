extends Node
# Nodo globale che funge da "hub" per gli eventi della gara.
# Tutti gli script possono connettersi ai segnali qui definiti.

signal on_lap_completed(info: LapCompleteData)
# Segnale emesso quando una macchina completa un giro.
# 'info' contiene dati della macchina e tempo del giro.

signal on_race_start
# Segnale emesso all'inizio della gara.

signal on_lap_update(car: Car, lap_count: int, lap_time: float)
# Segnale emesso quando una macchina aggiorna il giro.
# Utile per aggiornare UI o logica della gara.

signal on_race_over(data: Array[CarRaceData])
# Segnale emesso a fine gara.
# 'data' contiene l'elenco dei dati di gara per tutte le macchine.

func emit_on_race_over(data:Array[CarRaceData]) -> void:
	# Funzione comoda per emettere il segnale di fine gara
	on_race_over.emit(data)


func emit_on_lap_completed(info: LapCompleteData) -> void:
	# Funzione comoda per emettere il segnale di giro completato
	on_lap_completed.emit(info)


func emit_on_race_start() -> void:
	# Funzione comoda per emettere l’inizio della gara
	on_race_start.emit()
	
	
func emit_on_lap_update(car: Car, lap_count: int, lap_time: float) -> void:
	# Funzione comoda per aggiornare UI/logica sul giro
	on_lap_update.emit(car, lap_count, lap_time)
	
