extends Car
# CpuCar eredita da Car, quindi ha tutta la logica base della macchina, urti, lap, ecc.

class_name CpuCar


# Range di reazione dello sterzo (più alto = risposta più lenta)
const STEER_REACTION_MAX: float = 12.0
const STEER_REACTION_MIN: float = 10.0

# Passo minimo e massimo per la deviazione casuale della traiettoria
const DEVIATION_STEP_MIN: float = 0.02
const DEVIATION_STEP_MAX: float = 0.25

# Limiti minimi e massimi della deviazione totale
const DEVIATION_LIMIT_MIN: float = 0.1
const DEVIATION_LIMIT_MAX: float = 1.0


@export var debug: bool = true
# Attiva i print di debug

@export_range(0,1) var skill: float = 1
# Livello di abilità della Cpu (0 basso, 1 alto)

@export var waypoint_distance: float = 20.0
# Distanza minima per considerare raggiunto un waypoint

@export var max_top_speed_limit: float = 350.0
@export var min_top_speed_limit: float = 300.0
@export var max_bottom_speed_limit: float = 120.0
@export var min_bottom_speed_limit: float = 80.0
# Range di velocità massima/minima della CPU

@export var speed_reaction: float = 2.0
# Quanto velocemente la CpuCar aggiusta la velocità verso la target


@onready var target_sprite: Sprite2D = $TargetSprite
# Sprite visivo per debug della posizione target del waypoint


# Variabili interne
var _adjusted_waypoint_target: Vector2 = Vector2.ZERO
var _steer_reaction: float = STEER_REACTION_MAX
var _target_speed: float = 250.0
var _next_waypoint: Waypoint
var _deviation_step: float = 0.0
var _deviation_limit: float = 0.0
var _deviation_weight: float = 0.0
var _inverted_skill: float = 1.0
var _allowed_max_speed: float = 0.0
var _allowed_min_speed: float = 0.0


func _ready() -> void:
	super()  # chiama _ready() di Car

	_inverted_skill = 1.0 - skill
	target_sprite.visible = false
	
	# Velocità target iniziale casuale
	_target_speed = randf_range(min_top_speed_limit, max_top_speed_limit)
	
	# Deviazione casuale iniziale basata sulla skill
	_deviation_step = lerp(DEVIATION_STEP_MIN, DEVIATION_STEP_MAX, _inverted_skill)
	_deviation_limit = lerp(DEVIATION_LIMIT_MIN, DEVIATION_LIMIT_MAX, _inverted_skill)
	_deviation_weight = randf_range(-_deviation_limit, _deviation_limit)
	
	# Reazione sterzo basata sulla skill
	_steer_reaction = lerp(STEER_REACTION_MIN, STEER_REACTION_MAX, skill)
	
	update_speed()
	_apply_difficulty()
	

func update_speed() -> void:
	# Aggiorna range consentito di velocità massima/minima per il prossimo waypoint
	_allowed_max_speed = randf_range(min_top_speed_limit, max_top_speed_limit)
	_allowed_min_speed = randf_range(min_bottom_speed_limit, max_bottom_speed_limit)


func update_waypoint() -> void:
	# Controlla se la CpuCar è vicina al waypoint
	if global_position.distance_to(_adjusted_waypoint_target) < waypoint_distance:
		set_next_waypoint(_next_waypoint.next_waypoint)
		
		# Velocità target adattata in base a radius_factor del prossimo waypoint
		# Più il radius_factor è basso (curva stretta), più si riduce la velocità
		_target_speed = lerp(
			_allowed_min_speed, 
			_allowed_max_speed,
			_next_waypoint.next_waypoint.radius_factor
		)
		
		# Frena di più nelle curve strette
		if _next_waypoint.radius_factor < 0.3:
			_target_speed *= 0.67
		elif _next_waypoint.radius_factor < 0.5:
			_target_speed *= 0.9
		# debug: stampare numero macchina e velocità target
		# print (car_number, " ", _target_speed)


func set_next_waypoint(wp: Waypoint) -> void:
	_next_waypoint = wp
	
	# Aggiorna la deviazione casuale del percorso
	_deviation_weight += randf_range(-_deviation_step, _deviation_step)
	_deviation_weight = clampf(_deviation_weight, -_deviation_limit, _deviation_limit)
	
	print("%d %.2f" % [
		car_number, _deviation_weight
	])
	
	# Target finale considerando deviazione casuale
	# Usa Waypoint.get_target_adjusted(weight) per calcolare posizione corretta usando collider laterali
	_adjusted_waypoint_target = wp.get_target_adjusted(_deviation_weight)
	target_sprite.global_position = _adjusted_waypoint_target


func _physics_process(delta: float) -> void:
	# Aggiorna waypoint anche se SLIPPING per evitare che la CPU si blocchi su olio o urti
	if not _next_waypoint: 
		return
	
	# Aggiorna waypoint anche se scivola (per evitare problemi con olio)
	if _state == CarState.SLIPPING: 
		update_waypoint()
		
	# Movimento attivo solo se DRIVING
	if _state != CarState.DRIVING: 
		return
	
	# Calcola angolo verso target e interpola rotazione
	var ta : float = (_adjusted_waypoint_target - global_position).angle()
	rotation = lerp_angle(rotation, ta, _steer_reaction * delta)
	
	# Aggiorna velocità attuale verso target
	_velocity = lerp(_velocity, _target_speed, speed_reaction * delta)
	
	# Muove la macchina nella direzione del transform.x
	position += transform.x * _velocity * delta
	
	update_waypoint()


func _on_deviation_timer_timeout() -> void:
	# Aggiorna velocità consentita (_allowed_min_speed/_allowed_max_speed)
	# Eventualmente inverte deviazione della traiettoria per simulare errori della CPU
	update_speed()
	if randf() < _inverted_skill:
		_deviation_weight = -_deviation_weight
		print("Dev. Adj. --> %d %.2f" % [
		car_number, _deviation_weight
	])


func _apply_difficulty() -> void:
	# Imposta skill e limiti di velocità in base a GameManager.difficulty (0=Facile,1=Normale,2=Difficile)
	#Influenza deviazione casuale (_deviation_step/_deviation_limit) e reazione sterzo (_steer_reaction)
	match GameManager.difficulty:
		0: # Facile
			skill = 0.3
			max_top_speed_limit = 250.0
			min_top_speed_limit = 200.0
		1: # Normale
			skill = 0.6
			max_top_speed_limit = 320.0
			min_top_speed_limit = 270.0
		2: # Difficile
			skill = 1.0
			max_top_speed_limit = 380.0
			min_top_speed_limit = 340.0
	
	_inverted_skill = 1.0 - skill
	_deviation_step = lerp(DEVIATION_STEP_MIN, DEVIATION_STEP_MAX, _inverted_skill)
	_deviation_limit = lerp(DEVIATION_LIMIT_MIN, DEVIATION_LIMIT_MAX, _inverted_skill)
	_steer_reaction = lerp(STEER_REACTION_MIN, STEER_REACTION_MAX, skill)
	update_speed()
