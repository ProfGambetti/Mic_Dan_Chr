extends Resource
class_name SaveData

# --- PERCORSO FILE SALVATAGGIO ---
const SAVE_PATH: String = "user://best_laps.res"

# --- DATI SALVATI --- 
@export var best_laps: Dictionary[String, float]         # Migliori tempi per ogni pista
@export var preferred_difficulty: int = 1               # Difficoltà preferita dall'utente
@export var preferred_laps: int = 5                     # Numero di giri preferito
@export var preferred_braking: bool = false            # Frenata assistita preferita
@export var preferred_name: String = "Player"          # Nome giocatore salvato

# --- RECUPERA MIGLIOR GIRO ---
func get_best_lap(track_name: String) -> float:
	# Ritorna il miglior tempo registrato, o un valore di default se assente
	return best_laps.get(track_name, CarRaceData.DEFAULT_LAPTIME)

# --- SALVA NUOVO MIGLIOR GIRO ---
func save_best_lap(track_name: String, lap_time: float) -> void:
	var prev: float = get_best_lap(track_name)
	# Aggiorna solo se il nuovo tempo è migliore
	if lap_time < prev:
		best_laps[track_name] = lap_time
		ResourceSaver.save(self, SAVE_PATH)  # Salva su disco

# --- SALVA PREFERENZE GIOCATORE ---
func save_preferences(difficulty: int, laps: int, braking: bool, name: String) -> void:
	preferred_difficulty = difficulty
	preferred_laps = laps
	preferred_braking = braking
	preferred_name = name
	ResourceSaver.save(self, SAVE_PATH)  # Salva su disco

# --- CARICA DATI O CREA NUOVO FILE ---
static func load_or_create() -> SaveData:
	if ResourceLoader.exists(SAVE_PATH):
		return ResourceLoader.load(SAVE_PATH)
	# Se non esiste file, crea un nuovo SaveData e lo salva
	var data: SaveData = SaveData.new()
	ResourceSaver.save(data, SAVE_PATH)
	return data
