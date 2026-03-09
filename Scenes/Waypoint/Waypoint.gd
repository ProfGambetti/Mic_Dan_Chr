extends Node2D

class_name Waypoint
# Nodo che rappresenta un waypoint del tracciato.
# Contiene informazioni sulla posizione, il raggio della curva e collider laterali per la deviazione.

const MAX_RADIUS: float = 300.0
# Raggio massimo della curva

const COLLISION_MARGIN: float = 10.0
# Margine sottratto alla distanza del collider per sicurezza

@onready var right_collision: RayCast2D = $RightCollision
@onready var left_collision: RayCast2D = $LeftCollision
@onready var label: Label = $Label
# Collider e label di debug

var _left_collision_distance: float = 0.0
var _right_collision_distance: float = 0.0
var _left_collision_dir: Vector2 = Vector2.ZERO
var _right_collision_dir: Vector2 = Vector2.ZERO
var _max_path_devation: float = 75.0
# Variabili interne per calcolare deviazione del target

var radius: float = MAX_RADIUS:
	get: return radius
# Raggio calcolato della curva tra questo waypoint e i vicini

var radius_factor: float = 0.0:
	get: return radius_factor
# Valore normalizzato 0-1 che indica quanto è stretta la curva
# Usato da CpuCar per regolare velocità

var number: int = 0:
	get: return number
# Numero del waypoint

var next_waypoint: Waypoint: 
	get:
		if !next_waypoint: printerr("WP %d no next_waypoint!!" % number)
		return next_waypoint

var prev_waypoint: Waypoint: 
	get:
		if !prev_waypoint: printerr("WP %d no prev_waypoint!!" % number)
		return prev_waypoint

func setup(next_wp: Waypoint, prev_wp: Waypoint, num: int) -> void:
	# Imposta i waypoint adiacenti e il numero del waypoint
	next_waypoint = next_wp
	prev_waypoint = prev_wp
	number = num
	label.text = "%d" % num
	
func calc_turn_radius() -> void:
	# Calcola raggio della curva usando formula triangolo e semiperimetro
	var a: float = prev_waypoint.global_position.distance_to(global_position)
	var b: float = global_position.distance_to(next_waypoint.global_position)
	var c: float = next_waypoint.global_position.distance_to(prev_waypoint.global_position)
	var s: float = (a + b + c) / 2.0
	var area: float = sqrt(max(s * (s - a) * (s - b) * (s - c), 0.0))
	if !is_zero_approx(area):
		radius = (a * b * c) / (4.0 * area)

func set_radius_factor(min_radius: float, radius_curve: Curve) -> void:
	# Normalizza il raggio per ottenere radius_factor (0=stretta,1=larga)
	var adj: float = clampf(radius, min_radius, MAX_RADIUS)
	var t: float = (adj - min_radius) / (MAX_RADIUS - min_radius)
	radius_factor = radius_curve.sample(t)

func set_collider_data(max_path_deviation: float) -> void:
	# Calcola distanze dai collider laterali
	_max_path_devation = max_path_deviation
	_left_collision_distance = left_collision.target_position.length()
	_right_collision_distance = right_collision.target_position.length()
	if left_collision.is_colliding():
		var colp: Vector2 = left_collision.get_collision_point()
		_left_collision_distance = global_position.distance_to(colp) - COLLISION_MARGIN
		_left_collision_distance = max(0.0, _left_collision_distance)
	if right_collision.is_colliding():
		var colp: Vector2 = right_collision.get_collision_point()
		_right_collision_distance = global_position.distance_to(colp) - COLLISION_MARGIN
		_right_collision_distance = max(0.0, _right_collision_distance)
	_left_collision_dir = Vector2.LEFT.rotated(rotation)
	_right_collision_dir = Vector2.RIGHT.rotated(rotation)

func get_target_adjusted(weight: float) -> Vector2:
	# Restituisce punto target corretto per la CpuCar considerando deviazione casuale
	if is_zero_approx(weight): return global_position
	if weight > 0.0:
		var deviation: float  = weight *  _right_collision_distance
		deviation = clampf(deviation, -_max_path_devation, _max_path_devation)
		return _right_collision_dir *  deviation + global_position
	else:
		var deviation: float  = weight *  _left_collision_distance
		deviation = clampf(deviation, -_max_path_devation, _max_path_devation)
		return global_position - _left_collision_dir *  deviation
