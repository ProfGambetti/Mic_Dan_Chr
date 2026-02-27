extends Node2D


class_name Waypoint

const MAX_RADIUS: float = 300.0
const COLLISION_MARGIN: float = 10.0

@onready var right_collision: RayCast2D = $RightCollision
@onready var left_collision: RayCast2D = $LeftCollision
@onready var label: Label = $Label



var _left_collision_distance: float = 0.0
var _right_collision_distance: float = 0.0
var _left_collision_dir: Vector2 = Vector2.ZERO
var _right_collision_dir: Vector2 = Vector2.ZERO
var _max_path_devation: float = 75.0


var radius: float = MAX_RADIUS:
	get: return radius

var radius_factor: float = 0.0:
	get: return radius_factor


var number: int = 0:
	get: return number


var next_waypoint: Waypoint: 
	get:
		if !next_waypoint: printerr("WP %d no next_waypoint!!" % number)
		return next_waypoint


var prev_waypoint: Waypoint: 
	get:
		if !prev_waypoint: printerr("WP %d no prev_waypoint!!" % number)
		return prev_waypoint


func setup(next_wp: Waypoint, prev_wp: Waypoint, num: int) -> void:
	next_waypoint = next_wp
	prev_waypoint = prev_wp
	number = num
	label.text = "%d" % num
	

func calc_turn_radius() -> void:
	var a: float = prev_waypoint.global_position.distance_to(global_position)
	var b: float = global_position.distance_to(next_waypoint.global_position)
	var c: float = next_waypoint.global_position.distance_to(prev_waypoint.global_position)
	var s: float = (a + b + c) / 2.0
	
	var area: float = sqrt(max(s * (s - a) * (s - b) * (s - c), 0.0))

	if !is_zero_approx(area):
		radius = (a * b * c) / (4.0 * area)



func set_radius_factor(min_radius: float, radius_curve: Curve) -> void:
	var adj: float = clampf(radius, min_radius, MAX_RADIUS)
	var t: float = (adj - min_radius) / (MAX_RADIUS - min_radius)
	radius_factor = radius_curve.sample(t)


func set_collider_data(max_path_deviation: float) -> void:
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
	if is_zero_approx(weight): return  global_position
	
	if weight > 0.0:
		var deviation: float  = weight *  _right_collision_distance
		deviation = clampf(deviation, -_max_path_devation, _max_path_devation)
		return _right_collision_dir *  deviation + global_position
	else:
		var deviation: float  = weight *  _left_collision_distance
		deviation = clampf(deviation, -_max_path_devation, _max_path_devation)
		return global_position - _left_collision_dir *  deviation


#MESSAGGI DI CONSOLE CHE NON SERVONO AL PROGRAMMA

#func _to_string() -> String:
	##return "%d next:%d prev:%d rad:%.2f fac:%.2f lcd:%.2f" % [
	#	number, next_waypoint.number, prev_waypoint.number,
		#radius, radius_factor, _left_collision_distance, _right_collision_distance
	#]
	
#func _to_string() -> String:
	#var next_num = next_waypoint.number if next_waypoint else -1
	#var prev_num = prev_waypoint.number if prev_waypoint else -1
	#return "%d next:%d prev:%d" % [number, next_num, prev_num]
	
	
