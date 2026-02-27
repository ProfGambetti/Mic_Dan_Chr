extends Car


class_name CpuCar


const STEER_REACTION_MAX: float = 12.0
const STEER_REACTION_MIN: float = 10.0

const DEVIATION_STEP_MIN: float = 0.02
const DEVIATION_STEP_MAX: float = 0.25

const DEVIATION_LIMIT_MIN: float = 0.1
const DEVIATION_LIMIT_MAX: float = 1.0

@export var debug: bool = true
@export_range(0,1) var skill: float = 1
@export var waypoint_distance: float = 20.0
@export var max_top_speed_limit: float = 350.0
@export var min_top_speed_limit: float = 300.0
@export var max_bottom_speed_limit: float = 120.0
@export var min_bottom_speed_limit: float = 80.0
@export var speed_reaction: float = 2.0


@onready var target_sprite: Sprite2D = $TargetSprite


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
	super()
	_inverted_skill = 1.0 - skill
	target_sprite.visible = debug
	_target_speed = randf_range(min_top_speed_limit, max_top_speed_limit)
	_deviation_step = lerp(DEVIATION_STEP_MIN, DEVIATION_STEP_MAX, _inverted_skill)
	_deviation_limit = lerp(DEVIATION_LIMIT_MIN, DEVIATION_LIMIT_MAX, _inverted_skill)
	_deviation_weight = randf_range(-_deviation_limit, _deviation_limit)
	_steer_reaction = lerp(STEER_REACTION_MIN, STEER_REACTION_MAX, skill)
	update_speed()
	_apply_difficulty()


func update_speed() -> void:
	_allowed_max_speed = randf_range(min_top_speed_limit, max_top_speed_limit)
	_allowed_min_speed = randf_range(min_bottom_speed_limit, max_bottom_speed_limit)

func update_waypoint() -> void:
	if global_position.distance_to(_adjusted_waypoint_target) < waypoint_distance:
		set_next_waypoint(_next_waypoint.next_waypoint)
		_target_speed = lerp(
			_allowed_min_speed, 
			_allowed_max_speed,
			_next_waypoint.next_waypoint.radius_factor
		)
		#print (car_number, " ", _target_speed)


func set_next_waypoint(wp: Waypoint) -> void:
	_next_waypoint = wp
	
	_deviation_weight += randf_range(-_deviation_step, _deviation_step)
	_deviation_weight = clampf(_deviation_weight, -_deviation_limit, _deviation_limit)
	
	print("%d %.2f" % [
		car_number, _deviation_weight
	])
	
	_adjusted_waypoint_target = wp.get_target_adjusted(_deviation_weight)
	target_sprite.global_position = _adjusted_waypoint_target


func _physics_process(delta: float) -> void:
	if !_next_waypoint: 
		return
	if _state == CarState.SLIPPING: 
		update_waypoint()
	if _state != CarState.DRIVING: 
		return
	
	var ta : float = (_adjusted_waypoint_target - global_position).angle()
	rotation = lerp_angle(rotation, ta, _steer_reaction * delta)
	_velocity = lerp(_velocity, _target_speed, speed_reaction * delta)
	position += transform.x * _velocity * delta
	
	update_waypoint()


func _on_deviation_timer_timeout() -> void:
	update_speed()
	if randf() < _inverted_skill:
		_deviation_weight = -_deviation_weight
		print("Dev. Adj. --> %d %.2f" % [
		car_number, _deviation_weight
	])
	
	
func _apply_difficulty() -> void:
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
