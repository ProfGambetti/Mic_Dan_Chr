extends PathFollow2D
class_name TrackProcessor

# --- PROCESSA IL PERCORSO DELLA PISTA, CREA WAYPOINTS E CALCOLA LE CURVE ---

signal build_completed   # Segnale emesso quando tutti i waypoint sono stati creati e configurati

const WAYPOINT = preload("res://Scenes/Waypoint/Waypoint.tscn")  # Scena del waypoint da istanziare

@export var interval: float = 50.0           # Distanza tra waypoint lungo la curva
@export var grid_space: float = 75.0         # Spazio di sicurezza per evitare waypoint troppo vicini alla fine della curva
@export var max_path_deviation: float = 75.0 # Limite massimo per la deviazione laterale dei waypoint
@export var radius_curve: Curve               # Curve usata per mappare il raggio di curvatura dei waypoint

var _waypoints: Array[Waypoint]              # Array che contiene tutti i waypoint creati

var first_waypoint: Waypoint:                # Primo waypoint della pista
	get:
		if _waypoints.size() == 0:
			printerr("TrackProcessor first_waypoint no there")
			return null
		return _waypoints[0]


# --- CALCOLA IL RAGGIO DELLE CURVE E NORMALIZZA IL FATTOR DI CURVATURA ---
func calculate_radius() -> void:
	var min_radius: float = Waypoint.MAX_RADIUS
	for wp in _waypoints:
		wp.calc_turn_radius()  # Calcola il raggio della curva tra prev e next
		min_radius = min(min_radius, wp.radius)
	for wp in _waypoints:
		wp.set_radius_factor(min_radius, radius_curve)  # Normalizza in base alla curva globale


# --- COLLEGA I WAYPOINT TRA LORO (PREV E NEXT) ---
func connect_waypoints() -> void:
	var total_wp: int = _waypoints.size()
	for i in range(total_wp): 
		var prev_ix: int = (i - 1 + total_wp) % total_wp
		var next_ix: int = (i + 1) % total_wp
		_waypoints[i].setup(_waypoints[next_ix], _waypoints[prev_ix], i)


# --- CREA UN SINGOLO WAYPOINT ALLA POSIZIONE ATTUALE DEL TRACKPROCESSOR ---
func create_waypoint() -> Waypoint: 
	var wp: Waypoint = WAYPOINT.instantiate()
	wp.global_position = global_position
	wp.rotation_degrees = global_rotation_degrees + 90.0
	return wp


# --- GENERA WAYPOINT LUNGO LA CURVA DEL PATH2D ---
func generate_waypoints(holder: Node) -> void:
	var path2d: Path2D = get_parent()
	progress = interval
	while progress < path2d.curve.get_baked_length() - grid_space:
		var wp: Waypoint = create_waypoint()
		holder.add_child(wp)
		_waypoints.append(wp)
		progress += interval
		
	await get_tree().physics_frame  # Attende il frame successivo per sicurezza


# --- CONFIGURA I COLLIDER DEI WAYPOINT ---
func setup_wp_collisions() -> void:
	for wp in _waypoints:
		wp.set_collider_data(max_path_deviation)


# --- FUNZIONE COMPLETA PER COSTRUIRE TUTTI I WAYPOINT DELLA PISTA ---
func build_waypoint_data(holder: Node) -> void:
	_waypoints.clear()
	await generate_waypoints(holder)  # Crea waypoint lungo la curva
	connect_waypoints()                # Collega prev e next
	calculate_radius()                 # Calcola raggio e fattore curvatura
	await get_tree().physics_frame
	setup_wp_collisions()              # Configura collider per AI e deviazioni
	
	for wp in _waypoints: print(wp)    # Debug: stampa info waypoint
	
	build_completed.emit()             # Segnale emesso a fine setup
