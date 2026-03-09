extends Car
class_name PlayerCar

# --- PARAMETRI CONFIGURABILI DAL PLAYER ---
@export var max_speed: float = 380.0      # Velocità massima normale
@export var friction: float = 300.0       # Attrito che rallenta la macchina
@export var acceleration: float = 150.0   # Accelerazione normale
@export var steer_strength: float = 6.0   # Forza di sterzata base
@export var min_steer_factor: float = 0.5 # Minimo fattore di sterzata a velocità massima

# --- PARAMETRI BOOST ---
@export var boost_speed: float = 480.0       # Velocità durante il boost
@export var boost_duration: float = 2.0      # Durata del boost in secondi
@export var boost_cooldown: float = 6.0      # Tempo di recupero tra un boost e l'altro

# --- VARIABILI INTERNE ---
var _throttle: float = 0.0            # Intensità acceleratore (0..1)
var _steer: float = 0.0               # Valore di sterzata (-1 a 1)
var _is_boosting: bool = false        # Stato boost attivo
var _boost_timer: float = 0.0         # Timer countdown boost
var _boost_cooldown_timer: float = 0.0 # Timer countdown cooldown

# --- INIZIALIZZAZIONE ---
func _ready() -> void:
	super()
	car_name = GameManager.player_name # Imposta il nome della macchina dal giocatore

# --- LOGICA DI INPUT E BOOST ---
func _process(delta: float) -> void:
	# Lettura input del giocatore
	_throttle = Input.get_action_strength("ui_up")
	_steer = Input.get_axis("ui_left", "ui_right")
	
	# Aggiornamento timer boost e cooldown
	if _is_boosting:
		_boost_timer -= delta
		if _boost_timer <= 0:
			_is_boosting = false
			_boost_cooldown_timer = boost_cooldown
	elif _boost_cooldown_timer > 0:
		_boost_cooldown_timer -= delta
	
	# Attivazione boost se possibile
	if Input.is_action_just_pressed("boost") and _boost_cooldown_timer <= 0 and not _is_boosting:
		_is_boosting = true
		_boost_timer = boost_duration
		_velocity = boost_speed * 0.4  # Partenza boost leggermente incrementata
	
	# Richiama il _process di Car per aggiornare fisica e animazioni
	super(delta)

# --- LOGICA FISICA ---
func _physics_process(delta: float) -> void:
	if _state != CarState.DRIVING: return
	apply_throttle(delta)   # Aggiorna velocità
	apply_rotation(delta)   # Aggiorna rotazione
	position += transform.x * _velocity * delta # Applica spostamento

# --- APPLICA ACCELERAZIONE E FRENATA ---
func apply_throttle(delta: float) -> void:
	# Determina velocità massima corrente (boost o normale)
	var current_max_speed = boost_speed if _is_boosting else max_speed
	
	# Accelerazione
	if _throttle > 0.0 or _is_boosting:
		_velocity += acceleration * 1.5 * delta if _is_boosting else acceleration * delta
	else:
		_velocity -= friction * delta
	
	# Frenata assistita in curva se abilitata
	if GameManager.assisted_braking and not _is_boosting:
		var steer_abs = abs(_steer)
		if steer_abs > 0.65:
			_velocity -= friction * steer_abs * 0.6 * delta
	
	_velocity = clampf(_velocity, 0.0, current_max_speed) # Limita la velocità

# --- CALCOLA FATTOR DI STERZATA IN BASE ALLA VELOCITÀ ---
func get_steer_factor() -> float:
	return clampf(
		1.0 - pow(_velocity / max_speed, 2.0), # Più veloce = meno sterzata
		min_steer_factor,
		1.0
	) * steer_strength

# --- APPLICA ROTAZIONE DELLA MACCHINA ---
func apply_rotation(delta: float) -> void:
	rotate(get_steer_factor() * delta * _steer)

# --- BOOST: restituisce percentuale disponibile o in uso ---
func get_boost_factor() -> float:
	if _is_boosting:
		return _boost_timer / boost_duration
	return 1.0 - (_boost_cooldown_timer / boost_cooldown)

# --- CONTROLLI BOOST ---
func is_boosting() -> bool:
	return _is_boosting

func boost_ready() -> bool:
	return _boost_cooldown_timer <= 0 and not _is_boosting
