extends Node
# Nodo globale che gestisce lo stato della gara, preferenze del giocatore e cambio scene.

const MAIN = preload("res://Scenes/Ui/Main/Main.tscn")
# Scena principale del menu principale.

var data: SaveData
# Contiene dati salvati del giocatore (nome preferito, migliori tempi, preferenze).

var current_track_name: String = ""
# Nome della traccia attuale.

var assisted_braking: bool = false
# Indica se il freno assistito è attivo per il giocatore.

var difficulty: int = 1
# Difficoltà della CPU: 0 = facile, 1 = normale, 2 = difficile

var total_laps: int = 5
# Numero totale di giri per la gara

var last_track: TrackInfo = null
# Ultima traccia caricata

var player_name: String = "Player"
# Nome del giocatore

func _enter_tree() -> void:
	# Carica i dati salvati all’entrata dello scene tree
	data = SaveData.load_or_create()
	player_name = data.preferred_name

func save_best_lap(new_time: float):
	# Salva il miglior giro del giocatore per la traccia corrente
	data.save_best_lap(current_track_name, new_time)

func get_best_lap(track_name: String) -> float:
	# Ritorna il miglior giro salvato per una traccia specifica
	return data.get_best_lap(track_name)

func change_to_main() -> void:
	# Passa alla scena principale del menu
	get_tree().change_scene_to_packed(MAIN)

func change_to_track(info: TrackInfo) -> void:
	# Passa alla scena di una traccia specifica
	current_track_name = info.track_name
	last_track = info
	get_tree().change_scene_to_packed(info.track_scene)

func restart_track() -> void:
	# Ricarica l’ultima traccia giocata
	if last_track:
		change_to_track(last_track)

func save_preferences() -> void:
	# Salva le preferenze del giocatore (difficoltà, giri, freno assistito, nome)
	data.save_preferences(difficulty, total_laps, assisted_braking, player_name)
	
