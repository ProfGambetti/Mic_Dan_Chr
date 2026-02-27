extends PathFollow2D


class_name TrackProcessor


signal build_completed


const WAYPOINT = preload("res://Scenes/Waypoint/Waypoint.tscn")


@export var interval: float = 50.0
@export var grid_space: float = 75.0
@export var max_path_deviation: float = 75.0
@export var radius_curve: Curve


var _waypoints: Array[Waypoint]


var first_waypoint: Waypoint:
	get:
		if _waypoints.size() == 0:
			printerr("TrackProcessor first_waypoint no there")
			return null
		return _waypoints[0]


func calculate_radius( ) -> void:
	var min_radius: float = Waypoint.MAX_RADIUS
	for wp in _waypoints:
		wp.calc_turn_radius()
		min_radius = min(min_radius, wp.radius)
	for wp in _waypoints:
		wp.set_radius_factor(min_radius, radius_curve)


func connect_waypoints() -> void:
	var total_wp: int = _waypoints.size()
	for i in range(total_wp): 
		var prev_ix: int = (i - 1 + total_wp) % total_wp
		var next_ix: int = (i + 1) % total_wp
		_waypoints[i].setup(_waypoints[next_ix], _waypoints[prev_ix], i)


func create_waypoint() -> Waypoint: 
	var wp: Waypoint = WAYPOINT.instantiate()
	wp.global_position = global_position
	wp.rotation_degrees = global_rotation_degrees + 90.0
	return wp


func generate_waypoints(holder: Node) -> void:
	var path2d: Path2D = get_parent()
	progress = interval
	while progress < path2d.curve.get_baked_length() - grid_space:
		var wp: Waypoint = create_waypoint()
		holder.add_child(wp)
		_waypoints.append(wp)
		progress += interval
		
	await  get_tree().physics_frame

func setup_wp_collisions() -> void:
	for wp in _waypoints:
		wp.set_collider_data(max_path_deviation)

func build_waypoint_data(holder: Node) -> void:
	_waypoints.clear()
	await generate_waypoints(holder)
	connect_waypoints()
	calculate_radius()
	await get_tree().physics_frame
	setup_wp_collisions()
	
	for wp in _waypoints: print(wp)
	
	build_completed.emit()
